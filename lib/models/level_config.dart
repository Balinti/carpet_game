/// Configuration for a single level in Regular Flow mode.
class LevelConfig {
  /// Level number (1-12).
  final int level;

  /// Grid size (e.g., 2 for 2x2, 3 for 3x3).
  final int gridSize;

  /// Whether to reset pieces to full 36 at this level.
  final bool resetPieces;

  /// Number of tiles needed to complete this level.
  int get tilesNeeded => gridSize * gridSize;

  const LevelConfig({
    required this.level,
    required this.gridSize,
    required this.resetPieces,
  });

  /// Get the display name for this level.
  String get displayName => 'Level $level';

  /// Get the grid description.
  String get gridDescription => '${gridSize}×$gridSize';
}

/// All level configurations for Regular Flow mode.
///
/// Level progression:
/// - Levels 1-3: 2x2 grids (36→32→28 pieces)
/// - Levels 4-5: 3x3 grids (36→27 pieces)
/// - Levels 6-8: 3x3 grids (36→27→18 pieces)
/// - Levels 9-10: 4x4 grids (36→20 pieces)
/// - Level 11: 5x5 grid (36 pieces)
/// - Level 12: 6x6 grid (36 pieces)
const List<LevelConfig> regularFlowLevels = [
  // 2x2 series (3 levels from same pool)
  LevelConfig(level: 1, gridSize: 2, resetPieces: true),   // 36 pieces
  LevelConfig(level: 2, gridSize: 2, resetPieces: false),  // 32 pieces (36-4)
  LevelConfig(level: 3, gridSize: 2, resetPieces: false),  // 28 pieces (32-4)

  // 3x3 first series (2 levels from same pool)
  LevelConfig(level: 4, gridSize: 3, resetPieces: true),   // 36 pieces (reset)
  LevelConfig(level: 5, gridSize: 3, resetPieces: false),  // 27 pieces (36-9)

  // 3x3 second series (3 levels from same pool)
  LevelConfig(level: 6, gridSize: 3, resetPieces: true),   // 36 pieces (reset)
  LevelConfig(level: 7, gridSize: 3, resetPieces: false),  // 27 pieces (36-9)
  LevelConfig(level: 8, gridSize: 3, resetPieces: false),  // 18 pieces (27-9)

  // 4x4 series (2 levels from same pool)
  LevelConfig(level: 9, gridSize: 4, resetPieces: true),   // 36 pieces (reset)
  LevelConfig(level: 10, gridSize: 4, resetPieces: false), // 20 pieces (36-16)

  // 5x5 single level
  LevelConfig(level: 11, gridSize: 5, resetPieces: true),  // 36 pieces (reset)

  // 6x6 final level
  LevelConfig(level: 12, gridSize: 6, resetPieces: true),  // 36 pieces (reset)
];

/// Get the level config for a specific level number.
LevelConfig getLevelConfig(int level) {
  if (level < 1 || level > regularFlowLevels.length) {
    throw ArgumentError('Invalid level: $level. Must be 1-${regularFlowLevels.length}');
  }
  return regularFlowLevels[level - 1];
}

/// Total number of levels in Regular Flow mode.
const int totalRegularFlowLevels = 12;
