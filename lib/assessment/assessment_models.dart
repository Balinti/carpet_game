/// Data recorded for one assessment round (one grid).
///
/// All `*Ms` timestamps are milliseconds since the round started.
class RoundMetrics {
  final int gridSize;

  /// Grids of [gridSize] shown side by side in this round (sharing one tray).
  final int boards;
  final DateTime startedAt;

  /// Round start → solved (null if the round was never solved).
  final int? durationMs;

  /// First interaction (pick, place, rotate, ...) since round start.
  final int? firstInteractionMs;

  final int rotationsCw;
  final int rotationsCcw;

  /// Timestamp of every placement of a tray piece onto the board.
  final List<int> placementTimestampsMs;

  /// Time between consecutive placements (length = placements - 1).
  final List<int> placementIntervalsMs;

  /// Time from picking a tray piece (tap select or drag start) to placing it.
  final List<int> pickToPlaceMs;

  /// Timestamps of every "back to Builder" (piece taken off the board).
  final List<int> backToBuilderTimestampsMs;

  final int helpOpens;

  /// Swaps / moves of pieces already on the board.
  final int boardMoves;

  /// Tray piece dropped onto an occupied square (old piece back to tray).
  final int replacements;

  /// Mismatched edges when the grid first became full (null = never full).
  final int? mismatchesWhenFirstFull;

  /// Fewest rotations that would have turned the pieces of the finished
  /// board from how they were dealt into place (null = unknown / unsolved).
  final int? minRotations;

  /// "I finished" pressed while the board still had mistakes.
  final int wrongFinishChecks;

  /// Times this round was left and continued later.
  final int resumes;

  const RoundMetrics({
    required this.gridSize,
    this.boards = 1,
    required this.startedAt,
    this.durationMs,
    this.firstInteractionMs,
    this.rotationsCw = 0,
    this.rotationsCcw = 0,
    this.placementTimestampsMs = const [],
    this.placementIntervalsMs = const [],
    this.pickToPlaceMs = const [],
    this.backToBuilderTimestampsMs = const [],
    this.helpOpens = 0,
    this.boardMoves = 0,
    this.replacements = 0,
    this.mismatchesWhenFirstFull,
    this.minRotations,
    this.wrongFinishChecks = 0,
    this.resumes = 0,
  });

  int get rotations => rotationsCw + rotationsCcw;
  int get backToBuilder => backToBuilderTimestampsMs.length;
  int get placements => placementTimestampsMs.length;
  bool get solved => durationMs != null;

  /// e.g. "2×2" or "2×(3×3)".
  String get label =>
      boards > 1 ? '$boards×($gridSize×$gridSize)' : '$gridSize×$gridSize';

  /// Time from the first interaction to solved, if both are known.
  int? get activeDurationMs =>
      durationMs == null ? null : durationMs! - (firstInteractionMs ?? 0);

  Map<String, dynamic> toJson() => {
        'gridSize': gridSize,
        'boards': boards,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'durationMs': durationMs,
        'firstInteractionMs': firstInteractionMs,
        'rotationsCw': rotationsCw,
        'rotationsCcw': rotationsCcw,
        'placementTimestampsMs': placementTimestampsMs,
        'placementIntervalsMs': placementIntervalsMs,
        'pickToPlaceMs': pickToPlaceMs,
        'backToBuilderTimestampsMs': backToBuilderTimestampsMs,
        'helpOpens': helpOpens,
        'boardMoves': boardMoves,
        'replacements': replacements,
        'mismatchesWhenFirstFull': mismatchesWhenFirstFull,
        'minRotations': minRotations,
        'wrongFinishChecks': wrongFinishChecks,
        'resumes': resumes,
      };

  factory RoundMetrics.fromJson(Map<String, dynamic> j) {
    List<int> ints(String k) =>
        ((j[k] as List?) ?? const []).map((e) => (e as num).toInt()).toList();
    int? optInt(String k) => (j[k] as num?)?.toInt();
    return RoundMetrics(
      gridSize: (j['gridSize'] as num).toInt(),
      boards: (j['boards'] as num?)?.toInt() ?? 1,
      startedAt: DateTime.parse(j['startedAt'] as String),
      durationMs: optInt('durationMs'),
      firstInteractionMs: optInt('firstInteractionMs'),
      rotationsCw: optInt('rotationsCw') ?? 0,
      rotationsCcw: optInt('rotationsCcw') ?? 0,
      placementTimestampsMs: ints('placementTimestampsMs'),
      placementIntervalsMs: ints('placementIntervalsMs'),
      pickToPlaceMs: ints('pickToPlaceMs'),
      backToBuilderTimestampsMs: ints('backToBuilderTimestampsMs'),
      helpOpens: optInt('helpOpens') ?? 0,
      boardMoves: optInt('boardMoves') ?? 0,
      replacements: optInt('replacements') ?? 0,
      mismatchesWhenFirstFull: optInt('mismatchesWhenFirstFull'),
      minRotations: optInt('minRotations'),
      wrongFinishChecks: optInt('wrongFinishChecks') ?? 0,
      resumes: optInt('resumes') ?? 0,
    );
  }
}

/// A full assessment: several rounds played in order.
class AssessmentResult {
  /// Local id (millis of startedAt by default); stores may use it as doc id.
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;

  /// Filled later by the auth layer (e.g. Firebase uid).
  final String? userId;
  final List<RoundMetrics> rounds;

  AssessmentResult({
    String? id,
    required this.startedAt,
    this.completedAt,
    this.userId,
    required this.rounds,
  }) : id = id ?? startedAt.toUtc().millisecondsSinceEpoch.toString();

  AssessmentResult copyWith({String? userId, DateTime? completedAt}) =>
      AssessmentResult(
        id: id,
        startedAt: startedAt,
        completedAt: completedAt ?? this.completedAt,
        userId: userId ?? this.userId,
        rounds: rounds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'completedAt': completedAt?.toUtc().toIso8601String(),
        'userId': userId,
        'rounds': rounds.map((r) => r.toJson()).toList(),
      };

  factory AssessmentResult.fromJson(Map<String, dynamic> j) => AssessmentResult(
        id: j['id'] as String?,
        startedAt: DateTime.parse(j['startedAt'] as String),
        completedAt: j['completedAt'] == null
            ? null
            : DateTime.parse(j['completedAt'] as String),
        userId: j['userId'] as String?,
        rounds: ((j['rounds'] as List?) ?? const [])
            .map((r) =>
                RoundMetrics.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}
