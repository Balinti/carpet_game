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

                        // Total stars display
                        if (_progressionManager != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  '${_progressionManager!.totalStars} Stars',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),

                        // Section header
                        Text(
                          'Choose Your Grid',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                        const SizedBox(height: 24),

                        // Grid size cards
                        _GridSizeCard(
                          gridSize: GridSize.twoByTwo,
                          progressionManager: _progressionManager!,
                          onQuickPlay: () => _startQuickPlay(GridSize.twoByTwo),
                          onChallenges: () =>
                              _openChallenges(GridSize.twoByTwo),
                        ),
                        const SizedBox(height: 16),
                        _GridSizeCard(
                          gridSize: GridSize.threeByThree,
                          progressionManager: _progressionManager!,
                          onQuickPlay: () =>
                              _startQuickPlay(GridSize.threeByThree),
                          onChallenges: () =>
                              _openChallenges(GridSize.threeByThree),
                        ),
                        const SizedBox(height: 16),
                        _GridSizeCard(
                          gridSize: GridSize.fourByFour,
                          progressionManager: _progressionManager!,
                          onQuickPlay: () =>
                              _startQuickPlay(GridSize.fourByFour),
                          onChallenges: () =>
                              _openChallenges(GridSize.fourByFour),
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

  void _startQuickPlay(GridSize gridSize) {
    if (!_progressionManager!.isGridUnlocked(gridSize)) {
      _showLockedDialog(gridSize);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PuzzleScreen(
          gridSize: gridSize,
          progressionManager: _progressionManager,
        ),
      ),
    ).then((_) => _loadProgression());
  }

  void _openChallenges(GridSize gridSize) {
    if (!_progressionManager!.isGridUnlocked(gridSize)) {
      _showLockedDialog(gridSize);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengesScreen(
          gridSize: gridSize,
          progressionManager: _progressionManager!,
        ),
      ),
    ).then((_) => _loadProgression());
  }

  void _showLockedDialog(GridSize gridSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.grey),
            const SizedBox(width: 8),
            Text('${gridSize.displayName} Locked'),
          ],
        ),
        content: Text(
          _progressionManager!.getUnlockRequirementText(gridSize),
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

class _GridSizeCard extends StatelessWidget {
  final GridSize gridSize;
  final ProgressionManager progressionManager;
  final VoidCallback onQuickPlay;
  final VoidCallback onChallenges;

  const _GridSizeCard({
    required this.gridSize,
    required this.progressionManager,
    required this.onQuickPlay,
    required this.onChallenges,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = progressionManager.isGridUnlocked(gridSize);
    final completedCount = progressionManager.getCompletedCountForGrid(gridSize);
    final totalChallenges = ChallengeData.getChallengesForSize(gridSize).length;
    final stars = progressionManager.getTotalStarsForGrid(gridSize);
    final maxStars = totalChallenges * 3;

    // Grid icon based on size
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
        onTap: isUnlocked ? onQuickPlay : () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Grid icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isUnlocked ? gridColor : Colors.grey)
                          .withOpacity(0.15),
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
                  // Title and progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gridSize.displayName,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isUnlocked ? null : Colors.grey,
                                  ),
                        ),
                        if (isUnlocked) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$completedCount/$totalChallenges challenges',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '$stars/$maxStars',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.amber.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            progressionManager.getUnlockRequirementText(gridSize),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (isUnlocked) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onQuickPlay,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Quick Play'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onChallenges,
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('Challenges'),
                      ),
                    ),
                  ],
                ),
              ],
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
