import 'package:flutter/material.dart';

/// Kid-friendly scoring system with stars and milestones.
class ScoreSystem {
  int _points = 0;
  int _tilesPlaced = 0;
  int _perfectMatches = 0;
  int _stars = 0;
  List<String> _achievements = [];

  // Getters
  int get points => _points;
  int get tilesPlaced => _tilesPlaced;
  int get perfectMatches => _perfectMatches;
  int get stars => _stars;
  List<String> get achievements => List.unmodifiable(_achievements);

  /// Points awarded for different actions.
  static const int pointsPerTile = 10;
  static const int pointsPerMatch = 5;
  static const int pointsPerPerfectTile = 20; // All 4 edges match
  static const int pointsPerStar = 50;

  /// Add points for placing a tile.
  /// Returns the points earned and any new achievements.
  PlacementResult addTilePlacement({
    required int matchingEdges,
    required int totalAdjacentTiles,
  }) {
    _tilesPlaced++;
    int earned = pointsPerTile;
    List<String> newAchievements = [];

    // Bonus for matching edges
    earned += matchingEdges * pointsPerMatch;

    // Perfect match bonus (all adjacent edges match)
    if (totalAdjacentTiles > 0 && matchingEdges == totalAdjacentTiles) {
      _perfectMatches++;
      earned += pointsPerPerfectTile;
    }

    _points += earned;

    // Check for new stars
    int newStars = _points ~/ pointsPerStar;
    if (newStars > _stars) {
      int starsEarned = newStars - _stars;
      _stars = newStars;
      newAchievements.add('⭐ New Star${starsEarned > 1 ? 's' : ''}!');
    }

    // Milestone achievements
    if (_tilesPlaced == 1) {
      _achievements.add('First Tile!');
      newAchievements.add('🎉 First Tile!');
    }
    if (_tilesPlaced == 5) {
      _achievements.add('Getting Started');
      newAchievements.add('🌟 Getting Started!');
    }
    if (_tilesPlaced == 10) {
      _achievements.add('Tile Master');
      newAchievements.add('🏆 Tile Master!');
    }
    if (_tilesPlaced == 25) {
      _achievements.add('Carpet Builder');
      newAchievements.add('🎨 Carpet Builder!');
    }
    if (_perfectMatches == 1) {
      _achievements.add('Perfect Match');
      newAchievements.add('✨ Perfect Match!');
    }
    if (_perfectMatches == 5) {
      _achievements.add('Match Expert');
      newAchievements.add('💫 Match Expert!');
    }

    return PlacementResult(
      pointsEarned: earned,
      totalPoints: _points,
      matchingEdges: matchingEdges,
      isPerfectMatch: totalAdjacentTiles > 0 && matchingEdges == totalAdjacentTiles,
      newAchievements: newAchievements,
      stars: _stars,
    );
  }

  /// Reset the score.
  void reset() {
    _points = 0;
    _tilesPlaced = 0;
    _perfectMatches = 0;
    _stars = 0;
    _achievements = [];
  }

  /// Combine scores (for cooperative mode).
  void combineWith(ScoreSystem other) {
    _points += other._points;
    _tilesPlaced += other._tilesPlaced;
    _perfectMatches += other._perfectMatches;
    _stars = _points ~/ pointsPerStar;
  }
}

/// Result of placing a tile.
class PlacementResult {
  final int pointsEarned;
  final int totalPoints;
  final int matchingEdges;
  final bool isPerfectMatch;
  final List<String> newAchievements;
  final int stars;

  const PlacementResult({
    required this.pointsEarned,
    required this.totalPoints,
    required this.matchingEdges,
    required this.isPerfectMatch,
    required this.newAchievements,
    required this.stars,
  });

  bool get hasAchievements => newAchievements.isNotEmpty;
}

/// Visual feedback for edge matching.
enum EdgeMatchStatus {
  noAdjacent,  // No tile adjacent - neutral
  matching,    // Colors match - green/positive
  mismatched;  // Colors don't match - gentle hint

  Color get color {
    switch (this) {
      case EdgeMatchStatus.noAdjacent:
        return Colors.transparent;
      case EdgeMatchStatus.matching:
        return const Color.fromRGBO(76, 175, 80, 0.6); // Green with 0.6 opacity
      case EdgeMatchStatus.mismatched:
        return const Color.fromRGBO(255, 152, 0, 0.4); // Orange with 0.4 opacity
    }
  }

  Color get borderColor {
    switch (this) {
      case EdgeMatchStatus.noAdjacent:
        return Colors.grey;
      case EdgeMatchStatus.matching:
        return Colors.green;
      case EdgeMatchStatus.mismatched:
        return Colors.orange;
    }
  }
}
