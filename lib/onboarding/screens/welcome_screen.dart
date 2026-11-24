import 'package:flutter/material.dart';

import '../welcome/onboarding_look.dart';
import '../welcome/welcome_models.dart';

/// First screen for a signed-out player: what the game is, why we play it
/// and what comes next, then "Let's start" (sign up) or "I already have an
/// account" (sign in).
///
/// Three design models to compare, picked with `?welcome=1|2|3`
/// (see [OnboardingLook]).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onSignIn,
    required this.onCreateAccount,
  });

  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) => switch (OnboardingLook.current.model) {
        WelcomeModel.calm =>
          WelcomeCalm(onSignIn: onSignIn, onCreateAccount: onCreateAccount),
        WelcomeModel.playful =>
          WelcomePlayful(onSignIn: onSignIn, onCreateAccount: onCreateAccount),
        WelcomeModel.minimal =>
          WelcomeMinimal(onSignIn: onSignIn, onCreateAccount: onCreateAccount),
      };
}
