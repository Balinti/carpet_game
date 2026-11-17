import 'dart:async';

import 'package:flutter/material.dart';

import '../assessment/assessment.dart';
import '../game/game_state.dart';
import '../models/models.dart';
import '../widgets/visual_style.dart';
import 'game_screen.dart';

/// Runs the assessment: a fixed list of grids played in order (default
/// 2×2, 3×3, 3×3, each with all 36 pieces freshly shuffled), recording
/// metrics, then shows the results. No text messages during play.
class AssessmentScreen extends StatefulWidget {
  /// Grid size of each round, in order.
  final List<int> rounds;

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
    this.rounds = const [2, 3, 3],
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
  late GameState _gameState;
  int _round = 0;
  bool _transitioning = false;
  Timer? _timer;
  AssessmentResult? _result;

  @override
  void initState() {
    super.initState();
    _recorder = AssessmentRecorder(clock: widget.clock);
    _gameState = _newRound(0);
  }

  GameState _newRound(int index) {
    final size = widget.rounds[index];
    _recorder.startRound(size);
    return GameState.newPractice(size)..recorder = _recorder;
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
      // The old GameScreen detaches at the end of this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      return;
    }
    final result = _recorder.buildResult(userId: widget.userId);
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
    widget.onComplete?.call(result);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_result == null) _gameState.dispose();
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
    return AbsorbPointer(
      absorbing: _transitioning,
      child: GameScreen(
        key: ValueKey('assessment_round_$_round'),
        mode: GameMode.regularFlow,
        practiceGridSize: widget.rounds[_round],
        gameState: _gameState,
        onSolved: _onSolved,
        showRestart: false,
      ),
    );
  }
}

/// Results: one card per round with icons and numbers, and a "done" button.
class AssessmentResultsView extends StatelessWidget {
  final AssessmentResult result;
  final VoidCallback onDone;

  const AssessmentResultsView({
    super.key,
    required this.result,
    required this.onDone,
  });

  static String formatDuration(int? ms) {
    if (ms == null) return '–';
    final s = ms / 1000;
    if (s < 60) return '${s.toStringAsFixed(1)}s';
    final m = ms ~/ 60000;
    final rest = ((ms % 60000) / 1000).round();
    return '$m:${rest.toString().padLeft(2, '0')}';
  }

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
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        for (final r in result.rounds) _roundCard(st, r),
                      ],
                    ),
                  ),
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

  Widget _roundCard(VisualStyle st, RoundMetrics r) {
    Widget line(IconData icon, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: st.onTray.withOpacity(0.8), size: 24),
              const SizedBox(width: 10),
              Text(
                value,
                style: TextStyle(
                  color: st.onTray,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: st.trayCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: st.boardFrame.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view_rounded, color: st.boardFrame, size: 26),
              const SizedBox(width: 8),
              Text(
                '${r.gridSize}×${r.gridSize}',
                style: TextStyle(
                  color: st.boardFrame,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          line(Icons.timer_outlined, formatDuration(r.durationMs)),
          line(Icons.rotate_right, '${r.rotations}'),
          line(Icons.undo, '${r.backToBuilder}'),
          line(Icons.help_outline, '${r.helpOpens}'),
        ],
      ),
    );
  }
}
