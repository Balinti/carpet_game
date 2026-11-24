import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'account_deletion.dart';
import 'auth/auth_service.dart';

/// [AccountDeletionService] wired to Firebase.
AccountDeletionService firebaseAccountDeletion() => AccountDeletionService(
      auth: FirebaseAccountAuth(),
      data: FirestoreUserDataStore(),
      local: SharedPrefsLocalDataStore(),
    );

class FirebaseAccountAuth implements AccountAuth {
  FirebaseAccountAuth({fb.FirebaseAuth? auth})
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  /// Firebase asks for a fresh sign-in for deletes after about 5 minutes.
  static const recentLogin = Duration(minutes: 5);

  fb.User _user() {
    final u = _auth.currentUser;
    if (u == null) throw const AuthException('no-current-user');
    return u;
  }

  Future<T> _wrap<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Set<SignInMethod> get signInMethods {
    final u = _auth.currentUser;
    if (u == null) return const {};
    return {
      for (final p in u.providerData)
        if (p.providerId == fb.EmailAuthProvider.PROVIDER_ID)
          SignInMethod.password
        else if (p.providerId == fb.GoogleAuthProvider.PROVIDER_ID)
          SignInMethod.google,
    };
  }

  @override
  bool get needsRecentLogin {
    final t = _auth.currentUser?.metadata.lastSignInTime;
    if (t == null) return true;
    return DateTime.now().difference(t) > recentLogin;
  }

  @override
  Future<void> reauthenticateWithPassword(String password) => _wrap(() async {
        final u = _user();
        final email = u.email;
        if (email == null) throw const AuthException('no-current-user');
        await u.reauthenticateWithCredential(
          fb.EmailAuthProvider.credential(email: email, password: password),
        );
      });

  @override
  Future<void> reauthenticateWithGoogle() => _wrap(() async {
        final u = _user();
        final provider = fb.GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        if (kIsWeb) {
          await u.reauthenticateWithPopup(provider);
        } else {
          await u.reauthenticateWithProvider(provider);
        }
      });

  @override
  Future<void> deleteUser() => _wrap(() => _user().delete());

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Batched deletes under `users/{uid}` (allowed for the owner by
/// firestore.rules).
class FirestoreUserDataStore implements UserDataStore {
  FirestoreUserDataStore([FirebaseFirestore? db])
      : db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore db;

  /// Below Firestore's 500 writes per batch.
  static const batchSize = 400;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      db.collection('users').doc(uid);

  @override
  Future<void> deleteCollection(String uid, String collection) async {
    final col = _user(uid).collection(collection);
    while (true) {
      final snap = await col.limit(batchSize).get();
      if (snap.docs.isEmpty) return;
      final batch = db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  @override
  Future<void> deleteUserDoc(String uid) => _user(uid).delete();
}
