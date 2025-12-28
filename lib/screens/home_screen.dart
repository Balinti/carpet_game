import 'package:flutter/material.dart';
import '../models/game_mode.dart';
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
          child: SingleChildScrollView(
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
                      'Carpet Game',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tile Matching Fun!',
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
                      title: 'For Kids',
                      icon: Icons.child_care,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _GameModeCard(
                      mode: GameMode.freePlay,
                      subtitle: 'Solo Creative Play',
                      icon: Icons.brush,
                      iconColor: Colors.orange,
                      onTap: () => _startGame(context, GameMode.freePlay, 1),
                    ),
                    const SizedBox(height: 12),
                    _GameModeCard(
                      mode: GameMode.guidedLearning,
                      subtitle: 'Learn at Your Own Pace',
                      icon: Icons.lightbulb_outline,
                      iconColor: Colors.amber,
                      onTap: () => _startGame(context, GameMode.guidedLearning, 1),
                    ),

                    const SizedBox(height: 32),

                    // Cooperative modes section
                    _SectionHeader(
                      title: 'Play Together',
                      icon: Icons.groups,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _GameModeCard(
                      mode: GameMode.cooperative,
                      subtitle: '2 Players - Team Up!',
                      icon: Icons.favorite,
                      iconColor: Colors.pink,
                      onTap: () => _startGame(context, GameMode.cooperative, 2),
                    ),
                    const SizedBox(height: 12),
                    _GameModeCard(
                      mode: GameMode.cooperative,
                      subtitle: '3-4 Players - Family Fun!',
                      icon: Icons.family_restroom,
                      iconColor: Colors.green,
                      onTap: () => _showPlayerCountDialog(context, GameMode.cooperative),
                    ),

                    const SizedBox(height: 32),

                    // Competitive modes section
                    _SectionHeader(
                      title: 'Challenge Mode',
                      icon: Icons.emoji_events,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _GameModeCard(
                      mode: GameMode.colorDominoes,
                      subtitle: '2 Players - Pass and Play',
                      icon: Icons.people,
                      iconColor: Colors.blue,
                      onTap: () => _startGame(context, GameMode.colorDominoes, 2),
                    ),
                    const SizedBox(height: 12),
                    _GameModeCard(
                      mode: GameMode.colorDominoes,
                      subtitle: '3-4 Players',
                      icon: Icons.group_add,
                      iconColor: Colors.indigo,
                      onTap: () => _showPlayerCountDialog(context, GameMode.colorDominoes),
                    ),
                  ],
                ),
              ),
            ),
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

  void _showPlayerCountDialog(BuildContext context, GameMode mode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How many players?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Text('3')),
              title: const Text('3 Players'),
              onTap: () {
                Navigator.pop(context);
                _startGame(context, mode, 3);
              },
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('4')),
              title: const Text('4 Players'),
              onTap: () {
                Navigator.pop(context);
                _startGame(context, mode, 4);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
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
  final GameMode mode;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _GameModeCard({
    required this.mode,
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
                      mode.displayName,
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
