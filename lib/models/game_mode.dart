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
  shapeBuilder;

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
    }
  }

  bool get isCompetitive => this == GameMode.colorDominoes;
  bool get hasRules => this == GameMode.colorDominoes || this == GameMode.guidedLearning || this == GameMode.starterPuzzle;
  bool get showMatchFeedback => this == GameMode.guidedLearning || this == GameMode.cooperative || this == GameMode.starterPuzzle;

  /// Whether this mode uses deferred validation (results shown only when board is complete).
  bool get hasDeferredValidation => this == GameMode.shapeBuilder;

  /// Whether this mode allows free placement without matching requirements.
  bool get allowsFreePlacement => this == GameMode.freePlay || this == GameMode.guidedLearning || this == GameMode.shapeBuilder;
}
