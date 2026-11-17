import 'package:flutter/material.dart';

import '../onboarding_strings.dart';
import 'onboarding_ui.dart';

/// First screen for a signed-out player: two big choices.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onSignIn,
    required this.onCreateAccount,
  });

  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final s = OnboardingStrings.of(context);
    Widget big(Widget b) => SizedBox(width: 300, height: 72, child: b);
    final buttons = [
      big(BigButton(
        key: const ValueKey('welcome_signin'),
        label: s.welcomeSignIn,
        icon: Icons.login,
        onPressed: onSignIn,
      )),
      const SizedBox(width: 20, height: 20),
      big(BigButton(
        key: const ValueKey('welcome_create'),
        label: s.welcomeCreate,
        icon: Icons.person_add_alt_1,
        primary: false,
        onPressed: onCreateAccount,
      )),
    ];
    return OnboardingBackground(
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > c.maxHeight;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.grid_view_rounded,
                    size: 64, color: Colors.white),
                const SizedBox(height: 12),
                OnboardingTitle(s.welcomeTitle),
                const SizedBox(height: 28),
                wide
                    ? Row(mainAxisSize: MainAxisSize.min, children: buttons)
                    : Column(mainAxisSize: MainAxisSize.min, children: buttons),
              ],
            ),
          ),
        );
      }),
    );
  }
}
