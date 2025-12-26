import 'package:flutter/material.dart';
import 'game_screen.dart';

/// Home screen with game mode selection.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: Center(
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
                  'Carpet Game',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tile Matching Challenge',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.8),
                      ),
                ),
                const SizedBox(height: 48),

                // Game mode selection
                _GameModeCard(
                  title: 'Color Dominoes',
                  subtitle: '2 Players - Pass and Play',
                  icon: Icons.people,
                  onTap: () => _startGame(context, 2),
                ),
                const SizedBox(height: 16),
                _GameModeCard(
                  title: 'Color Dominoes',
                  subtitle: '3 Players',
                  icon: Icons.groups,
                  onTap: () => _startGame(context, 3),
                ),
                const SizedBox(height: 16),
                _GameModeCard(
                  title: 'Color Dominoes',
                  subtitle: '4 Players',
                  icon: Icons.group_add,
                  onTap: () => _startGame(context, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, int playerCount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(playerCount: playerCount),
      ),
    );
  }
}

class _GameModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _GameModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
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
          width: 280,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Column(
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
              const Spacer(),
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
