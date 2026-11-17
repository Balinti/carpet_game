import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../main.dart';
import '../models/game_mode.dart';
import '../widgets/visual_style.dart';
import 'assessment_screen.dart';
import 'game_screen.dart';

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
                        const SizedBox(height: 32),

                        // Assessment: 2×2, 3×3, 3×3 with metrics.
                        const _AssessmentButton(),
                        const SizedBox(height: 16),

                        // Quick grids: 2x2 .. 6x6
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            for (var n = 2; n <= 6; n++)
                              FilledButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GameScreen(
                                      mode: GameMode.regularFlow,
                                      practiceGridSize: n,
                                    ),
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(72, 56),
                                  textStyle: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                child: Text('$n×$n'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Game modes section
                        _SectionHeader(
                          title: 'Choose Your Mode',
                          icon: Icons.play_circle_outline,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 20),

                        // Regular Flow
                        _GameModeCard(
                          title: 'Regular Flow',
                          subtitle: '12 levels of increasing challenge!\n2×2 → 3×3 → 4×4 → 5×5 → 6×6',
                          icon: Icons.trending_up,
                          iconColor: Colors.blue,
                          onTap: () => _startGame(context, GameMode.regularFlow),
                        ),
                        const SizedBox(height: 16),

                        // Shape Flow
                        _GameModeCard(
                          title: 'Shape Flow',
                          subtitle: 'Build 7 shapes while completing the grid!\nDiamonds, triangles, rectangles & arrows',
                          icon: Icons.category,
                          iconColor: Colors.teal,
                          onTap: () => _startGame(context, GameMode.shapeFlow),
                        ),

                        const SizedBox(height: 32),

                        // Level guide
                        _buildLevelGuide(context),
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

  Widget _buildLevelGuide(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Regular Flow Levels',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _levelRow(context, '1-3', '2×2', 'Same pieces across 3 levels'),
          _levelRow(context, '4-5', '3×3', 'Reset, then continue'),
          _levelRow(context, '6-8', '3×3', 'Reset, use pieces 3 times'),
          _levelRow(context, '9-10', '4×4', 'Reset, then continue'),
          _levelRow(context, '11', '5×5', 'Full 36 pieces'),
          _levelRow(context, '12', '6×6', 'Use all 36 pieces!'),
        ],
      ),
    );
  }

  Widget _levelRow(BuildContext context, String levels, String grid, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              levels,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              grid,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              note,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _startGame(BuildContext context, GameMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(mode: mode),
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
          width: 320,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 36,
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
                    const SizedBox(height: 4),
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

/// Soft 3D style entry button for the assessment.
class _AssessmentButton extends StatelessWidget {
  const _AssessmentButton();

  @override
  Widget build(BuildContext context) {
    const st = VisualStyle.soft3d;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [st.boardFrame, st.boardBackground[1]],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('assessment_button'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssessmentScreen()),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assignment_turned_in_outlined,
                    color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'Assessment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
