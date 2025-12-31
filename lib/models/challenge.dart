import 'carpet_tile.dart';
import 'tile_color.dart';

/// Types of challenges available in the game.
enum ChallengeType {
  /// Free build - just complete the grid with matching edges
  freeBuild,

  /// Match a specific pattern shown to the player
  matchPattern,

  /// Use only specific tile types (solid, two-color, etc.)
  specificTiles,

  /// Create a geometric shape (diamond, triangle, etc.)
  geometricShape,

  /// Create color chains (connected colors)
  colorChain,

  /// Symmetry challenge - create symmetric patterns
  symmetry,

  /// Place solid tiles in specific positions
  solidPlacement,

  /// Mixed constraints combining multiple rules
  mixedConstraints,
}

/// Difficulty levels for challenges.
enum ChallengeDifficulty {
  beginner,
  intermediate,
  advanced,
}

/// Grid size for puzzle modes.
enum GridSize {
  twoByTwo(2, 4),
  threeByThree(3, 9),
  fourByFour(4, 16);

  final int size;
  final int tileCount;

  const GridSize(this.size, this.tileCount);

  String get displayName => '${size}x$size';
}

/// Represents a challenge in the game.
class Challenge {
  final String id;
  final String name;
  final String description;
  final GridSize gridSize;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;

  /// Optional: Target pattern to match (for matchPattern type)
  final List<CarpetTile?>? targetPattern;

  /// Optional: Required tile constraints
  final ChallengeConstraints? constraints;

  /// Number of challenges to complete before unlocking this one
  final int unlockRequirement;

  const Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.gridSize,
    required this.type,
    required this.difficulty,
    this.targetPattern,
    this.constraints,
    this.unlockRequirement = 0,
  });

  /// Check if this challenge is unlocked based on completed challenges count
  bool isUnlocked(int completedChallenges) {
    return completedChallenges >= unlockRequirement;
  }
}

/// Constraints for a challenge.
class ChallengeConstraints {
  /// Require solid tiles at specific positions (grid indices)
  final List<int>? solidPositions;

  /// Require specific color at center (for 3x3)
  final TileColor? centerColor;

  /// Require only certain number of colors
  final int? maxColors;

  /// Require minimum matching edges
  final int? minMatchingEdges;

  /// Require symmetric pattern
  final bool? requireSymmetry;

  /// Require specific tile types
  final List<String>? requiredTileTypes;

  const ChallengeConstraints({
    this.solidPositions,
    this.centerColor,
    this.maxColors,
    this.minMatchingEdges,
    this.requireSymmetry,
    this.requiredTileTypes,
  });
}

/// Result of completing a challenge.
class ChallengeResult {
  final String challengeId;
  final bool completed;
  final int timeSeconds;
  final int rotations;
  final int stars; // 1-3 stars based on performance

  const ChallengeResult({
    required this.challengeId,
    required this.completed,
    required this.timeSeconds,
    required this.rotations,
    required this.stars,
  });

  /// Calculate stars based on time and rotations.
  static int calculateStars({
    required int timeSeconds,
    required int rotations,
    required GridSize gridSize,
  }) {
    // Base thresholds vary by grid size
    final baseTime = gridSize.tileCount * 10; // 10 seconds per tile
    final baseRotations = gridSize.tileCount * 2; // 2 rotations per tile

    int stars = 1; // Always at least 1 star for completion

    // Time bonus
    if (timeSeconds < baseTime * 0.5) {
      stars += 1;
    }

    // Rotation efficiency bonus
    if (rotations < baseRotations * 0.5) {
      stars += 1;
    }

    return stars.clamp(1, 3);
  }
}

/// Predefined challenges for each grid size.
class ChallengeData {
  /// 2x2 challenges - Basic pattern matching
  static List<Challenge> get twoByTwoChallenges => [
    const Challenge(
      id: '2x2_free_1',
      name: 'First Steps',
      description: 'Complete the 2x2 grid with matching colors',
      gridSize: GridSize.twoByTwo,
      type: ChallengeType.freeBuild,
      difficulty: ChallengeDifficulty.beginner,
      unlockRequirement: 0,
    ),
    const Challenge(
      id: '2x2_free_2',
      name: 'Quick Builder',
      description: 'Complete the grid in under 30 seconds',
      gridSize: GridSize.twoByTwo,
      type: ChallengeType.freeBuild,
      difficulty: ChallengeDifficulty.beginner,
      unlockRequirement: 1,
    ),
    const Challenge(
      id: '2x2_solid_1',
      name: 'Solid Start',
      description: 'Use at least one solid-colored tile',
      gridSize: GridSize.twoByTwo,
      type: ChallengeType.solidPlacement,
      difficulty: ChallengeDifficulty.beginner,
      unlockRequirement: 2,
    ),
    const Challenge(
      id: '2x2_efficient',
      name: 'Efficient Builder',
      description: 'Complete with less than 4 rotations',
      gridSize: GridSize.twoByTwo,
      type: ChallengeType.freeBuild,
      difficulty: ChallengeDifficulty.intermediate,
      unlockRequirement: 3,
    ),
    const Challenge(
      id: '2x2_color_1',
      name: 'Color Match',
      description: 'All touching edges must match',
      gridSize: GridSize.twoByTwo,
      type: ChallengeType.colorChain,
      difficulty: ChallengeDifficulty.intermediate,
      unlockRequirement: 4,
    ),
  ];

  /// 3x3 challenges - Pattern constraints
  static List<Challenge> get threeByThreeChallenges => [
    const Challenge(
      id: '3x3_free_1',
      name: 'Grid Master',
      description: 'Complete the 3x3 grid with matching colors',
      gridSize: GridSize.threeByThree,
      type: ChallengeType.freeBuild,
      difficulty: ChallengeDifficulty.beginner,
      unlockRequirement: 0,
    ),
    const Challenge(
      id: '3x3_center_solid',
      name: 'Center Piece',
      description: 'Place a solid tile in the center',
      gridSize: GridSize.threeByThree,
      type: ChallengeType.solidPlacement,
      difficulty: ChallengeDifficulty.beginner,
      constraints: ChallengeConstraints(solidPositions: [4]),
      unlockRequirement: 1,
    ),
    const Challenge(
      id: '3x3_corners_solid',
      name: 'Corner Strategy',
      description: 'Place solid tiles in all corners',
      gridSize: GridSize.threeByThree,
      type: ChallengeType.solidPlacement,
      difficulty: ChallengeDifficulty.intermediate,
      constraints: ChallengeConstraints(solidPositions: [0, 2, 6, 8]),
      unlockRequirement: 2,
    ),
    const Challenge(
      id: '3x3_quick',
      name: 'Speed Runner',
      description: 'Complete in under 60 seconds',
      gridSize: GridSize.threeByThree,
      type: ChallengeType.freeBuild,
      difficulty: ChallengeDifficulty.intermediate,
      unlockRequirement: 3,
    ),
    const Challenge(
      id: '3x3_minimal_rotations',
      name: 'Perfect Placement',
      description: 'Complete with less than 9 rotations',
      gridSize: GridSize.threeByThree,
      type: ChallengeType.freeBuild,
      difficulty: ChallengeDifficulty.intermediate,
      unlockRequirement: 4,
    ),
    const Challenge(
      id: '3x3_diamond',
      name: 'Diamond Pattern',
      description: 'Create a diamond pattern with solid tiles',
      gridSize: GridSize.threeByThree,
      type: ChallengeType.geometricShape,
      difficulty: ChallengeDifficulty.advanced,
      constraints: ChallengeConstraints(solidPositions: [1, 3, 5, 7]),
      unlockRequirement: 5,
    ),
    const Challenge(
      id: '3x3_color_chain',
      name: 'Color River',
      description: 'Create a connected chain of the same color',
      gridSize: GridSize.threeByThree,
      type: ChallengeType.colorChain,
      difficulty: ChallengeDifficulty.advanced,
      unlockRequirement: 6,
    ),
    const Challenge(
      id: '3x3_all_solid',
      name: 'Solid Master',
      description: 'Use only solid-colored tiles',
      gridSize: GridSize.threeByThree,
      type: ChallengeType.specificTiles,
      difficulty: ChallengeDifficulty.advanced,
      unlockRequirement: 7,
    ),
  ];

  /// 4x4 challenges - Complex patterns
  static List<Challenge> get fourByFourChallenges => [
    const Challenge(
      id: '4x4_free_1',
      name: 'Grand Grid',
      description: 'Complete the 4x4 grid with matching colors',
      gridSize: GridSize.fourByFour,
      type: ChallengeType.freeBuild,
      difficulty: ChallengeDifficulty.beginner,
      unlockRequirement: 0,
    ),
    const Challenge(
      id: '4x4_corners',
      name: 'Four Corners',
      description: 'Place solid tiles in all corners',
      gridSize: GridSize.fourByFour,
      type: ChallengeType.solidPlacement,
      difficulty: ChallengeDifficulty.intermediate,
      constraints: ChallengeConstraints(solidPositions: [0, 3, 12, 15]),
      unlockRequirement: 1,
    ),
    const Challenge(
      id: '4x4_center_square',
      name: 'Inner Square',
      description: 'Place solid tiles in the center 4 squares',
      gridSize: GridSize.fourByFour,
      type: ChallengeType.solidPlacement,
      difficulty: ChallengeDifficulty.intermediate,
      constraints: ChallengeConstraints(solidPositions: [5, 6, 9, 10]),
      unlockRequirement: 2,
    ),
    const Challenge(
      id: '4x4_quick',
      name: 'Speed Demon',
      description: 'Complete in under 90 seconds',
      gridSize: GridSize.fourByFour,
      type: ChallengeType.freeBuild,
      difficulty: ChallengeDifficulty.intermediate,
      unlockRequirement: 3,
    ),
    const Challenge(
      id: '4x4_symmetry',
      name: 'Mirror Mirror',
      description: 'Create a horizontally symmetric pattern',
      gridSize: GridSize.fourByFour,
      type: ChallengeType.symmetry,
      difficulty: ChallengeDifficulty.advanced,
      constraints: ChallengeConstraints(requireSymmetry: true),
      unlockRequirement: 4,
    ),
    const Challenge(
      id: '4x4_diagonal',
      name: 'Diagonal Master',
      description: 'Place solid tiles on the main diagonal',
      gridSize: GridSize.fourByFour,
      type: ChallengeType.geometricShape,
      difficulty: ChallengeDifficulty.advanced,
      constraints: ChallengeConstraints(solidPositions: [0, 5, 10, 15]),
      unlockRequirement: 5,
    ),
    const Challenge(
      id: '4x4_cross',
      name: 'The Cross',
      description: 'Create a cross pattern with solid tiles',
      gridSize: GridSize.fourByFour,
      type: ChallengeType.geometricShape,
      difficulty: ChallengeDifficulty.advanced,
      constraints: ChallengeConstraints(solidPositions: [1, 2, 4, 7, 8, 11, 13, 14]),
      unlockRequirement: 6,
    ),
    const Challenge(
      id: '4x4_master',
      name: 'Carpet Master',
      description: 'Complete with less than 16 rotations',
      gridSize: GridSize.fourByFour,
      type: ChallengeType.freeBuild,
      difficulty: ChallengeDifficulty.advanced,
      unlockRequirement: 7,
    ),
  ];

  /// Get all challenges for a specific grid size.
  static List<Challenge> getChallengesForSize(GridSize size) {
    switch (size) {
      case GridSize.twoByTwo:
        return twoByTwoChallenges;
      case GridSize.threeByThree:
        return threeByThreeChallenges;
      case GridSize.fourByFour:
        return fourByFourChallenges;
    }
  }
}
