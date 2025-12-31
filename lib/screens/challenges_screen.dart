import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../models/progression.dart';
import 'puzzle_screen.dart';

/// Screen showing all challenges for a specific grid size.
class ChallengesScreen extends StatefulWidget {
  final GridSize gridSize;
  final ProgressionManager progressionManager;

  const ChallengesScreen({
    super.key,
    required this.gridSize,
    required this.progressionManager,
  });

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late ProgressionManager _progressionManager;

  @override
  void initState() {
    super.initState();
    _progressionManager = widget.progressionManager;
  }

  Future<void> _refreshProgression() async {
    final manager = await ProgressionManager.load();
    if (mounted) {
      setState(() {
        _progressionManager = manager;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenges = ChallengeData.getChallengesForSize(widget.gridSize);
    final completedCount = _progressionManager.getCompletedCountForGrid(widget.gridSize);
    final totalStars = _progressionManager.getTotalStarsForGrid(widget.gridSize);
    final maxStars = challenges.length * 3;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gridSize.displayName} Challenges'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Progress header
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Completed count
                Column(
                  children: [
                    Text(
                      '$completedCount/${challenges.length}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      'Completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
                // Divider
                Container(
                  height: 40,
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                // Stars
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 28),
                        const SizedBox(width: 4),
                        Text(
                          '$totalStars/$maxStars',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      'Stars',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Challenge list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return _ChallengeCard(
                  challenge: challenge,
                  progressionManager: _progressionManager,
                  onTap: () => _startChallenge(challenge),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _startChallenge(Challenge challenge) {
    if (!_progressionManager.isChallengeUnlocked(challenge)) {
      _showLockedDialog(challenge);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PuzzleScreen(
          gridSize: challenge.gridSize,
          challenge: challenge,
          progressionManager: _progressionManager,
        ),
      ),
    ).then((_) => _refreshProgression());
  }

  void _showLockedDialog(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.grey),
            SizedBox(width: 8),
            Text('Challenge Locked'),
          ],
        ),
        content: Text(
          'Complete ${challenge.unlockRequirement} challenges to unlock this one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final ProgressionManager progressionManager;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.challenge,
    required this.progressionManager,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = progressionManager.isChallengeUnlocked(challenge);
    final isCompleted = progressionManager.isChallengeCompleted(challenge.id);
    final stars = progressionManager.getStarsForChallenge(challenge.id);

    // Difficulty color
    Color difficultyColor;
    String difficultyText;
    switch (challenge.difficulty) {
      case ChallengeDifficulty.beginner:
        difficultyColor = Colors.green;
        difficultyText = 'Beginner';
        break;
      case ChallengeDifficulty.intermediate:
        difficultyColor = Colors.orange;
        difficultyText = 'Intermediate';
        break;
      case ChallengeDifficulty.advanced:
        difficultyColor = Colors.red;
        difficultyText = 'Advanced';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnlocked ? 2 : 0,
      color: isUnlocked ? null : Colors.grey.shade200,
      child: InkWell(
        onTap: isUnlocked ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.15)
                      : isUnlocked
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isUnlocked
                          ? Icons.play_circle_outline
                          : Icons.lock,
                  color: isCompleted
                      ? Colors.green
                      : isUnlocked
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Challenge info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? null : Colors.grey,
                                ),
                          ),
                        ),
                        // Difficulty badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (isUnlocked ? difficultyColor : Colors.grey)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            difficultyText,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isUnlocked ? difficultyColor : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isUnlocked
                                ? Theme.of(context).colorScheme.outline
                                : Colors.grey,
                          ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(3, (index) {
                          return Icon(
                            index < stars ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow
              if (isUnlocked)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
