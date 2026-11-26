import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import 'auth/auth_service.dart';
import 'ef/questionnaire_result.dart';
import 'ef/questionnaire_store.dart';
import 'profile/profile_store.dart';
import 'profile/user_profile.dart';
import 'screens/onboarding_ui.dart';
import 'screens/questionnaire_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/welcome_screen.dart';
import 'welcome/language_toggle.dart';

/// Sign up (or sign in) -> verify email -> EF questionnaire, then [onDone].
///
/// Resumes where the user left off: if [auth] already has a signed-in user,
/// it skips straight to verification / profile / questionnaire as needed, and
/// calls [onDone] right away if both a profile and a questionnaire result are
/// already stored. Everything happens inside this one widget (no routes, no
/// pop-ups), so it can be used as a `home:` or pushed as a page.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.auth,
    required this.onDone,
    ProfileStore? profileStore,
    QuestionnaireStore? questionnaireStore,
    this.clock,
  })  : profileStore = profileStore ?? const LocalProfileStore(),
        questionnaireStore =
            questionnaireStore ?? const LocalQuestionnaireStore();

  final AuthService auth;
  final ProfileStore profileStore;
  final QuestionnaireStore questionnaireStore;

  /// Called once, after the questionnaire result has been saved.
  final void Function(UserProfile profile, QuestionnaireResult result) onDone;

  /// For tests: overrides "now" for [UserProfile.createdAt].
  final DateTime Function()? clock;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

enum OnboardingStep {
  loading,
  welcome,
  signUp,
  signIn,
  verify,
  completeProfile,
  questionnaire,
  done
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  OnboardingStep _step = OnboardingStep.loading;
  UserProfile? _profile;
  String? _error;

  AuthService get _auth => widget.auth;

  @override
  void initState() {
    super.initState();
    // First start: switch the app to Hebrew. The whole app rebuilds right
    // after, so this instance just waits.
    if (applyDefaultLanguageOnce(context)) return;
    final user = _auth.currentUser;
    if (user == null) {
      _step = OnboardingStep.welcome;
    } else {
      _resume(user);
    }
  }

  void _go(OnboardingStep s) {
    if (mounted) setState(() => _step = s);
  }

  /// Routes a signed-in user to the next missing piece.
  Future<void> _resume(AuthUser user) async {
    _go(OnboardingStep.loading);
    try {
      if (!user.emailVerified && !await _auth.reloadAndCheckVerified()) {
        _go(OnboardingStep.verify);
        return;
      }
      await _afterVerified(user.uid);
    } catch (e) {
      // Can't reach the backend: show the error on the sign-in screen.
      if (mounted) {
        setState(() {
          _error = e is AuthException ? e.code : 'unknown';
          _step = OnboardingStep.signIn;
        });
      }
    }
  }

  Future<void> _afterVerified(String uid) async {
    _profile ??= await widget.profileStore.load(uid);
    if (_profile == null) {
      _go(OnboardingStep.completeProfile);
      return;
    }
    final existing = await widget.questionnaireStore.load(uid);
    if (existing != null) {
      _finish(existing);
      return;
    }
    _go(OnboardingStep.questionnaire);
  }

  Future<void> _saveProfile(AuthUser user, SignUpData d) async {
    final p = UserProfile(
      uid: user.uid,
      name: d.name,
      email: user.email.isNotEmpty ? user.email : d.email,
      age: d.age,
      createdAt: (widget.clock ?? DateTime.now)(),
    );
    await widget.profileStore.save(p);
    _profile = p;
  }

  Future<void> _onSignUp(SignUpData d) async {
    final user = await _auth.signUp(d.email, d.password);
    await _auth.updateDisplayName(d.name);
    await _saveProfile(user, d);
    await _auth.sendEmailVerification();
    _go(OnboardingStep.verify);
  }

  Future<void> _onCompleteProfile(SignUpData d) async {
    final user = _auth.currentUser;
    if (user == null) {
      _go(OnboardingStep.signUp);
      return;
    }
    await _saveProfile(user, d);
    await _afterVerified(user.uid);
  }

  Future<void> _onSignIn(String email, String password) async {
    _profile = null;
    final user = await _auth.signIn(email, password);
    if (!user.emailVerified) {
      // Their earlier email may be lost/expired: send a fresh one.
      await _auth.sendEmailVerification();
      _go(OnboardingStep.verify);
      return;
    }
    await _afterVerified(user.uid);
  }

  Future<void> _onGoogle() async {
    _profile = null;
    final user = await _auth.signInWithGoogle();
    await _afterVerified(user.uid);
  }

  Future<bool> _onCheckVerified() async {
    final ok = await _auth.reloadAndCheckVerified();
    if (ok) {
      final user = _auth.currentUser;
      if (user != null) await _afterVerified(user.uid);
    }
    return ok;
  }

  Future<void> _onUseDifferentEmail() async {
    await _auth.signOut();
    _profile = null;
    _go(OnboardingStep.signUp);
  }

  Future<void> _onQuestionnaireDone(QuestionnaireResult r) async {
    _go(OnboardingStep.loading);
    await widget.questionnaireStore.save(_profile!.uid, r);
    _finish(r);
  }

  void _finish(QuestionnaireResult r) {
    _go(OnboardingStep.done);
    widget.onDone(_profile!, r);
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case OnboardingStep.done:
        // The host navigates away in onDone; keep a calm, static frame.
        return const OnboardingBackground(child: SizedBox.expand());
      case OnboardingStep.loading:
        return OnboardingBackground(
          child: Center(
            child: CircularProgressIndicator(color: onboardingStyle.boardFrame),
          ),
        );
      case OnboardingStep.welcome:
        return WelcomeScreen(
          key: const ValueKey('step_welcome'),
          onSignIn: () => _go(OnboardingStep.signIn),
          onCreateAccount: () => _go(OnboardingStep.signUp),
        );
      case OnboardingStep.signUp:
        return SignUpScreen(
          key: const ValueKey('step_signup'),
          onSubmit: _onSignUp,
          onGoogle: _onGoogle,
          onSignInInstead: () => _go(OnboardingStep.signIn),
          onBack: () => _go(OnboardingStep.welcome),
        );
      case OnboardingStep.signIn:
        return SignInScreen(
          key: const ValueKey('step_signin'),
          initialErrorCode: _error,
          onGoogle: _onGoogle,
          onForgotPassword: (email) => _auth.sendPasswordReset(email,
              languageCode: AppLocalizations.of(context).language.code),
          onBack: () {
            _error = null;
            _go(OnboardingStep.welcome);
          },
          onSubmit: (e, p) {
            _error = null;
            return _onSignIn(e, p);
          },
          onCreateAccount: () {
            _error = null;
            _go(OnboardingStep.signUp);
          },
        );
      case OnboardingStep.completeProfile:
        return SignUpScreen(
          key: const ValueKey('step_complete_profile'),
          completeProfileEmail: _auth.currentUser?.email ?? '',
          initialName: _auth.currentUser?.displayName,
          onSubmit: _onCompleteProfile,
        );
      case OnboardingStep.verify:
        return VerifyEmailScreen(
          key: const ValueKey('step_verify'),
          email: _auth.currentUser?.email ?? '',
          onCheck: _onCheckVerified,
          onResend: _auth.sendEmailVerification,
          onUseDifferentEmail: _onUseDifferentEmail,
        );
      case OnboardingStep.questionnaire:
        return QuestionnaireScreen(
          key: const ValueKey('step_questionnaire'),
          ageGroup: _profile!.ageGroup,
          onDone: _onQuestionnaireDone,
        );
    }
  }
}
