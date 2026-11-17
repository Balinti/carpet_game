// EF domain types, ported from EF Trainer (ef-trainer/lib/core/models.dart).
// Kept wire-compatible: AssessmentAnswer JSON uses the same keys (q, d, s, w).
import '../../l10n/app_localizations.dart';

/// The four executive-function axes.
enum Dimension { inhibition, workingMemory, flexibility, initiation }

/// kid = under 13, adult = 13 and up.
enum AgeGroup { kid, adult }

/// Age cut-off: under this age the kid question set is used.
const int kAdultMinAge = 13;

AgeGroup ageGroupForAge(int age) =>
    age < kAdultMinAge ? AgeGroup.kid : AgeGroup.adult;

extension DimensionLabels on Dimension {
  String get hebrewName => switch (this) {
        Dimension.inhibition => 'עיכוב תגובה',
        Dimension.workingMemory => 'זיכרון עבודה',
        Dimension.flexibility => 'גמישות מחשבתית',
        Dimension.initiation => 'התנעה ותכנון',
      };

  String get englishName => switch (this) {
        Dimension.inhibition => 'Inhibition',
        Dimension.workingMemory => 'Working Memory',
        Dimension.flexibility => 'Cognitive Flexibility',
        Dimension.initiation => 'Task Initiation',
      };

  String get spanishName => switch (this) {
        Dimension.inhibition => 'Inhibición',
        Dimension.workingMemory => 'Memoria de trabajo',
        Dimension.flexibility => 'Flexibilidad cognitiva',
        Dimension.initiation => 'Inicio de tareas',
      };

  String labelIn(AppLanguage lang) => switch (lang) {
        AppLanguage.hebrew => hebrewName,
        AppLanguage.spanish => spanishName,
        AppLanguage.english => englishName,
      };
}

/// One answer to one item. [score] is 1 (optimal) .. 3 (high friction).
class AssessmentAnswer {
  final String questionId;
  final Dimension dimension;
  final int score;
  final double weight;

  const AssessmentAnswer({
    required this.questionId,
    required this.dimension,
    required this.score,
    this.weight = 1.0,
  }) : assert(score >= 1 && score <= 3);

  Map<String, dynamic> toJson() => {
        'q': questionId,
        'd': dimension.name,
        's': score,
        'w': weight,
      };

  factory AssessmentAnswer.fromJson(Map<String, dynamic> j) => AssessmentAnswer(
        questionId: j['q'] as String,
        dimension: Dimension.values.byName(j['d'] as String),
        score: j['s'] as int,
        weight: (j['w'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      other is AssessmentAnswer &&
      other.questionId == questionId &&
      other.dimension == dimension &&
      other.score == score &&
      other.weight == weight;

  @override
  int get hashCode => Object.hash(questionId, dimension, score, weight);
}
