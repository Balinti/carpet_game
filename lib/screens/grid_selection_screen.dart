import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../main.dart';
import '../models/challenge.dart';
import '../models/progression.dart';
import 'puzzle_screen.dart';
import 'challenges_screen.dart';

/// Main menu screen for selecting grid size.
class GridSelectionScreen extends StatefulWidget {
  const GridSelectionScreen({super.key});

  @override
  State<GridSelectionScreen> createState() => _GridSelectionScreenState();
}

class _GridSelectionScreenState extends State<GridSelectionScreen> {
  ProgressionManager? _progressionManager;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgression();
  }

  Future<void> _loadProgression() async {
    final manager = await ProgressionManager.load();
    if (mounted) {
      setState(() {
        _progressionManager = manager;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Language selector
              Positioned(
                top: 8,
                right: 8,
                child: _LanguageButton(),
              ),
              // Main content
              SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo/Title
                        const Icon(
                          Icons.grid_view_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.appTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.appSubtitle,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withOpacity(0.8),
                                  ),
                        ),

                        const SizedBox(height: 40),

                        // Free Play section header
                        Text(
                          'Free Play',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All 64 tiles available',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withOpacity(0.7),
                                  ),
                        ),
                        const SizedBox(height: 24),

                        // Grid size cards - all unlocked
                        _FreePlayCard(
                          gridSize: GridSize.twoByTwo,
                          onPlay: () => _startFreePlay(GridSize.twoByTwo),
                        ),
                        const SizedBox(height: 16),
                        _FreePlayCard(
                          gridSize: GridSize.threeByThree,
                          onPlay: () => _startFreePlay(GridSize.threeByThree),
                        ),
                        const SizedBox(height: 16),
                        _FreePlayCard(
                          gridSize: GridSize.fourByFour,
                          onPlay: () => _startFreePlay(GridSize.fourByFour),
                        ),

                        const SizedBox(height: 40),

                        // Challenge Mode section
                        Text(
                          'Challenge Mode',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete challenges to earn stars!',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withOpacity(0.7),
                                  ),
                        ),
                        const SizedBox(height: 24),

                        // Challenge Mode Card
                        _ChallengeModeCard(
                          progressionManager: _progressionManager!,
                          onTap: () => _openChallengeMode(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startFreePlay(GridSize gridSize) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PuzzleScreen(
          gridSize: gridSize,
          // No challenge or progression for free play
        ),
      ),
    );
  }

  void _openChallengeMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeModeScreen(
          progressionManager: _progressionManager!,
        ),
      ),
    ).then((_) => _loadProgression());
  }
}

/// Card for free play modes - always unlocked
class _FreePlayCard extends StatelessWidget {
  final GridSize gridSize;
  final VoidCallback onPlay;

  const _FreePlayCard({
    required this.gridSize,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    // Grid icon and color based on size
    IconData gridIcon;
    Color gridColor;
    switch (gridSize) {
      case GridSize.twoByTwo:
        gridIcon = Icons.grid_4x4;
        gridColor = Colors.green;
        break;
      case GridSize.threeByThree:
        gridIcon = Icons.grid_3x3;
        gridColor = Colors.blue;
        break;
      case GridSize.fourByFour:
        gridIcon = Icons.grid_on;
        gridColor = Colors.purple;
        break;
    }

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Grid icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: gridColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  gridIcon,
                  size: 40,
                  color: gridColor,
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gridSize.displayName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${gridSize.tileCount} tiles to fill',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              // Play button
              FilledButton(
                onPressed: onPlay,
                child: const Text('Play'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for challenge mode with progression
class _ChallengeModeCard extends StatelessWidget {
  final ProgressionManager progressionManager;
  final VoidCallback onTap;

  const _ChallengeModeCard({
    required this.progressionManager,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalStars = progressionManager.totalStars;

    // Count total completed challenges across all grid sizes
    int totalCompleted = 0;
    int totalChallenges = 0;
    for (final gridSize in GridSize.values) {
      totalCompleted += progressionManager.getCompletedCountForGrid(gridSize);
      totalChallenges += ChallengeData.getChallengesForSize(gridSize).length;
    }

    return Card(
      elevation: 4,
      color: Colors.amber.shade50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  // Trophy icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 40,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Challenges',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalCompleted/$totalChallenges completed',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stars display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '$totalStars Stars Earned',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Enter button
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Enter Challenge Mode'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localeProvider = LocaleProviderScope.of(context);
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<AppLanguage>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 20),
            const SizedBox(width: 4),
            Text(
              localeProvider.language.displayName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      tooltip: l10n.selectLanguage,
      onSelected: (language) {
        localeProvider.setLanguage(language);
      },
      itemBuilder: (context) => AppLanguage.values.map((language) {
        final isSelected = language == localeProvider.language;
        return PopupMenuItem<AppLanguage>(
          value: language,
          child: Row(
            children: [
              if (isSelected)
                const Icon(Icons.check, size: 20)
              else
                const SizedBox(width: 20),
              const SizedBox(width: 8),
              Text(
                language.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Challenge mode screen with grid selection for challenges
class ChallengeModeScreen extends StatelessWidget {
  final ProgressionManager progressionManager;

  const ChallengeModeScreen({
    super.key,
    required this.progressionManager,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Mode'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Total stars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      '${progressionManager.totalStars} Total Stars',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Grid size challenge cards
              _ChallengeGridCard(
                gridSize: GridSize.twoByTwo,
                progressionManager: progressionManager,
                isUnlocked: true, // 2x2 always unlocked
              ),
              const SizedBox(height: 16),
              _ChallengeGridCard(
                gridSize: GridSize.threeByThree,
                progressionManager: progressionManager,
                isUnlocked: progressionManager.isGridUnlocked(GridSize.threeByThree),
              ),
              const SizedBox(height: 16),
              _ChallengeGridCard(
                gridSize: GridSize.fourByFour,
                progressionManager: progressionManager,
                isUnlocked: progressionManager.isGridUnlocked(GridSize.fourByFour),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeGridCard extends StatelessWidget {
  final GridSize gridSize;
  final ProgressionManager progressionManager;
  final bool isUnlocked;

  const _ChallengeGridCard({
    required this.gridSize,
    required this.progressionManager,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = progressionManager.getCompletedCountForGrid(gridSize);
    final totalChallenges = ChallengeData.getChallengesForSize(gridSize).length;
    final stars = progressionManager.getTotalStarsForGrid(gridSize);
    final maxStars = totalChallenges * 3;

    // Grid icon and color
    IconData gridIcon;
    Color gridColor;
    switch (gridSize) {
      case GridSize.twoByTwo:
        gridIcon = Icons.grid_4x4;
        gridColor = Colors.green;
        break;
      case GridSize.threeByThree:
        gridIcon = Icons.grid_3x3;
        gridColor = Colors.blue;
        break;
      case GridSize.fourByFour:
        gridIcon = Icons.grid_on;
        gridColor = Colors.purple;
        break;
    }

    return Card(
      elevation: isUnlocked ? 4 : 1,
      color: isUnlocked ? null : Colors.grey.shade300,
      child: InkWell(
        onTap: isUnlocked
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChallengesScreen(
                      gridSize: gridSize,
                      progressionManager: progressionManager,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Grid icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isUnlocked ? gridColor : Colors.grey).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Icon(
                      gridIcon,
                      size: 40,
                      color: isUnlocked ? gridColor : Colors.grey,
                    ),
                    if (!isUnlocked)
                      const Positioned(
                        right: -4,
                        bottom: -4,
                        child: Icon(
                          Icons.lock,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${gridSize.displayName} Challenges',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? null : Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (isUnlocked) ...[
                      Text(
                        '$completedCount/$totalChallenges completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '$stars/$maxStars',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        progressionManager.getUnlockRequirementText(gridSize),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow
              if (isUnlocked)
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
