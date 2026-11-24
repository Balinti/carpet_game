import 'package:flutter/material.dart';

import '../../models/tile_color.dart';
import '../ef/ef_questions.dart';
import '../onboarding_strings.dart';
import '../screens/onboarding_ui.dart';
import 'language_toggle.dart';
import 'tile_art.dart';

/// Number of questionnaire items (same for kids and adults).
int get _questionCount => kidQuestions.length;

/// Top row on every welcome model: language switch + "I have an account".
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSignIn, this.showSignIn = true});
  final VoidCallback onSignIn;
  final bool showSignIn;

  @override
  Widget build(BuildContext context) {
    final s = OnboardingStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          const LanguageToggle(),
          const Spacer(),
          if (showSignIn)
            Flexible(
              child: OnboardingLink(
                key: const ValueKey('welcome_signin'),
                label: s.haveAccount,
                onPressed: onSignIn,
              ),
            ),
        ],
      ),
    );
  }
}

/// Shared pager state for models 1 and 2.
mixin _Pager<T extends StatefulWidget> on State<T> {
  final controller = PageController();
  int page = 0;

  int get pageCount => 3;
  bool get last => page == pageCount - 1;

  void nextPage() => controller.nextPage(
      duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Model 1: calm step-by-step cards with progress dots.
// ---------------------------------------------------------------------------

class WelcomeCalm extends StatefulWidget {
  const WelcomeCalm(
      {super.key, required this.onSignIn, required this.onCreateAccount});
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  State<WelcomeCalm> createState() => _WelcomeCalmState();
}

class _WelcomeCalmState extends State<WelcomeCalm> with _Pager<WelcomeCalm> {
  @override
  Widget build(BuildContext context) {
    final s = OnboardingStrings.of(context);
    final l = look;
    return OnboardingBackground(
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > c.maxHeight;
        final cards = [
          _card(
            wide,
            art: TileMosaic(rows: 2, cols: 2, tileSize: wide ? 44 : 54, gap: 3),
            title: s.welcomeHello,
            body: s.welcomeForWho,
            extra: Text(s.howBody,
                style: TextStyle(color: l.muted, fontSize: 16, height: 1.35)),
          ),
          _card(
            wide,
            art: _iconBadge(Icons.lightbulb_outline_rounded),
            title: s.goalTitle,
            body: s.goalBody,
            extra: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.route_rounded, s.goalPlan),
                _chip(Icons.psychology_rounded, s.goalRemember),
                _chip(Icons.center_focus_strong_rounded, s.goalFocus),
              ],
            ),
          ),
          _card(
            wide,
            art: _iconBadge(Icons.flag_rounded),
            title: s.stepsTitle,
            extra: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _step(1, s.stepAccount),
                _step(2, s.stepQuestions(_questionCount)),
                _step(3, s.stepPlay),
              ],
            ),
          ),
        ];
        return Column(
          children: [
            _TopBar(onSignIn: widget.onSignIn),
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (i) => setState(() => page = i),
                children: [
                  for (final card in cards)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: wide ? 6 : 16),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: wide ? 680 : 520),
                          child: SizedBox(width: double.infinity, child: card),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, wide ? 8 : 20),
              child: Row(
                children: [
                  for (var i = 0; i < pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsetsDirectional.only(end: 8),
                      width: i == page ? 26 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: i == page ? l.accent : l.border,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  const Spacer(),
                  last
                      ? BigButton(
                          key: const ValueKey('welcome_create'),
                          label: s.letsStart,
                          icon: Icons.arrow_forward_rounded,
                          onPressed: widget.onCreateAccount,
                        )
                      : BigButton(
                          key: const ValueKey('welcome_next'),
                          label: s.next,
                          onPressed: nextPage,
                        ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _card(bool wide,
      {required Widget art,
      required String title,
      String? body,
      Widget? extra}) {
    final l = look;
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingTitle(title),
        if (body != null) ...[
          const SizedBox(height: 10),
          Text(body,
              style: TextStyle(color: l.text, fontSize: 18, height: 1.4)),
        ],
        if (extra != null) ...[const SizedBox(height: 14), extra],
      ],
    );
    return OnboardingPanel(
      compact: wide,
      child: SingleChildScrollView(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  art,
                  const SizedBox(width: 20),
                  Expanded(child: text),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [art, const SizedBox(height: 18), text],
              ),
      ),
    );
  }

  Widget _iconBadge(IconData icon) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: look.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: look.accent, size: 34),
      );

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F6F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: look.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: look.accent),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: look.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _step(int n, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: look.accent,
                shape: BoxShape.circle,
              ),
              child: Text('$n',
                  style: TextStyle(
                      color: look.onAccent,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: look.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Model 2: playful, big tile art from the game's own pieces.
// ---------------------------------------------------------------------------

class WelcomePlayful extends StatefulWidget {
  const WelcomePlayful(
      {super.key, required this.onSignIn, required this.onCreateAccount});
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  State<WelcomePlayful> createState() => _WelcomePlayfulState();
}

class _WelcomePlayfulState extends State<WelcomePlayful>
    with _Pager<WelcomePlayful> {
  static const _yellow = Color(0xFFFFE100);

  @override
  Widget build(BuildContext context) {
    final s = OnboardingStrings.of(context);
    return OnboardingBackground(
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > c.maxHeight;
        return Column(
          children: [
            _TopBar(onSignIn: widget.onSignIn),
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (i) => setState(() => page = i),
                children: [
                  _page(
                    wide,
                    art: (box) {
                      final t = ((box.biggest.shortestSide - 30) / 3.6)
                          .clamp(34.0, 96.0);
                      return TileMosaic(
                        rows: 3,
                        cols: 3,
                        tileSize: t,
                        gap: t * 0.06,
                        seed: 3,
                        missing: (0, 2),
                      );
                    },
                    title: s.welcomeHello,
                    body: s.howBody,
                  ),
                  _page(
                    wide,
                    art: (box) {
                      final t = ((wide ? box.maxWidth : box.maxWidth) / 3.9)
                          .clamp(40.0, 104.0)
                          .clamp(40.0, box.maxHeight - 34);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _skill(TileColor.red, Icons.route_rounded, s.goalPlan,
                              t),
                          _skill(TileColor.green, Icons.psychology_rounded,
                              s.goalRemember, t),
                          _skill(
                              TileColor.blue,
                              Icons.center_focus_strong_rounded,
                              s.goalFocus,
                              t),
                        ],
                      );
                    },
                    title: s.goalTitle,
                    body: s.goalBody,
                  ),
                  _page(
                    wide,
                    art: (box) {
                      final t = ((box.maxHeight - 24) / 3.4).clamp(36.0, 64.0);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _numbered(1, TileColor.blue, s.stepAccount, t),
                          _numbered(2, TileColor.green,
                              s.stepQuestions(_questionCount), t),
                          _numbered(3, TileColor.red, s.stepPlay, t),
                        ],
                      );
                    },
                    title: s.stepsTitle,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, wide ? 8 : 20),
              child: Row(
                children: [
                  for (var i = 0; i < pageCount; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: i <= page ? 1 : 0.3,
                        child: TileArt.solid(
                          TileColor.values[(i + 2) % 4],
                          size: i == page ? 26 : 20,
                        ),
                      ),
                    ),
                  const Spacer(),
                  last
                      ? BigButton(
                          key: const ValueKey('welcome_create'),
                          label: s.letsStart,
                          icon: Icons.play_arrow_rounded,
                          onPressed: widget.onCreateAccount,
                        )
                      : BigButton(
                          key: const ValueKey('welcome_next'),
                          label: s.next,
                          icon: Icons.arrow_forward_rounded,
                          onPressed: nextPage,
                        ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _page(bool wide,
      {required Widget Function(BoxConstraints box) art,
      required String title,
      String? body}) {
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            color: _yellow,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: TextStyle(color: look.text, fontSize: 19, height: 1.4),
          ),
        ],
      ],
    );
    final artBox = LayoutBuilder(
      builder: (context, box) => Center(child: art(box)),
    );
    if (wide) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            Expanded(flex: 5, child: artBox),
            const SizedBox(width: 20),
            Expanded(
                flex: 5,
                child: Center(child: SingleChildScrollView(child: text))),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        children: [
          Expanded(flex: 6, child: artBox),
          const SizedBox(height: 16),
          Flexible(flex: 4, child: SingleChildScrollView(child: text)),
        ],
      ),
    );
  }

  Widget _skill(TileColor c, IconData icon, String label, double t) => Padding(
        padding: EdgeInsets.symmetric(horizontal: t * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TileArt.solid(c,
                size: t, child: Icon(icon, color: Colors.white, size: t * 0.5)),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: look.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _numbered(int n, TileColor c, String label, double t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TileArt.solid(c,
                size: t,
                child: Text('$n',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: t * 0.45,
                        fontWeight: FontWeight.w900))),
            const SizedBox(width: 12),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      color: look.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Model 3: minimal, one screen, one big start button.
// ---------------------------------------------------------------------------

class WelcomeMinimal extends StatelessWidget {
  const WelcomeMinimal(
      {super.key, required this.onSignIn, required this.onCreateAccount});
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final s = OnboardingStrings.of(context);
    final l = look;
    final head = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TileMosaic(rows: 1, cols: 3, tileSize: 30, gap: 3, seed: 5),
        const SizedBox(height: 18),
        OnboardingTitle(s.welcomeHello, size: 32),
        const SizedBox(height: 12),
        Text(s.minimalGoal,
            style: TextStyle(color: l.muted, fontSize: 18, height: 1.4)),
      ],
    );
    Widget step(int n, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text('$n',
                    style: TextStyle(
                        color: l.muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child:
                    Text(label, style: TextStyle(color: l.text, fontSize: 17)),
              ),
            ],
          ),
        );
    final action = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: l.border),
        const SizedBox(height: 10),
        step(1, s.stepAccount),
        step(2, s.stepQuestions(_questionCount)),
        step(3, s.stepPlay),
        const SizedBox(height: 18),
        SizedBox(
          height: 60,
          child: BigButton(
            key: const ValueKey('welcome_create'),
            label: s.letsStart,
            onPressed: onCreateAccount,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: OnboardingLink(
            key: const ValueKey('welcome_signin'),
            label: s.haveAccount,
            onPressed: onSignIn,
          ),
        ),
      ],
    );
    return OnboardingBackground(
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > c.maxHeight;
        return Column(
          children: [
            _TopBar(onSignIn: onSignIn, showSignIn: false),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 820 : 480),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: head),
                              const SizedBox(width: 40),
                              Expanded(child: action),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              head,
                              const SizedBox(height: 36),
                              action
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
