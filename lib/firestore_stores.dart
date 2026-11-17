import 'package:cloud_firestore/cloud_firestore.dart';

import 'assessment/assessment.dart';
import 'onboarding/onboarding.dart';

/// Firestore layout (all private to the signed-in user, see firestore.rules):
///   users/{uid}                                profile
///   users/{uid}/questionnaires/latest          EF questionnaire result
///   users/{uid}/assessments/{assessmentId}     assessment metrics
class FirestoreProfileStore implements ProfileStore {
  final FirebaseFirestore db;
  FirestoreProfileStore([FirebaseFirestore? db])
      : db = db ?? FirebaseFirestore.instance;

  @override
  Future<void> save(UserProfile profile) => db
      .collection('users')
      .doc(profile.uid)
      .set(profile.toJson(), SetOptions(merge: true));

  @override
  Future<UserProfile?> load(String uid) async {
    final d = await db.collection('users').doc(uid).get();
    final data = d.data();
    if (data == null || data['age'] == null) return null;
    try {
      return UserProfile.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }
}

class FirestoreQuestionnaireStore implements QuestionnaireStore {
  final FirebaseFirestore db;
  FirestoreQuestionnaireStore([FirebaseFirestore? db])
      : db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => db
      .collection('users')
      .doc(uid)
      .collection('questionnaires')
      .doc('latest');

  @override
  Future<void> save(String uid, QuestionnaireResult result) =>
      _doc(uid).set(result.toJson());

  @override
  Future<QuestionnaireResult?> load(String uid) async {
    final data = (await _doc(uid).get()).data();
    if (data == null) return null;
    try {
      return QuestionnaireResult.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }
}

class FirestoreAssessmentStore implements AssessmentStore {
  final String uid;
  final FirebaseFirestore db;
  FirestoreAssessmentStore(this.uid, [FirebaseFirestore? db])
      : db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      db.collection('users').doc(uid).collection('assessments');

  @override
  Future<void> save(AssessmentResult r) =>
      _col.doc(r.id).set(r.copyWith(userId: uid).toJson());

  @override
  Future<List<AssessmentResult>> all() async {
    final q = await _col.get();
    return [
      for (final d in q.docs)
        AssessmentResult.fromJson(Map<String, dynamic>.from(d.data())),
    ];
  }
}
