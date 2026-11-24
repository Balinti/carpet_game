import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_service.dart';

/// How the signed-in account can prove who it is again.
enum SignInMethod { password, google }

/// The auth operations account deletion needs. Firebase version:
/// `account_deletion_firebase.dart`; tests use fakes.
abstract class AccountAuth {
  /// The signed-in user's uid, or null.
  String? get currentUid;

  /// Sign-in methods linked to the signed-in account.
  Set<SignInMethod> get signInMethods;

  /// True when the last sign-in is too old for deleting the account
  /// (Firebase then fails with `requires-recent-login`).
  bool get needsRecentLogin;

  /// Throws [AuthException] (e.g. wrong-password / invalid-credential).
  Future<void> reauthenticateWithPassword(String password);

  /// Throws [AuthException] (e.g. popup-closed-by-user).
  Future<void> reauthenticateWithGoogle();

  /// Deletes the auth account. Throws [AuthException]
  /// (`requires-recent-login` when the sign-in is too old).
  Future<void> deleteUser();

  Future<void> signOut();
}

/// The user's documents on the server.
abstract class UserDataStore {
  /// Deletes every document in `users/{uid}/{collection}`.
  Future<void> deleteCollection(String uid, String collection);

  /// Deletes `users/{uid}`.
  Future<void> deleteUserDoc(String uid);
}

/// Data saved on this device.
abstract class LocalDataStore {
  Future<void> clear(String uid);
}

/// Asks the user for their password again. Returns null when they cancel.
typedef PasswordPrompt = Future<String?> Function();

/// Deletes the account and everything stored for it:
/// subcollections → `users/{uid}` → local data → auth account → sign out.
///
/// Errors are [AuthException]s; `reauth-cancelled` when the user closes the
/// password prompt.
class AccountDeletionService {
  AccountDeletionService({
    required this.auth,
    required this.data,
    required this.local,
  });

  final AccountAuth auth;
  final UserDataStore data;
  final LocalDataStore local;

  /// Every subcollection under `users/{uid}` the app writes
  /// (telemetry.dart, firestore_stores.dart).
  static const subcollections = ['events', 'assessments', 'questionnaires'];

  Future<void> deleteAccount({required PasswordPrompt askPassword}) async {
    final uid = auth.currentUid;
    if (uid == null) throw const AuthException('no-current-user');

    // Re-auth first when the sign-in is old, so data is not deleted while
    // the auth account then can't be.
    if (auth.needsRecentLogin) await _reauthenticate(askPassword);

    for (final c in subcollections) {
      await data.deleteCollection(uid, c);
    }
    await data.deleteUserDoc(uid);
    await local.clear(uid);

    try {
      await auth.deleteUser();
    } on AuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      await _reauthenticate(askPassword);
      await auth.deleteUser();
    }

    try {
      await auth.signOut();
    } catch (_) {
      // Deleting the auth user already signs out.
    }
  }

  Future<void> _reauthenticate(PasswordPrompt askPassword) async {
    final methods = auth.signInMethods;
    if (methods.contains(SignInMethod.password)) {
      final password = await askPassword();
      if (password == null || password.isEmpty) {
        throw const AuthException('reauth-cancelled');
      }
      await auth.reauthenticateWithPassword(password);
    } else if (methods.contains(SignInMethod.google)) {
      await auth.reauthenticateWithGoogle();
    } else {
      throw const AuthException('requires-recent-login');
    }
  }
}

/// Removes the app's SharedPreferences data (not the language choice).
class SharedPrefsLocalDataStore implements LocalDataStore {
  static const prefixes = [
    'practice_save_', // lib/game/practice_save.dart
    'assessment_progress_', // lib/screens/assessment_progress.dart
    'onboarding.profile.', // lib/onboarding/profile/profile_store.dart
    'onboarding.questionnaire.', // lib/onboarding/ef/questionnaire_store.dart
  ];
  static const keys = [
    'assessment_results_v1', // lib/assessment/assessment_store.dart
    'carpet_game_progression', // lib/models/progression.dart
  ];

  @override
  Future<void> clear(String uid) async {
    final p = await SharedPreferences.getInstance();
    for (final k in p.getKeys().toList()) {
      if (keys.contains(k) || prefixes.any(k.startsWith)) await p.remove(k);
    }
  }
}
