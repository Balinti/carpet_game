import 'dart:async';

/// The signed-in account, independent of the auth backend.
class AuthUser {
  final String uid;
  final String email;
  final String? displayName;
  final bool emailVerified;

  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.emailVerified = false,
  });
}

/// Auth failure. [code] uses Firebase Auth's error codes so a Firebase
/// implementation can pass `FirebaseAuthException.code` straight through:
/// email-already-in-use, invalid-email, weak-password, user-not-found,
/// wrong-password, invalid-credential, too-many-requests,
/// network-request-failed, no-current-user, unknown.
class AuthException implements Exception {
  final String code;
  final String? message;
  const AuthException(this.code, [this.message]);

  @override
  String toString() =>
      'AuthException($code${message == null ? '' : ': $message'})';
}

/// Email + password auth with email verification.
///
/// See `firebase_auth_service.dart` for the Firebase implementation sketch.
abstract class AuthService {
  /// The signed-in user, or null.
  AuthUser? get currentUser;

  /// Emits the current user (or null) whenever it signs in/out or changes.
  Stream<AuthUser?> authStateChanges();

  /// Creates the account and signs it in. Throws [AuthException].
  Future<AuthUser> signUp(String email, String password);

  /// Sets the display name of the signed-in user.
  Future<void> updateDisplayName(String name);

  /// Sends (or re-sends) the verification email to the signed-in user.
  Future<void> sendEmailVerification();

  /// Refreshes the signed-in user from the backend and returns whether the
  /// email is now verified.
  Future<bool> reloadAndCheckVerified();

  /// Throws [AuthException].
  Future<AuthUser> signIn(String email, String password);

  Future<void> signOut();

  /// Sign in (or create the account) with Google. Google accounts come
  /// with a confirmed email, so no verification step is needed.
  Future<AuthUser> signInWithGoogle();
}

/// In-memory auth so the flow runs before Firebase exists.
///
/// Verification is simulated: call [debugMarkVerified] (tests) or set
/// [autoVerifyOnCheck] (debug builds) so "I confirmed" succeeds.
class FakeAuthService implements AuthService {
  FakeAuthService({this.autoVerifyOnCheck = false});

  /// When true, [reloadAndCheckVerified] marks the user verified.
  bool autoVerifyOnCheck;

  final Map<String, _FakeAccount> _accounts = {};
  final StreamController<AuthUser?> _changes =
      StreamController<AuthUser?>.broadcast();
  _FakeAccount? _current;
  int _nextUid = 1;

  /// How many verification emails were "sent" (for tests).
  int verificationEmailsSent = 0;

  @override
  AuthUser? get currentUser => _current?.toUser();

  @override
  Stream<AuthUser?> authStateChanges() {
    // Like Firebase: each listener first gets the user at subscribe time.
    StreamSubscription<AuthUser?>? sub;
    late final StreamController<AuthUser?> c;
    c = StreamController<AuthUser?>(
      onListen: () {
        c.add(currentUser);
        sub = _changes.stream.listen(c.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return c.stream;
  }

  void _emit() => _changes.add(currentUser);

  @override
  Future<AuthUser> signUp(String email, String password) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthException('email-already-in-use');
    }
    if (password.length < 6) throw const AuthException('weak-password');
    final acc = _FakeAccount('fake-uid-${_nextUid++}', email.trim(), password);
    _accounts[key] = acc;
    _current = acc;
    _emit();
    return acc.toUser();
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    const email = 'google.user@example.com';
    final acc = _accounts.putIfAbsent(
        email, () => _FakeAccount('fake-uid-${_nextUid++}', email, ''));
    acc.verified = true;
    _current = acc;
    _emit();
    return acc.toUser();
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final acc = _current;
    if (acc == null) throw const AuthException('no-current-user');
    acc.displayName = name;
    _emit();
  }

  @override
  Future<void> sendEmailVerification() async {
    if (_current == null) throw const AuthException('no-current-user');
    verificationEmailsSent++;
  }

  @override
  Future<bool> reloadAndCheckVerified() async {
    final acc = _current;
    if (acc == null) throw const AuthException('no-current-user');
    if (autoVerifyOnCheck) acc.verified = true;
    return acc.verified;
  }

  @override
  Future<AuthUser> signIn(String email, String password) async {
    final acc = _accounts[email.trim().toLowerCase()];
    if (acc == null || acc.password != password) {
      throw const AuthException('invalid-credential');
    }
    _current = acc;
    _emit();
    return acc.toUser();
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _emit();
  }

  /// Simulates the user clicking the link in the verification email.
  /// Marks [email] (or the signed-in user) as verified.
  void debugMarkVerified([String? email]) {
    final acc =
        email == null ? _current : _accounts[email.trim().toLowerCase()];
    acc?.verified = true;
  }

  Future<void> dispose() => _changes.close();
}

class _FakeAccount {
  _FakeAccount(this.uid, this.email, this.password);
  final String uid;
  final String email;
  final String password;
  String? displayName;
  bool verified = false;

  AuthUser toUser() => AuthUser(
        uid: uid,
        email: email,
        displayName: displayName,
        emailVerified: verified,
      );
}
