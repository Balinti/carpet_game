import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'assessment_models.dart';

/// Where finished assessments are kept. A Firestore implementation can be
/// added later next to [LocalAssessmentStore].
abstract class AssessmentStore {
  Future<void> save(AssessmentResult r);
  Future<List<AssessmentResult>> all();
}

/// Stores results on the device as a list of JSON strings.
class LocalAssessmentStore implements AssessmentStore {
  static const String prefsKey = 'assessment_results_v1';

  final Future<SharedPreferences> Function() _prefs;

  LocalAssessmentStore({Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance;

  @override
  Future<void> save(AssessmentResult r) async {
    final p = await _prefs();
    final list = List<String>.from(p.getStringList(prefsKey) ?? const []);
    // Same id saved again replaces the earlier copy.
    list.removeWhere((s) {
      try {
        return (jsonDecode(s) as Map)['id'] == r.id;
      } catch (_) {
        return false;
      }
    });
    list.add(jsonEncode(r.toJson()));
    await p.setStringList(prefsKey, list);
  }

  @override
  Future<List<AssessmentResult>> all() async {
    final p = await _prefs();
    final out = <AssessmentResult>[];
    for (final s in p.getStringList(prefsKey) ?? const <String>[]) {
      try {
        out.add(AssessmentResult.fromJson(
            Map<String, dynamic>.from(jsonDecode(s) as Map)));
      } catch (_) {
        // Skip corrupt entries.
      }
    }
    return out;
  }
}
