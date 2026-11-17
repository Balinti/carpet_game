import 'dfi_engine.dart';
import 'ef_models.dart';

/// Outcome of the EF questionnaire.
///
/// [scores] is EF Trainer's normalised DFI per dimension:
/// 0.0 = no friction .. 1.0 = maximal friction.
/// JSON keys match EF Trainer's AssessmentResult (t, a, ans, dfi, pb) so a
/// result can be shared between the two apps.
class QuestionnaireResult {
  final DateTime takenAt;
  final AgeGroup ageGroup;
  final List<AssessmentAnswer> answers;
  final Map<Dimension, double> scores;
  final Dimension primaryBottleneck;

  const QuestionnaireResult({
    required this.takenAt,
    required this.ageGroup,
    required this.answers,
    required this.scores,
    required this.primaryBottleneck,
  });

  /// Scores [answers] exactly like EF Trainer's `DfiEngine.evaluate`.
  factory QuestionnaireResult.evaluate(
    AgeGroup ageGroup,
    List<AssessmentAnswer> answers, {
    DateTime? at,
  }) {
    const engine = DfiEngine();
    final v = engine.vector(answers);
    return QuestionnaireResult(
      takenAt: at ?? DateTime.now(),
      ageGroup: ageGroup,
      answers: List.unmodifiable(answers),
      scores: v,
      primaryBottleneck: engine.primaryBottleneck(v),
    );
  }

  Map<String, dynamic> toJson() => {
        't': takenAt.toIso8601String(),
        'a': ageGroup.name,
        'ans': answers.map((e) => e.toJson()).toList(),
        'dfi': {for (final e in scores.entries) e.key.name: e.value},
        'pb': primaryBottleneck.name,
      };

  factory QuestionnaireResult.fromJson(Map<String, dynamic> j) =>
      QuestionnaireResult(
        takenAt: DateTime.parse(j['t'] as String),
        ageGroup: AgeGroup.values.byName(j['a'] as String),
        answers: (j['ans'] as List)
            .map((e) => AssessmentAnswer.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        scores: {
          for (final e in (j['dfi'] as Map).entries)
            Dimension.values.byName(e.key as String):
                (e.value as num).toDouble(),
        },
        primaryBottleneck: Dimension.values.byName(j['pb'] as String),
      );
}
