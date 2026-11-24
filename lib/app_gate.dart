import 'package:flutter/material.dart';

import 'assessment/assessment.dart';
import 'firestore_stores.dart';
import 'onboarding/account_deletion_firebase.dart';
import 'onboarding/auth/firebase_auth_service.dart';
import 'onboarding/onboarding.dart';
import 'screens/assessment_screen.dart';
import 'screens/home_screen.dart';
import 'admin/dashboard_screen.dart';
import 'telemetry.dart';
import 'main.dart' show forceLandscape;
import 'package:cloud_firestore/cloud_firestore.dart';

/// App flow: sign up / sign in → confirm email → EF questionnaire (by age)
/// → first assessment (2×2, 3×3, 3×3) → home screen.
/// Returning users who finished all steps go straight to home.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  /// Shared auth instance (also used by the home screen's sign-out).
  static final AuthService auth = FirebaseAuthService();

  @override
  State<AppGate> createState() => _AppGateState();
}

enum _Stage { onboarding, checking, assessment, home }

class _AppGateState extends State<AppGate> {
  _Stage _stage = _Stage.onboarding;
  String? _uid;

  bool _isAdmin = false;

  Future<void> _afterOnboarding(
      UserProfile profile, QuestionnaireResult _) async {
    Telemetry.log('session_start', {'ageGroup': profile.ageGroup.name});
    FirebaseFirestore.instance.collection('admins').doc(profile.uid).get().then(
        (d) {
      if (mounted && d.exists) setState(() => _isAdmin = true);
    }, onError: (_) {});
    setState(() {
      _uid = profile.uid;
      _stage = _Stage.checking;
    });
    var hasAssessment = false;
    try {
      hasAssessment =
          (await FirestoreAssessmentStore(profile.uid).all()).isNotEmpty;
    } catch (_) {}
    if (!mounted) return;
    setState(() => _stage = hasAssessment ? _Stage.home : _Stage.assessment);
  }

  @override
  Widget build(BuildContext context) {
    // Never turn the app ourselves: it follows how the phone is held, the
    // same on every screen (Shemer: switching orientation was confusing).
    const landscape = false;
    if (forceLandscape.value != landscape) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => forceLandscape.value = landscape);
    }
    switch (_stage) {
      case _Stage.onboarding:
        return OnboardingFlow(
          auth: AppGate.auth,
          profileStore: FirestoreProfileStore(),
          questionnaireStore: FirestoreQuestionnaireStore(),
          onDone: _afterOnboarding,
        );
      case _Stage.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _Stage.assessment:
        return AssessmentScreen(
          userId: _uid,
          store: FirestoreAssessmentStore(_uid!),
          onDone: () => setState(() => _stage = _Stage.home),
        );
      case _Stage.home:
        return HomeScreen(
          onOpenDashboard: _isAdmin
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  )
              : null,
          onSignOut: () async {
            await AppGate.auth.signOut();
            if (mounted) setState(() => _stage = _Stage.onboarding);
          },
          accountDeletion: firebaseAccountDeletion(),
          onAccountDeleted: () {
            if (!mounted) return;
            Navigator.of(context).popUntil((r) => r.isFirst);
            setState(() {
              _uid = null;
              _isAdmin = false;
              _stage = _Stage.onboarding;
            });
          },
        );
    }
  }
}
