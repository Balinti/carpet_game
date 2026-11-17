import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'questionnaire_result.dart';

/// Where questionnaire results live. A Firestore implementation
/// (e.g. `users/{uid}/questionnaires/latest`) can be added later.
abstract class QuestionnaireStore {
  Future<void> save(String uid, QuestionnaireResult result);

  /// Latest saved result for [uid], or null.
  Future<QuestionnaireResult?> load(String uid);
}

/// Device-local store (shared_preferences).
class LocalQuestionnaireStore implements QuestionnaireStore {
  const LocalQuestionnaireStore();

  static String _key(String uid) => 'onboarding.questionnaire.$uid';

  @override
  Future<void> save(String uid, QuestionnaireResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(uid), jsonEncode(result.toJson()));
  }

  @override
  Future<QuestionnaireResult?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null) return null;
    try {
      return QuestionnaireResult.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
