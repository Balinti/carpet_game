// Firebase implementation of [AuthService] — live (Firebase project carpet-game-ubotika).
//
// It stays commented out until the Firebase project exists and the
// integrator adds `firebase_core` + `firebase_auth` to pubspec.yaml and runs
// `flutterfire configure` (which creates lib/firebase_options.dart).
// Then: uncomment everything below, and in main():
//
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   ... OnboardingFlow(auth: FirebaseAuthService(), ...)
//
// Error codes: FirebaseAuthException.code is passed straight through as
// AuthException.code, and the onboarding screens already map those codes
// to localized messages.

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth})
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  static AuthUser? _map(fb.User? u) => u == null
      ? null
      : AuthUser(
          uid: u.uid,
          email: u.email ?? '',
          displayName: u.displayName,
          emailVerified: u.emailVerified,
        );

  Future<T> _wrap<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  fb.User _requireUser() {
    final u = _auth.currentUser;
    if (u == null) throw const AuthException('no-current-user');
    return u;
  }

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  // userChanges() (not authStateChanges()) also fires on reload/profile edits.
  @override
  Stream<AuthUser?> authStateChanges() => _auth.userChanges().map(_map);

  @override
  Future<AuthUser> signUp(String email, String password) => _wrap(() async {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return _map(cred.user)!;
      });

  @override
  Future<void> updateDisplayName(String name) =>
      _wrap(() => _requireUser().updateDisplayName(name));

  @override
  Future<void> sendEmailVerification() =>
      _wrap(() => _requireUser().sendEmailVerification());

  @override
  Future<bool> reloadAndCheckVerified() => _wrap(() async {
        await _requireUser().reload();
        return _auth.currentUser?.emailVerified ?? false;
      });

  @override
  Future<AuthUser> signIn(String email, String password) => _wrap(() async {
        final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return _map(cred.user)!;
      });

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email, {String? languageCode}) =>
      _wrap(() async {
        if (languageCode != null) await _auth.setLanguageCode(languageCode);
        await _auth.sendPasswordResetEmail(email: email.trim());
      });

  @override
  Future<AuthUser> signInWithGoogle() => _wrap(() async {
        final provider = fb.GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        final cred = kIsWeb
            ? await _auth.signInWithPopup(provider)
            : await _auth.signInWithProvider(provider);
        return _map(cred.user)!;
      });
}
