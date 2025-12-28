/// Different game modes available in the app.
enum GameMode {
  /// Competitive Color Dominoes - players race to empty their hand.
  colorDominoes,

  /// Free Play sandbox - no rules, unlimited tiles, pure creativity.
  freePlay,

  /// Guided Learning - allows any placement with visual feedback on matches.
  guidedLearning,

  /// Cooperative Building - all players work together toward a shared goal.
  cooperative;

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
    }
  }

  bool get isCompetitive => this == GameMode.colorDominoes;
  bool get hasRules => this == GameMode.colorDominoes || this == GameMode.guidedLearning;
  bool get showMatchFeedback => this == GameMode.guidedLearning || this == GameMode.cooperative;
}
