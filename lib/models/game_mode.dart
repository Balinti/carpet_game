/// Different game modes available in the app.
enum GameMode {
  colorDominoes,
  freePlay,
  guidedLearning,
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

  bool get isCompetitive => this == GameMode.colorDominoes;
  bool get showMatchFeedback => this == GameMode.guidedLearning || this == GameMode.cooperative;
}
