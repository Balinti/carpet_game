import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Kid-safe usage events: stored in our own Firestore under the signed-in
/// user (users/{uid}/events), no ad IDs, no third-party analytics.
/// Never throws and never blocks play.
class Telemetry {
  static void log(String type, [Map<String, Object?> data = const {}]) {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('events')
          .add({
        'type': type,
        'at': FieldValue.serverTimestamp(),
        'uid': uid,
        ...data,
      }).then((_) {}, onError: (_) {});
    } catch (_) {}
  }
}
