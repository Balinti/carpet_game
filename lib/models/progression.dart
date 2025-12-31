import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'challenge.dart';

/// Manages player progression, unlocks, and saved results.
class ProgressionManager {
  static const String _prefsKey = 'carpet_game_progression';

  /// Completed challenges with their results
  final Map<String, ChallengeResult> _completedChallenges;

  /// Unlocked grid sizes
  final Set<GridSize> _unlockedGrids;

  /// Total stars earned
  int _totalStars;

  ProgressionManager._({
    required Map<String, ChallengeResult> completedChallenges,
    required Set<GridSize> unlockedGrids,
    required int totalStars,
  })  : _completedChallenges = completedChallenges,
        _unlockedGrids = unlockedGrids,
        _totalStars = totalStars;

  /// Create a new progression manager with default state.
  factory ProgressionManager.initial() {
    return ProgressionManager._(
      completedChallenges: {},
      unlockedGrids: {GridSize.twoByTwo}, // 2x2 unlocked by default
      totalStars: 0,
    );
  }

  /// Load progression from shared preferences.
  static Future<ProgressionManager> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);

      if (jsonString == null) {
        return ProgressionManager.initial();
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final completedChallenges = <String, ChallengeResult>{};
      final challengesData = data['completedChallenges'] as Map<String, dynamic>?;
      if (challengesData != null) {
        for (final entry in challengesData.entries) {
          final result = entry.value as Map<String, dynamic>;
          completedChallenges[entry.key] = ChallengeResult(
            challengeId: result['challengeId'] as String,
            completed: result['completed'] as bool,
            timeSeconds: result['timeSeconds'] as int,
            rotations: result['rotations'] as int,
            stars: result['stars'] as int,
          );
        }
      }

      final unlockedGrids = <GridSize>{};
      final gridsData = data['unlockedGrids'] as List<dynamic>?;
      if (gridsData != null) {
        for (final gridIndex in gridsData) {
          if (gridIndex >= 0 && gridIndex < GridSize.values.length) {
            unlockedGrids.add(GridSize.values[gridIndex as int]);
          }
        }
      }
      // Ensure 2x2 is always unlocked
      unlockedGrids.add(GridSize.twoByTwo);

      return ProgressionManager._(
        completedChallenges: completedChallenges,
        unlockedGrids: unlockedGrids,
        totalStars: data['totalStars'] as int? ?? 0,
      );
    } catch (e) {
      // If loading fails, return initial state
      return ProgressionManager.initial();
    }
  }

  /// Save progression to shared preferences.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    final challengesData = <String, Map<String, dynamic>>{};
    for (final entry in _completedChallenges.entries) {
      challengesData[entry.key] = {
        'challengeId': entry.value.challengeId,
        'completed': entry.value.completed,
        'timeSeconds': entry.value.timeSeconds,
        'rotations': entry.value.rotations,
        'stars': entry.value.stars,
      };
    }

    final data = {
      'completedChallenges': challengesData,
      'unlockedGrids': _unlockedGrids.map((g) => g.index).toList(),
      'totalStars': _totalStars,
    };

    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  /// Get completed challenges map.
  Map<String, ChallengeResult> get completedChallenges =>
      Map.unmodifiable(_completedChallenges);

  /// Get unlocked grid sizes.
  Set<GridSize> get unlockedGrids => Set.unmodifiable(_unlockedGrids);

  /// Get total stars earned.
  int get totalStars => _totalStars;

  /// Check if a grid size is unlocked.
  bool isGridUnlocked(GridSize gridSize) {
    return _unlockedGrids.contains(gridSize);
  }

  /// Check if a challenge is completed.
  bool isChallengeCompleted(String challengeId) {
    return _completedChallenges.containsKey(challengeId);
  }

  /// Get stars for a completed challenge.
  int getStarsForChallenge(String challengeId) {
    return _completedChallenges[challengeId]?.stars ?? 0;
  }

  /// Get number of completed challenges for a grid size.
  int getCompletedCountForGrid(GridSize gridSize) {
    final challenges = ChallengeData.getChallengesForSize(gridSize);
    return challenges.where((c) => isChallengeCompleted(c.id)).length;
  }

  /// Get total stars for a grid size.
  int getTotalStarsForGrid(GridSize gridSize) {
    final challenges = ChallengeData.getChallengesForSize(gridSize);
    int stars = 0;
    for (final challenge in challenges) {
      stars += getStarsForChallenge(challenge.id);
    }
    return stars;
  }

  /// Check if a challenge is unlocked.
  bool isChallengeUnlocked(Challenge challenge) {
    if (!isGridUnlocked(challenge.gridSize)) return false;
    final completedCount = getCompletedCountForGrid(challenge.gridSize);
    return completedCount >= challenge.unlockRequirement;
  }

  /// Record a challenge completion.
  Future<void> completeChallenge(ChallengeResult result) async {
    final existingResult = _completedChallenges[result.challengeId];

    // Only update if this is a new completion or better result
    if (existingResult == null || result.stars > existingResult.stars) {
      // Calculate star difference
      final oldStars = existingResult?.stars ?? 0;
      _totalStars += result.stars - oldStars;

      _completedChallenges[result.challengeId] = result;

      // Check for grid unlocks based on progress
      _checkUnlocks();

      await save();
    }
  }

  /// Check and unlock grids based on progress.
  void _checkUnlocks() {
    // Unlock 3x3 after completing 3 challenges in 2x2
    if (getCompletedCountForGrid(GridSize.twoByTwo) >= 3) {
      _unlockedGrids.add(GridSize.threeByThree);
    }

    // Unlock 4x4 after completing 5 challenges in 3x3
    if (getCompletedCountForGrid(GridSize.threeByThree) >= 5) {
      _unlockedGrids.add(GridSize.fourByFour);
    }
  }

  /// Get unlock requirements text for a grid size.
  String getUnlockRequirementText(GridSize gridSize) {
    switch (gridSize) {
      case GridSize.twoByTwo:
        return 'Unlocked!';
      case GridSize.threeByThree:
        final completed = getCompletedCountForGrid(GridSize.twoByTwo);
        if (_unlockedGrids.contains(gridSize)) {
          return 'Unlocked!';
        }
        return 'Complete $completed/3 challenges in 2x2';
      case GridSize.fourByFour:
        final completed = getCompletedCountForGrid(GridSize.threeByThree);
        if (_unlockedGrids.contains(gridSize)) {
          return 'Unlocked!';
        }
        return 'Complete $completed/5 challenges in 3x3';
    }
  }

  /// Reset all progression (for testing).
  Future<void> reset() async {
    _completedChallenges.clear();
    _unlockedGrids.clear();
    _unlockedGrids.add(GridSize.twoByTwo);
    _totalStars = 0;
    await save();
  }
}
