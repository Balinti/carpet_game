/// Different game modes available in the app.
enum GameMode {
  /// Regular Flow - progress through 12 levels with increasing grid sizes.
  /// Pieces are tracked across levels, with resets at specific levels.
  regularFlow,

  /// Shape Flow - build shapes while completing the entire matrix.
  /// Must match the requested shape AND fill the grid following regular rules.
  shapeFlow;

  String get displayName {
    switch (this) {
      case GameMode.regularFlow:
        return 'Regular Flow';
      case GameMode.shapeFlow:
        return 'Shape Flow';
    }
  }

  String get description {
    switch (this) {
      case GameMode.regularFlow:
        return 'Progress through 12 levels with increasing difficulty!';
      case GameMode.shapeFlow:
        return 'Build shapes while completing the matrix!';
    }
  }

  bool get isCompetitive => false;
  bool get hasRules => true;
  bool get showMatchFeedback => true;
  bool get allowsFreePlacement => true;
  bool get isSquareMode => true;
}
