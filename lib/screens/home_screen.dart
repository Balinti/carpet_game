import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../main.dart';
import '../models/game_mode.dart';
import 'game_screen.dart';
import 'starter_puzzle_screen.dart';

/// Home screen with game mode selection.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
              // Language selector button
              Positioned(
                top: 8,
                right: 8,
                child: _LanguageButton(),
              ),
              // Version indicator (to verify deployment)
              Positioned(
                bottom: 8,
                left: 8,
                child: Text(
                  'v2.3.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
                  ),
                ),
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
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.appSubtitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.8),
                              ),
                        ),
                        const SizedBox(height: 40),

                        // Kid-friendly modes section
                        _SectionHeader(
                          title: l10n.forKids,
                          icon: Icons.child_care,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        _GameModeCard(
                          title: l10n.freePlay,
                          subtitle: l10n.soloCreativePlay,
                          icon: Icons.brush,
                          iconColor: Colors.orange,
                          onTap: () => _startGame(context, GameMode.freePlay, 1),
                        ),
                        const SizedBox(height: 12),
                        _GameModeCard(
                          title: l10n.learningMode,
                          subtitle: l10n.learnAtYourPace,
                          icon: Icons.lightbulb_outline,
                          iconColor: Colors.amber,
                          onTap: () => _startGame(context, GameMode.guidedLearning, 1),
                        ),
                        const SizedBox(height: 12),
                        _GameModeCard(
                          title: l10n.starterPuzzle,
                          subtitle: l10n.fillThe3x3Grid,
                          icon: Icons.grid_3x3,
                          iconColor: Colors.purple,
                          onTap: () => _startStarterPuzzle(context),
                        ),

                        const SizedBox(height: 32),

                        // Cooperative modes section
                        _SectionHeader(
                          title: l10n.playTogether,
                          icon: Icons.groups,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _GameModeCard(
                          title: l10n.buildTogether,
                          subtitle: l10n.twoPlayersTeamUp,
                          icon: Icons.favorite,
                          iconColor: Colors.pink,
                          onTap: () => _startGame(context, GameMode.cooperative, 2),
                        ),
                        const SizedBox(height: 12),
                        _GameModeCard(
                          title: l10n.buildTogether,
                          subtitle: l10n.familyFun,
                          icon: Icons.family_restroom,
                          iconColor: Colors.green,
                          onTap: () => _showPlayerCountDialog(context, GameMode.cooperative),
                        ),

                        const SizedBox(height: 32),

                        // Competitive modes section
                        _SectionHeader(
                          title: l10n.challengeMode,
                          icon: Icons.emoji_events,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _GameModeCard(
                          title: l10n.colorDominoes,
                          subtitle: l10n.twoPlayersPassPlay,
                          icon: Icons.people,
                          iconColor: Colors.blue,
                          onTap: () => _startGame(context, GameMode.colorDominoes, 2),
                        ),
                        const SizedBox(height: 12),
                        _GameModeCard(
                          title: l10n.colorDominoes,
                          subtitle: l10n.threeFourPlayers,
                          icon: Icons.group_add,
                          iconColor: Colors.indigo,
                          onTap: () => _showPlayerCountDialog(context, GameMode.colorDominoes),
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

  void _startGame(BuildContext context, GameMode mode, int playerCount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          mode: mode,
          playerCount: playerCount,
        ),
      ),
    );
  }

  void _startStarterPuzzle(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StarterPuzzleScreen(),
      ),
    );
  }

  void _showPlayerCountDialog(BuildContext context, GameMode mode) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.howManyPlayers),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Text('3')),
              title: Text(l10n.threePlayers),
              onTap: () {
                Navigator.pop(dialogContext);
                _startGame(context, mode, 3);
              },
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('4')),
              title: Text(l10n.fourPlayers),
              onTap: () {
                Navigator.pop(dialogContext);
                _startGame(context, mode, 4);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _GameModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _GameModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
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
