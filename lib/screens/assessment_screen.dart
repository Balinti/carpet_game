import 'dart:async';

import 'package:flutter/material.dart';

import '../telemetry.dart';

import '../assessment/assessment.dart';
import '../game/game_state.dart';
import '../models/models.dart';
import '../widgets/visual_style.dart';
import '../game/practice_save.dart';
import 'assessment_intro.dart';
import 'assessment_progress.dart';
import 'game_screen.dart';

/// Runs the assessment: a fixed list of grids played in order (default
/// 2×2, two 3×3 side by side, then 6×6; all 36 pieces freshly shuffled), recording
/// metrics, then shows the results. No text messages during play.
class AssessmentScreen extends StatefulWidget {
  /// Grid size of each round, in order.
  final List<int> rounds;

  /// Grids shown side by side per round (same length as [rounds]; default 1).
  final List<int>? roundBoards;

  /// Where the finished result is saved (default: on-device).
  final AssessmentStore? store;

  /// Time source (tests).
  final Clock? clock;

  /// Attached to the saved result (e.g. Firebase uid), if known.
  final String? userId;

  /// Called with the finished result after it was saved.
  final void Function(AssessmentResult result)? onComplete;

  /// Called by the "done" button on the results; default pops the route.
  final VoidCallback? onDone;

  /// Pause after a solved round before the next one starts.
  final Duration solvedPause;

  const AssessmentScreen({
    super.key,
    this.rounds = const [2, 3, 6],
    this.roundBoards = const [1, 2, 1],
    this.store,
    this.clock,
    this.userId,
    this.onComplete,
    this.onDone,
    this.solvedPause = const Duration(milliseconds: 1500),
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  late final AssessmentRecorder _recorder;
  GameState? _game;
  GameState get _gameState => _game!;
  set _gameState(GameState g) {
    _game = g;
    g.addListener(_saveProgress);
  }

  /// Unfinished assessment saved earlier on this device (continue it).
  AssessmentProgress? _resume;
  int _round = 0;
  bool _transitioning = false;
  Timer? _timer;
  AssessmentResult? _result;

  @override
  void initState() {
    super.initState();
    _recorder = AssessmentRecorder(clock: widget.clock);
    AssessmentProgress.load(widget.userId).then((p) {
      if (p != null &&
          _game == null &&
          _listEq(p.rounds, widget.rounds) &&
          p.round < widget.rounds.length) {
        _resume = p;
      }
    });
  }

  static bool _listEq(List<int> a, List<int> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);

  /// Instructions are done: the first round (and its clock) starts now,
  /// or the saved assessment continues where it stopped.
  void _start() {
    final p = _resume;
    _resume = null;
    if (p == null) {
      setState(() => _gameState = _newRound(0));
      return;
    }
    _recorder.rounds.addAll(p.completed);
    _round = p.round;
    final restored = (p.partial != null && p.board != null)
        ? PracticeSave.restore(p.board!)
        : null;
    Telemetry.log(
        'assessment_resume', {'round': _round, 'withBoard': restored != null});
    if (restored == null) {
      setState(() => _gameState = _newRound(_round));
      return;
    }
    _recorder.resumeRound(p.partial!, p.elapsedMs);
    restored.recorder = _recorder;
    setState(() => _gameState = restored);
  }

  /// Keep the unfinished assessment on this device after every change.
  void _saveProgress() {
    final g = _game;
    if (g == null || _result != null) return;
    AssessmentProgress(
      rounds: widget.rounds,
      completed: List.of(_recorder.rounds),
      round: _round,
      partial: _recorder.currentRound,
      elapsedMs: _recorder.elapsedMs,
      board: PracticeSave.snapshot(g),
    ).save(widget.userId);
  }

  GameState _newRound(int index) {
    final size = widget.rounds[index];
    final boards =
        (widget.roundBoards != null && index < widget.roundBoards!.length)
            ? widget.roundBoards![index]
            : 1;
    _recorder.startRound(size, boards: boards);
    Telemetry.log('assessment_round_start', {'grid': size, 'boards': boards});
    return GameState.newPractice(size, boards: boards)..recorder = _recorder;
  }

  void _onSolved() {
    if (_transitioning) return;
    _transitioning = true;
    setState(() {});
    _timer = Timer(widget.solvedPause, _advance);
  }

  Future<void> _advance() async {
    if (!mounted) return;
    _recorder.completeRound();
    final old = _gameState;
    if (_round + 1 < widget.rounds.length) {
      setState(() {
        _round++;
        _gameState = _newRound(_round);
        _transitioning = false;
      });
      _saveProgress();
      // The old GameScreen detaches at the end of this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      return;
    }
    final result = _recorder.buildResult(userId: widget.userId);
    AssessmentProgress.clear(widget.userId);
    setState(() {
      _result = result;
      _transitioning = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    try {
      await (widget.store ?? LocalAssessmentStore()).save(result);
    } catch (_) {
      // Never interrupt the child with errors; result is still shown.
    }
    Telemetry.log('assessment_done', {
      'rounds': result.rounds.length,
      'totalMs': result.rounds.fold<int>(0, (s, m) => s + (m.durationMs ?? 0)),
    });
    widget.onComplete?.call(result);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_result == null) _game?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) {
      return AssessmentResultsView(
        result: result,
        onDone: widget.onDone ?? () => Navigator.maybePop(context),
      );
    }
    if (_game == null) return AssessmentIntro(onStart: _start);
    return AbsorbPointer(
      absorbing: _transitioning,
      child: GameScreen(
        key: ValueKey('assessment_round_$_round'),
        mode: GameMode.regularFlow,
        practiceGridSize: widget.rounds[_round],
        gameState: _gameState,
        onSolved: _onSolved,
        onGiveUp: _onSolved,
        showRestart: false,
      ),
    );
  }
}

/// Results at the end: the performance report and a "done" button.
class AssessmentResultsView extends StatelessWidget {
  final AssessmentResult result;
  final VoidCallback onDone;

  const AssessmentResultsView({
    super.key,
    required this.result,
    required this.onDone,
  });

  static String formatDuration(int? ms) => AssessmentReport.formatDuration(ms);

  @override
  Widget build(BuildContext context) {
    final st = VisualStyle.current.isClassic
        ? VisualStyle.soft3d
        : VisualStyle.current;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: st.boardBackground,
          ),
        ),
        child: SafeArea(
          child: Flex(
            direction: MediaQuery.sizeOf(context).height >
                    MediaQuery.sizeOf(context).width
                ? Axis.vertical
                : Axis.horizontal,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: AssessmentSummary(result: result),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Material(
                  key: const ValueKey('assessment_done'),
                  color: st.palette[1],
                  shape: const CircleBorder(),
                  elevation: 6,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onDone,
                    child: const SizedBox(
                      width: 72,
                      height: 72,
                      child: Icon(Icons.check, size: 44, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
