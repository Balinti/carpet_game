import 'package:carpet_game/onboarding/ef/ef_questions.dart';
import 'package:carpet_game/onboarding/onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Picks, per question id, the option with the given score.
List<AssessmentAnswer> answerByScore(
    List<AssessmentQuestion> qs, Map<String, int> scores) {
  return [
    for (final q in qs)
      q.answer(q.options.firstWhere((o) => o.score == scores[q.id])),
  ];
}

void main() {
  group('validation', () {
    test('email format', () {
      expect(validateEmail('a@b.co'), isNull);
      expect(validateEmail('  dana@example.com '), isNull);
      for (final bad in ['', 'dana', 'dana@', '@x.com', 'a@b', 'a b@c.com', 'a@b.c']) {
        expect(validateEmail(bad), FieldError.emailInvalid, reason: bad);
      }
      expect(validateEmail(null), FieldError.emailInvalid);
    });

    test('password at least 6', () {
      expect(validatePassword('12345'), FieldError.passwordTooShort);
      expect(validatePassword(''), FieldError.passwordTooShort);
      expect(validatePassword('123456'), isNull);
    });

    test('age 4..99', () {
      expect(validateAge('3'), FieldError.ageInvalid);
      expect(validateAge('4'), isNull);
      expect(validateAge('99'), isNull);
      expect(validateAge('100'), FieldError.ageInvalid);
      expect(validateAge('abc'), FieldError.ageInvalid);
      expect(validateAge('12.5'), FieldError.ageInvalid);
      expect(validateAge(''), FieldError.ageInvalid);
      expect(parseAge(' 12 '), 12);
    });

    test('name required', () {
      expect(validateName('  '), FieldError.nameRequired);
      expect(validateName('Dana'), isNull);
    });
  });

  group('age group', () {
    test('12 -> kid, 13 -> adult', () {
      expect(ageGroupForAge(12), AgeGroup.kid);
      expect(ageGroupForAge(13), AgeGroup.adult);
      expect(ageGroupForAge(4), AgeGroup.kid);
      expect(ageGroupForAge(99), AgeGroup.adult);
      UserProfile p(int age) => UserProfile(
          uid: 'u', name: 'n', email: 'e@x.com', age: age, createdAt: DateTime(2026));
      expect(p(12).ageGroup, AgeGroup.kid);
      expect(p(13).ageGroup, AgeGroup.adult);
    });

    test('question sets follow the age group', () {
      expect(questionsFor(AgeGroup.kid), hasLength(12));
      expect(questionsFor(AgeGroup.adult), hasLength(12));
      expect(questionsFor(AgeGroup.kid).every((q) => q.ageGroup == AgeGroup.kid), isTrue);
      expect(questionsFor(AgeGroup.adult).every((q) => q.ageGroup == AgeGroup.adult), isTrue);
      for (final group in AgeGroup.values) {
        for (final d in Dimension.values) {
          final qs = questionsFor(group).where((q) => q.dimension == d).toList();
          expect(qs, hasLength(3));
          expect(qs.where((q) => q.isCore), hasLength(1));
        }
        for (final q in questionsFor(group)) {
          expect(q.options.map((o) => o.score).toList(), [1, 2, 3], reason: q.id);
        }
      }
    });
  });

  group('scoring parity with EF Trainer DfiEngine', () {
    // Hand-computed with EF Trainer's formula:
    //   DFI_d = sum((score-1)*w) / sum(2*w), core w=1.5, extra w=1.0
    test('fixed adult answer set', () {
      final answers = answerByScore(adultQuestions, {
        'adult_inh_core': 3, 'adult_inh_2': 1, 'adult_inh_3': 2, // (3+0+1)/7
        'adult_wm_core': 1, 'adult_wm_2': 1, 'adult_wm_3': 1, // 0
        'adult_flex_core': 3, 'adult_flex_2': 3, 'adult_flex_3': 3, // 1
        'adult_init_core': 2, 'adult_init_2': 3, 'adult_init_3': 1, // (1.5+2+0)/7
      });
      final r = QuestionnaireResult.evaluate(AgeGroup.adult, answers,
          at: DateTime.utc(2026, 11, 17));
      expect(r.scores[Dimension.inhibition], closeTo(4 / 7, 1e-12));
      expect(r.scores[Dimension.workingMemory], 0);
      expect(r.scores[Dimension.flexibility], 1);
      expect(r.scores[Dimension.initiation], closeTo(0.5, 1e-12));
      expect(r.primaryBottleneck, Dimension.flexibility);
      // Raw spec formula, also from EF Trainer.
      expect(const DfiEngine().rawDfi(Dimension.inhibition, answers),
          closeTo((4.5 + 1 + 2) / 10.5, 1e-12));
      expect(answers.firstWhere((a) => a.questionId == 'adult_inh_core').weight, 1.5);
      expect(answers.firstWhere((a) => a.questionId == 'adult_inh_2').weight, 1.0);
    });

    test('fixed kid answer set + tie-break by dimension order', () {
      final answers = answerByScore(kidQuestions, {
        for (final q in kidQuestions) q.id: 2,
      });
      final r = QuestionnaireResult.evaluate(AgeGroup.kid, answers);
      for (final d in Dimension.values) {
        expect(r.scores[d], closeTo(0.5, 1e-12));
      }
      expect(r.primaryBottleneck, Dimension.inhibition);
    });
  });

  group('JSON round-trips', () {
    test('QuestionnaireResult', () {
      final answers = answerByScore(kidQuestions, {
        for (var i = 0; i < kidQuestions.length; i++) kidQuestions[i].id: i % 3 + 1,
      });
      final r = QuestionnaireResult.evaluate(AgeGroup.kid, answers,
          at: DateTime.utc(2026, 11, 17, 9, 30));
      final back = QuestionnaireResult.fromJson(r.toJson());
      expect(back.takenAt, r.takenAt);
      expect(back.ageGroup, r.ageGroup);
      expect(back.answers, r.answers);
      expect(back.scores, r.scores);
      expect(back.primaryBottleneck, r.primaryBottleneck);
      // Same keys as EF Trainer's AssessmentResult.
      expect(r.toJson().keys.toSet(), {'t', 'a', 'ans', 'dfi', 'pb'});
    });

    test('UserProfile', () {
      final p = UserProfile(
          uid: 'u1', name: 'Dana', email: 'd@x.com', age: 12,
          createdAt: DateTime.utc(2026, 11, 17));
      final j = p.toJson();
      expect(j['ageGroup'], 'kid');
      expect(UserProfile.fromJson(j), p);
    });

    test('local stores', () async {
      SharedPreferences.setMockInitialValues({});
      const ps = LocalProfileStore();
      const qs = LocalQuestionnaireStore();
      expect(await ps.load('u1'), isNull);
      expect(await qs.load('u1'), isNull);
      final p = UserProfile(
          uid: 'u1', name: 'Dana', email: 'd@x.com', age: 30,
          createdAt: DateTime.utc(2026, 1, 2));
      await ps.save(p);
      expect(await ps.load('u1'), p);
      final r = QuestionnaireResult.evaluate(AgeGroup.adult,
          answerByScore(adultQuestions, {for (final q in adultQuestions) q.id: 3}));
      await qs.save('u1', r);
      final back = await qs.load('u1');
      expect(back!.scores, r.scores);
      expect(back.primaryBottleneck, Dimension.inhibition);
    });
  });

  group('FakeAuthService', () {
    test('sign up, verify, sign out, sign in', () async {
      final auth = FakeAuthService();
      final states = <String?>[];
      final sub = auth.authStateChanges().listen((u) => states.add(u?.email));
      final u = await auth.signUp('Dana@x.com', 'secret1');
      expect(auth.currentUser!.uid, u.uid);
      await auth.sendEmailVerification();
      expect(auth.verificationEmailsSent, 1);
      expect(await auth.reloadAndCheckVerified(), isFalse);
      auth.debugMarkVerified();
      expect(await auth.reloadAndCheckVerified(), isTrue);
      await expectLater(auth.signUp('dana@x.com', 'secret1'),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'email-already-in-use')));
      await auth.signOut();
      expect(auth.currentUser, isNull);
      await expectLater(auth.signIn('dana@x.com', 'nope'),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid-credential')));
      final again = await auth.signIn('dana@x.com', 'secret1');
      expect(again.uid, u.uid);
      expect(again.emailVerified, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(states, [null, 'Dana@x.com', null, 'Dana@x.com']);
      await sub.cancel();
    });
  });
}
