import 'package:carpet_game/onboarding/account_deletion.dart';
import 'package:carpet_game/onboarding/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Log {
  final List<String> calls = [];
}

class _FakeAuth implements AccountAuth {
  _FakeAuth(
    this.log, {
    this.uid = 'u1',
    this.methods = const {SignInMethod.password},
    this.stale = false,
    this.deleteFailsOnce = false,
  });
  final _Log log;
  final String? uid;
  final Set<SignInMethod> methods;
  bool stale;
  bool deleteFailsOnce;
  String? password;

  @override
  String? get currentUid => uid;
  @override
  Set<SignInMethod> get signInMethods => methods;
  @override
  bool get needsRecentLogin => stale;

  @override
  Future<void> reauthenticateWithPassword(String p) async {
    log.calls.add('reauth:password:$p');
    if (p != 'secret') throw const AuthException('wrong-password');
    stale = false;
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    log.calls.add('reauth:google');
    stale = false;
  }

  @override
  Future<void> deleteUser() async {
    log.calls.add('auth:delete');
    if (deleteFailsOnce) {
      deleteFailsOnce = false;
      throw const AuthException('requires-recent-login');
    }
  }

  @override
  Future<void> signOut() async => log.calls.add('auth:signOut');
}

class _FakeData implements UserDataStore {
  _FakeData(this.log);
  final _Log log;
  @override
  Future<void> deleteCollection(String uid, String c) async =>
      log.calls.add('col:$uid/$c');
  @override
  Future<void> deleteUserDoc(String uid) async => log.calls.add('doc:$uid');
}

class _FakeLocal implements LocalDataStore {
  _FakeLocal(this.log);
  final _Log log;
  @override
  Future<void> clear(String uid) async => log.calls.add('local:$uid');
}

AccountDeletionService _service(_Log log, _FakeAuth auth) =>
    AccountDeletionService(
        auth: auth, data: _FakeData(log), local: _FakeLocal(log));

void main() {
  const dataSteps = [
    'col:u1/events',
    'col:u1/assessments',
    'col:u1/questionnaires',
    'doc:u1',
    'local:u1',
  ];

  test('deletes subcollections, user doc, local data, then auth user',
      () async {
    final log = _Log();
    var asked = 0;
    await _service(log, _FakeAuth(log)).deleteAccount(askPassword: () async {
      asked++;
      return 'secret';
    });
    expect(log.calls, [...dataSteps, 'auth:delete', 'auth:signOut']);
    expect(asked, 0);
  });

  test('old sign-in: asks for the password before deleting anything', () async {
    final log = _Log();
    await _service(log, _FakeAuth(log, stale: true))
        .deleteAccount(askPassword: () async => 'secret');
    expect(log.calls, [
      'reauth:password:secret',
      ...dataSteps,
      'auth:delete',
      'auth:signOut',
    ]);
  });

  test('requires-recent-login on delete: reauth and retry', () async {
    final log = _Log();
    await _service(log, _FakeAuth(log, deleteFailsOnce: true))
        .deleteAccount(askPassword: () async => 'secret');
    expect(log.calls, [
      ...dataSteps,
      'auth:delete',
      'reauth:password:secret',
      'auth:delete',
      'auth:signOut',
    ]);
  });

  test('Google account reauthenticates with Google', () async {
    final log = _Log();
    await _service(
      log,
      _FakeAuth(log, methods: const {SignInMethod.google}, stale: true),
    ).deleteAccount(askPassword: () async => fail('no password prompt'));
    expect(log.calls.first, 'reauth:google');
    expect(log.calls, contains('auth:delete'));
  });

  test('cancelled password prompt: nothing is deleted', () async {
    final log = _Log();
    await expectLater(
      _service(log, _FakeAuth(log, stale: true))
          .deleteAccount(askPassword: () async => null),
      throwsA(isA<AuthException>()
          .having((e) => e.code, 'code', 'reauth-cancelled')),
    );
    expect(log.calls, isEmpty);
  });

  test('wrong password: nothing is deleted', () async {
    final log = _Log();
    await expectLater(
      _service(log, _FakeAuth(log, stale: true))
          .deleteAccount(askPassword: () async => 'nope'),
      throwsA(isA<AuthException>()),
    );
    expect(log.calls, ['reauth:password:nope']);
  });

  test('not signed in: throws no-current-user', () async {
    final log = _Log();
    await expectLater(
      _service(log, _FakeAuth(log, uid: null))
          .deleteAccount(askPassword: () async => null),
      throwsA(isA<AuthException>()
          .having((e) => e.code, 'code', 'no-current-user')),
    );
    expect(log.calls, isEmpty);
  });

  test('SharedPrefsLocalDataStore removes app data, keeps other keys',
      () async {
    SharedPreferences.setMockInitialValues({
      'practice_save_3': '{}',
      'assessment_progress_u1': '{}',
      'onboarding.profile.u1': '{}',
      'onboarding.questionnaire.u1': '{}',
      'assessment_results_v1': <String>['x'],
      'carpet_game_progression': '{}',
      'something_else': 'keep',
    });
    await SharedPrefsLocalDataStore().clear('u1');
    final p = await SharedPreferences.getInstance();
    expect(p.getKeys(), {'something_else'});
  });
}
