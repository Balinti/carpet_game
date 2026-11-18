import 'package:carpet_game/l10n/app_localizations.dart';
import 'package:carpet_game/onboarding/ef/ef_questions.dart';
import 'package:carpet_game/onboarding/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemProfiles implements ProfileStore {
  final Map<String, UserProfile> data = {};
  @override
  Future<UserProfile?> load(String uid) async => data[uid];
  @override
  Future<void> save(UserProfile p) async => data[p.uid] = p;
}

class _MemResults implements QuestionnaireStore {
  final Map<String, QuestionnaireResult> data = {};
  @override
  Future<QuestionnaireResult?> load(String uid) async => data[uid];
  @override
  Future<void> save(String uid, QuestionnaireResult r) async => data[uid] = r;
}

Widget _app(Widget home, {AppLanguage lang = AppLanguage.english}) =>
    MaterialApp(
      locale: lang.locale,
      supportedLocales: AppLanguage.values.map((l) => l.locale),
      localizationsDelegates: [
        AppLocalizationsDelegate(lang),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

/// Short, wide landscape phone.
void _landscapePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(780, 300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final f = find.byKey(key);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, Key key, String text) async {
  final f = find.byKey(key);
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('walks sign up -> verify -> kid questionnaire -> onDone',
      (tester) async {
    _landscapePhone(tester);
    final auth = FakeAuthService();
    final profiles = _MemProfiles();
    final results = _MemResults();
    UserProfile? doneProfile;
    QuestionnaireResult? doneResult;
    var doneCalls = 0;

    await tester.pumpWidget(_app(OnboardingFlow(
      auth: auth,
      profileStore: profiles,
      questionnaireStore: results,
      clock: () => DateTime.utc(2026, 11, 17),
      onDone: (p, r) {
        doneCalls++;
        doneProfile = p;
        doneResult = r;
      },
    )));
    await tester.pumpAndSettle();
    await _tap(tester, const ValueKey('welcome_create'));
    expect(find.text('Create your account'), findsOneWidget);

    // Empty submit shows inline validation errors.
    await _tap(tester, const ValueKey('signup_submit'));
    expect(find.text('Please enter a name'), findsOneWidget);
    expect(find.text('Please enter a valid email'), findsOneWidget);
    expect(find.text('At least 6 characters'), findsOneWidget);
    expect(find.text('Age 4 to 99'), findsOneWidget);
    expect(auth.currentUser, isNull);

    await _enter(tester, const ValueKey('signup_name'), 'Dana');
    await _enter(tester, const ValueKey('signup_age'), '12');
    await _enter(tester, const ValueKey('signup_email'), 'dana@example.com');
    await _enter(tester, const ValueKey('signup_password'), 'secret1');
    await _tap(tester, const ValueKey('signup_submit'));

    // Verify screen.
    expect(find.byKey(const ValueKey('step_verify')), findsOneWidget);
    expect(find.textContaining('dana@example.com'), findsOneWidget);
    expect(auth.verificationEmailsSent, 1);
    expect(profiles.data.values.single.ageGroup, AgeGroup.kid);
    expect(auth.currentUser!.displayName, 'Dana');

    await _tap(tester, const ValueKey('verify_confirmed'));
    expect(
        find.textContaining("can't see the confirmation yet"), findsOneWidget);

    await _tap(tester, const ValueKey('verify_resend'));
    expect(auth.verificationEmailsSent, 2);
    expect(find.textContaining('Sent again'), findsOneWidget);

    auth.debugMarkVerified();
    await _tap(tester, const ValueKey('verify_confirmed'));

    // Kid intro with parent help.
    expect(find.byKey(const ValueKey('step_questionnaire')), findsOneWidget);
    expect(find.text(kidIntroEn), findsOneWidget);
    await _tap(tester, const ValueKey('q_start'));

    // Back button returns to the previous question.
    final first = kidQuestions.first;
    await _tap(tester, ValueKey('opt_${first.id}_2'));
    expect(find.byKey(ValueKey('q_${kidQuestions[1].id}')), findsOneWidget);
    await _tap(tester, const ValueKey('q_back'));
    expect(find.byKey(ValueKey('q_${first.id}')), findsOneWidget);
    expect(find.text('Question 1 of 6'), findsOneWidget);

    // Answer all with option 0 except the inhibition item ("always", score 3).
    for (final q in kidQuestions) {
      expect(find.byKey(ValueKey('q_${q.id}')), findsOneWidget);
      final opt = q.id == 'kid_3' ? 2 : 0;
      await _tap(tester, ValueKey('opt_${q.id}_$opt'));
    }

    expect(doneCalls, 1);
    expect(doneProfile!.name, 'Dana');
    expect(doneProfile!.age, 12);
    expect(doneProfile!.ageGroup, AgeGroup.kid);
    expect(doneProfile!.createdAt, DateTime.utc(2026, 11, 17));
    expect(doneResult!.ageGroup, AgeGroup.kid);
    expect(doneResult!.answers, hasLength(6));
    expect(doneResult!.scores[Dimension.inhibition], closeTo(1, 1e-12));
    expect(doneResult!.scores[Dimension.workingMemory], 0);
    expect(doneResult!.primaryBottleneck, Dimension.inhibition);
    expect(results.data[doneProfile!.uid], same(doneResult));
  });

  testWidgets('13-year-old gets adult questions (Hebrew, RTL, no overflow)',
      (tester) async {
    _landscapePhone(tester);
    final auth = FakeAuthService(autoVerifyOnCheck: true);
    QuestionnaireResult? result;
    await tester.pumpWidget(_app(
      OnboardingFlow(
        auth: auth,
        profileStore: _MemProfiles(),
        questionnaireStore: _MemResults(),
        onDone: (_, r) => result = r,
      ),
      lang: AppLanguage.hebrew,
    ));
    await tester.pumpAndSettle();
    await _tap(tester, const ValueKey('welcome_create'));
    await _enter(tester, const ValueKey('signup_name'), 'נועה');
    await _enter(tester, const ValueKey('signup_age'), '13');
    await _enter(tester, const ValueKey('signup_email'), 'noa@example.com');
    await _enter(tester, const ValueKey('signup_password'), 'secret1');
    await _tap(tester, const ValueKey('signup_submit'));
    await _tap(tester, const ValueKey('verify_confirmed'));
    expect(find.text(adultIntro), findsOneWidget);
    await _tap(tester, const ValueKey('q_start'));
    for (final q in adultQuestions) {
      expect(find.text(q.text), findsOneWidget);
      await _tap(tester, ValueKey('opt_${q.id}_1'));
    }
    expect(result!.ageGroup, AgeGroup.adult);
    expect(result!.answers.map((a) => a.questionId),
        adultQuestions.map((q) => q.id));
  });

  testWidgets('sign in instead: wrong password, then profile completion',
      (tester) async {
    _landscapePhone(tester);
    final auth = FakeAuthService();
    await auth.signUp('old@example.com', 'secret1');
    auth.debugMarkVerified();
    await auth.signOut();
    final profiles = _MemProfiles();
    await tester.pumpWidget(_app(OnboardingFlow(
      auth: auth,
      profileStore: profiles,
      questionnaireStore: _MemResults(),
      onDone: (_, __) {},
    )));
    await tester.pumpAndSettle();
    await _tap(tester, const ValueKey('welcome_signin'));
    expect(find.text('Welcome back'), findsOneWidget);
    await _enter(tester, const ValueKey('signin_email'), 'old@example.com');
    await _enter(tester, const ValueKey('signin_password'), 'wrong!!');
    await _tap(tester, const ValueKey('signin_submit'));
    expect(find.text('Wrong email or password'), findsOneWidget);
    await _enter(tester, const ValueKey('signin_password'), 'secret1');
    await _tap(tester, const ValueKey('signin_submit'));
    // Verified account, but no profile on this device.
    expect(find.byKey(const ValueKey('step_complete_profile')), findsOneWidget);
    expect(find.byKey(const ValueKey('signup_email')), findsNothing);
    await _enter(tester, const ValueKey('signup_name'), 'Old');
    await _enter(tester, const ValueKey('signup_age'), '40');
    await _tap(tester, const ValueKey('signup_submit'));
    expect(find.byKey(const ValueKey('step_questionnaire')), findsOneWidget);
    expect(find.text(adultIntroEn), findsOneWidget);
    expect(profiles.data.values.single.email, 'old@example.com');
  });

  testWidgets('already-registered email shows inline error', (tester) async {
    _landscapePhone(tester);
    final auth = FakeAuthService();
    await auth.signUp('taken@example.com', 'secret1');
    await auth.signOut();
    await tester.pumpWidget(_app(OnboardingFlow(
      auth: auth,
      profileStore: _MemProfiles(),
      questionnaireStore: _MemResults(),
      onDone: (_, __) {},
    )));
    await tester.pumpAndSettle();
    await _tap(tester, const ValueKey('welcome_create'));
    await _enter(tester, const ValueKey('signup_name'), 'X');
    await _enter(tester, const ValueKey('signup_age'), '30');
    await _enter(tester, const ValueKey('signup_email'), 'taken@example.com');
    await _enter(tester, const ValueKey('signup_password'), 'secret1');
    await _tap(tester, const ValueKey('signup_submit'));
    expect(find.textContaining('already has an account'), findsOneWidget);
    expect(find.byKey(const ValueKey('step_signup')), findsOneWidget);
  });

  testWidgets('resumes: signed-in user with profile + result -> onDone',
      (tester) async {
    final auth = FakeAuthService();
    final u = await auth.signUp('r@example.com', 'secret1');
    auth.debugMarkVerified();
    final profiles = _MemProfiles();
    final results = _MemResults();
    final p = UserProfile(
        uid: u.uid,
        name: 'R',
        email: u.email,
        age: 8,
        createdAt: DateTime(2026));
    await profiles.save(p);
    final r = QuestionnaireResult.evaluate(AgeGroup.kid, const []);
    await results.save(u.uid, r);
    UserProfile? got;
    await tester.pumpWidget(_app(OnboardingFlow(
      auth: auth,
      profileStore: profiles,
      questionnaireStore: results,
      onDone: (pp, _) => got = pp,
    )));
    await tester.pumpAndSettle();
    expect(got, p);
  });
}
