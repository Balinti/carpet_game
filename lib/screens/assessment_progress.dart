import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../assessment/assessment.dart';

/// An unfinished assessment kept on this device, so a player who stops
/// (e.g. stuck on the 6×6) continues there instead of starting over.
class AssessmentProgress {
  final List<int> rounds;
  final List<RoundMetrics> completed;
  final int round;

  /// The round in progress and its board (null = start it fresh).
  final RoundMetrics? partial;
  final int elapsedMs;
  final Map<String, dynamic>? board;

  AssessmentProgress({
    required this.rounds,
    required this.completed,
    required this.round,
    this.partial,
    this.elapsedMs = 0,
    this.board,
  });

  static String _key(String? uid) => 'assessment_progress_${uid ?? 'local'}';

  Map<String, dynamic> toJson() => {
        'rounds': rounds,
        'completed': completed.map((r) => r.toJson()).toList(),
        'round': round,
        'partial': partial?.toJson(),
        'elapsedMs': elapsedMs,
        'board': board,
      };

  static AssessmentProgress? fromJson(Map<String, dynamic> j) {
    try {
      return AssessmentProgress(
        rounds: (j['rounds'] as List).map((e) => (e as num).toInt()).toList(),
        completed: (j['completed'] as List)
            .map((r) =>
                RoundMetrics.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
        round: (j['round'] as num).toInt(),
        partial: j['partial'] == null
            ? null
            : RoundMetrics.fromJson(
                Map<String, dynamic>.from(j['partial'] as Map)),
        elapsedMs: (j['elapsedMs'] as num?)?.toInt() ?? 0,
        board: j['board'] == null
            ? null
            : Map<String, dynamic>.from(j['board'] as Map),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<AssessmentProgress?> load(String? uid) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key(uid));
      if (raw == null) return null;
      return fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String? uid) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key(uid), jsonEncode(toJson()));
    } catch (_) {}
  }

  static Future<void> clear(String? uid) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_key(uid));
    } catch (_) {}
  }
}
