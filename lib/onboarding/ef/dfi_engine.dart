// DFI = Dimension Friction Index. Ported verbatim from EF Trainer
// (ef-trainer/lib/core/dfi_engine.dart) so scores match across both apps.
//
//   DFI_D = Sum(Score_i * Weight_i) / MaxPossibleScore_D
//   PrimaryBottleneck = ArgMax(DFI vector)
//
// Scores are 1..3, so raw DFI lives in [1/3, 1]. We rescale to [0, 1] so that
// "all answers = 1 (optimal)" reads as 0 friction and "all = 3" reads as 1.0.
import 'ef_models.dart';

class DfiEngine {
  const DfiEngine();

  static const int minScore = 1;
  static const int maxScore = 3;

  /// Raw spec formula, in [1/3, 1]. Returns null for a dimension with no answers.
  double? rawDfi(Dimension d, List<AssessmentAnswer> answers) {
    final items = answers.where((a) => a.dimension == d).toList();
    if (items.isEmpty) return null;
    final sum = items.fold<double>(0, (acc, a) => acc + a.score * a.weight);
    final max = items.fold<double>(0, (acc, a) => acc + maxScore * a.weight);
    return sum / max;
  }

  /// Rescaled DFI in [0, 1]. 0 = no friction, 1 = maximal friction.
  double normalisedDfi(Dimension d, List<AssessmentAnswer> answers) {
    final items = answers.where((a) => a.dimension == d).toList();
    if (items.isEmpty) return 0;
    final sum = items.fold<double>(
      0,
      (acc, a) => acc + (a.score - minScore) * a.weight,
    );
    final max = items.fold<double>(
      0,
      (acc, a) => acc + (maxScore - minScore) * a.weight,
    );
    return max == 0 ? 0 : sum / max;
  }

  Map<Dimension, double> vector(List<AssessmentAnswer> answers) => {
        for (final d in Dimension.values) d: normalisedDfi(d, answers),
      };

  /// ArgMax. Ties are broken by the fixed order of [Dimension.values].
  Dimension primaryBottleneck(Map<Dimension, double> v) {
    var best = Dimension.values.first;
    for (final d in Dimension.values) {
      if ((v[d] ?? 0) > (v[best] ?? 0)) best = d;
    }
    return best;
  }
}
