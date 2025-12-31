/// Different game modes available in the app.
enum GameMode {
  /// Competitive Color Dominoes - players race to empty their hand.
  colorDominoes,

  /// Free Play sandbox - no rules, unlimited tiles, pure creativity.
  freePlay,

  /// Guided Learning - allows any placement with visual feedback on matches.
  guidedLearning,

  /// Cooperative Building - all players work together toward a shared goal.
  cooperative,

  /// Starter Puzzle - 3x3 grid puzzle with all tiles, rotation counter and timer.
  starterPuzzle,

  /// Shape Builder - build shapes based on colors with deferred validation.
  shapeBuilder,

  /// Geometric Shapes - build geometric patterns like squares, rectangles, etc.
  geometricShapes,

  /// Square 2x2 - build a 2x2 square.
  square2x2,

  /// Square 3x3 - build a 3x3 square.
  square3x3,

  /// Square 4x4 - build a 4x4 square.
  square4x4,

  /// Square Progression - build 2x2, then 3x3, then 4x4.
  squareProgression;

  String get displayName {
    switch (this) {
      case GameMode.colorDominoes:
        return 'Color Dominoes';
      case GameMode.freePlay:
        return 'Free Play';
      case GameMode.guidedLearning:
        return 'Learning Mode';
      case GameMode.cooperative:
        return 'Build Together';
      case GameMode.starterPuzzle:
        return 'Starter Puzzle';
      case GameMode.shapeBuilder:
        return 'Shape Builder';
      case GameMode.geometricShapes:
        return 'Geometric Shapes';
      case GameMode.square2x2:
        return '2×2 Square';
      case GameMode.square3x3:
        return '3×3 Square';
      case GameMode.square4x4:
        return '4×4 Square';
      case GameMode.squareProgression:
        return 'Progression';
    }
  }

  String get description {
    switch (this) {
      case GameMode.colorDominoes:
        return 'Race to place all your tiles first!';
      case GameMode.freePlay:
        return 'Create anything you want - no rules!';
      case GameMode.guidedLearning:
        return 'Learn to match colors at your own pace';
      case GameMode.cooperative:
        return 'Work together to build a beautiful carpet!';
      case GameMode.starterPuzzle:
        return 'Fill the 3x3 grid with matching colors!';
      case GameMode.shapeBuilder:
        return 'Build shapes by color - see results when done!';
      case GameMode.geometricShapes:
        return 'Build squares, rectangles, and more!';
      case GameMode.square2x2:
        return 'Build a 2×2 square!';
      case GameMode.square3x3:
        return 'Build a 3×3 square!';
      case GameMode.square4x4:
        return 'Build a 4×4 square!';
      case GameMode.squareProgression:
        return '2×2 → 3×3 → 4×4 in sequence!';
    }
  }

  bool get isCompetitive => this == GameMode.colorDominoes;
  bool get hasRules => this == GameMode.colorDominoes || this == GameMode.guidedLearning || this == GameMode.starterPuzzle || this == GameMode.geometricShapes || this == GameMode.square2x2 || this == GameMode.square3x3 || this == GameMode.square4x4 || this == GameMode.squareProgression;
  bool get showMatchFeedback => this == GameMode.guidedLearning || this == GameMode.cooperative || this == GameMode.starterPuzzle || this == GameMode.geometricShapes || this == GameMode.square2x2 || this == GameMode.square3x3 || this == GameMode.square4x4 || this == GameMode.squareProgression;

  /// Whether this mode uses deferred validation (results shown only when board is complete).
  bool get hasDeferredValidation => this == GameMode.shapeBuilder;

  /// Whether this mode allows free placement without matching requirements.
  bool get allowsFreePlacement => this == GameMode.freePlay || this == GameMode.guidedLearning || this == GameMode.shapeBuilder || this == GameMode.geometricShapes || this == GameMode.square2x2 || this == GameMode.square3x3 || this == GameMode.square4x4 || this == GameMode.squareProgression;

  /// Whether this is a square building mode.
  bool get isSquareMode => this == GameMode.square2x2 || this == GameMode.square3x3 || this == GameMode.square4x4 || this == GameMode.squareProgression;
}
