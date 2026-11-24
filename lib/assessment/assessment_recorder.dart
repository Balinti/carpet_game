import 'assessment_models.dart';
import 'clock.dart';

/// Records play metrics for an assessment, one round at a time.
///
/// GameState calls the `on*` hooks; the assessment flow calls
/// [startRound] / [completeRound] / [buildResult].
class AssessmentRecorder {
  final Clock clock;
  final DateTime startedAt;
  final List<RoundMetrics> rounds = [];

  _RoundBuilder? _round;

  AssessmentRecorder({Clock? clock})
      : clock = clock ?? const SystemClock(),
        startedAt = (clock ?? const SystemClock()).now();

  bool get inRound => _round != null;

  /// Begin recording a new round (discards an unfinished one).
  void startRound(int gridSize, {int boards = 1}) {
    _round = _RoundBuilder(gridSize, clock.now(), boards: boards);
  }

  int _ms() => clock.now().difference(_round!.startedAt).inMilliseconds;

  /// Time since the current round started (0 when none is running).
  int get elapsedMs => _round == null ? 0 : _ms();

  /// Continue a round saved earlier: its counts and timestamps are kept and
  /// the clock goes on from [elapsedMs] (time away is not counted).
  void resumeRound(RoundMetrics m, int elapsedMs) {
    final r = _RoundBuilder(
        m.gridSize, clock.now().subtract(Duration(milliseconds: elapsedMs)),
        boards: m.boards)
      ..firstInteractionMs = m.firstInteractionMs
      ..cw = m.rotationsCw
      ..ccw = m.rotationsCcw
      ..help = m.helpOpens
      ..moves = m.boardMoves
      ..replacements = m.replacements
      ..mismatchesWhenFirstFull = m.mismatchesWhenFirstFull
      ..wrongFinishChecks = m.wrongFinishChecks
      ..resumes = m.resumes + 1
      ..gaveUpMs = m.gaveUpMs;
    r.deal.addAll(m.deal);
    r.moveLog.addAll(m.moves);
    r.placements.addAll(m.placementTimestampsMs);
    r.intervals.addAll(m.placementIntervalsMs);
    r.pickToPlace.addAll(m.pickToPlaceMs);
    r.backToBuilder.addAll(m.backToBuilderTimestampsMs);
    _round = r;
  }

  void _touch() {
    final r = _round!;
    r.firstInteractionMs ??= _ms();
  }

  /// A tray piece was picked (tap-selected or drag started).
  /// Picking the same piece again keeps the earliest pick time.
  void onPick(String tileId) {
    final r = _round;
    if (r == null || r.solvedMs != null) return;
    _touch();
    if (r.pendingPickId == tileId) return;
    r.pendingPickId = tileId;
    r.pendingPickMs = _ms();
  }

  /// The picked piece was let go without being placed (deselect / drag cancel).
  void onPickCancelled(String tileId) {
    final r = _round;
    if (r == null || r.pendingPickId != tileId) return;
    r.pendingPickId = null;
    r.pendingPickMs = null;
  }

  /// A tray piece landed on the board.
  void onPlace(String tileId, {bool replacement = false}) {
    final r = _round;
    if (r == null || r.solvedMs != null) return;
    _touch();
    final t = _ms();
    if (r.placements.isNotEmpty) r.intervals.add(t - r.placements.last);
    r.placements.add(t);
    if (r.pendingPickId == tileId && r.pendingPickMs != null) {
      r.pickToPlace.add(t - r.pendingPickMs!);
    }
    r.pendingPickId = null;
    r.pendingPickMs = null;
    if (replacement) r.replacements++;
  }

  /// Any rotation (placed piece or tray piece).
  void onRotate({bool counterClockwise = false}) {
    final r = _round;
    if (r == null || r.solvedMs != null) return;
    _touch();
    if (counterClockwise) {
      r.ccw++;
    } else {
      r.cw++;
    }
  }

  void onBackToBuilder() {
    final r = _round;
    if (r == null || r.solvedMs != null) return;
    _touch();
    r.backToBuilder.add(_ms());
  }

  void onHelpOpened() {
    final r = _round;
    if (r == null || r.solvedMs != null) return;
    r.help++;
  }

  /// A piece already on the board was swapped / moved.
  void onBoardMove() {
    final r = _round;
    if (r == null || r.solvedMs != null) return;
    _touch();
    r.moves++;
  }

  /// Grid is full; only the first time per round is kept.
  void onGridFull(int mismatches) {
    final r = _round;
    if (r == null) return;
    r.mismatchesWhenFirstFull ??= mismatches;
  }

  /// Grid is full and every edge matches; only the first time is kept.
  void onSolved({int? minRotations}) {
    final r = _round;
    if (r == null || r.solvedMs != null) return;
    r.solvedMs = _ms();
    r.minRotations = minRotations;
  }

  /// Pieces dealt for this round, "id:TRBL" (only the first deal counts).
  void onDeal(List<String> codes) {
    final r = _round;
    if (r == null || r.deal.isNotEmpty) return;
    r.deal.addAll(codes);
  }

  /// One entry of the move log (replayable). [kind] see RoundMetrics.moves.
  void log(String kind, Map<String, Object?> data) {
    final r = _round;
    if (r == null || (r.solvedMs != null && kind != 'solved')) return;
    r.moveLog.add({'t': _ms(), 'k': kind, ...data});
  }

  /// "I'm stuck": the round ends without a solution.
  void onGiveUp() {
    final r = _round;
    if (r == null || r.solvedMs != null) return;
    r.gaveUpMs ??= _ms();
  }

  /// "I finished" was pressed on a full board; [correct] = no mistakes.
  void onFinishCheck({required bool correct}) {
    final r = _round;
    if (r == null || r.solvedMs != null) return;
    if (!correct) r.wrongFinishChecks++;
  }

  /// Snapshot of the current round so far (null when no round is running).
  RoundMetrics? get currentRound => _round?.build();

  /// Close the current round and append it to [rounds].
  RoundMetrics completeRound() {
    final m = _round!.build();
    rounds.add(m);
    _round = null;
    return m;
  }

  AssessmentResult buildResult({String? userId}) => AssessmentResult(
        startedAt: startedAt,
        completedAt: clock.now(),
        userId: userId,
        rounds: List.unmodifiable(rounds),
      );
}

class _RoundBuilder {
  final int gridSize;
  final int boards;
  final DateTime startedAt;
  int? firstInteractionMs;
  int? solvedMs;
  int cw = 0;
  int ccw = 0;
  int help = 0;
  int moves = 0;
  int replacements = 0;
  int? mismatchesWhenFirstFull;
  int? minRotations;
  int wrongFinishChecks = 0;
  int resumes = 0;
  int? gaveUpMs;
  final List<String> deal = [];
  final List<Map<String, dynamic>> moveLog = [];
  final List<int> placements = [];
  final List<int> intervals = [];
  final List<int> pickToPlace = [];
  final List<int> backToBuilder = [];
  String? pendingPickId;
  int? pendingPickMs;

  _RoundBuilder(this.gridSize, this.startedAt, {this.boards = 1});

  RoundMetrics build() => RoundMetrics(
        gridSize: gridSize,
        boards: boards,
        startedAt: startedAt,
        durationMs: solvedMs,
        firstInteractionMs: firstInteractionMs,
        rotationsCw: cw,
        rotationsCcw: ccw,
        placementTimestampsMs: List.unmodifiable(placements),
        placementIntervalsMs: List.unmodifiable(intervals),
        pickToPlaceMs: List.unmodifiable(pickToPlace),
        backToBuilderTimestampsMs: List.unmodifiable(backToBuilder),
        helpOpens: help,
        boardMoves: moves,
        replacements: replacements,
        mismatchesWhenFirstFull: mismatchesWhenFirstFull,
        minRotations: minRotations,
        wrongFinishChecks: wrongFinishChecks,
        resumes: resumes,
        gaveUpMs: gaveUpMs,
        deal: List.unmodifiable(deal),
        moves: List.unmodifiable(moveLog),
      );
}
