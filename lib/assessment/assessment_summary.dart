import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/visual_style.dart';
import 'assessment_models.dart';
import 'assessment_report.dart';

/// What the player sees at the end (Shemer: the charts were too hard to
/// read): one big card per board with its time and rotations in plain
/// words. The full charts stay one tap away and in the admin dashboard.
class AssessmentSummary extends StatelessWidget {
  final AssessmentResult result;
  const AssessmentSummary({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final st = VisualStyle.current.isClassic
        ? VisualStyle.soft3d
        : VisualStyle.current;
    final he = AppLocalizations.of(context).language == AppLanguage.hebrew;
    String t(String h, String e) => he ? h : e;
    final total = result.rounds.fold<int>(0, (s, r) => s + (r.durationMs ?? 0));

    Widget card(int i, RoundMetrics r) {
      final c = AssessmentReport.roundColor(st, i);
      final min = r.minRotations;
      return Container(
        key: ValueKey('summary_round_$i'),
        width: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: st.trayCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(r.solved ? Icons.check_circle : Icons.timelapse,
                  color: r.solved ? Colors.greenAccent : c, size: 26),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(r.label,
                      style: TextStyle(
                          color: c,
                          fontSize: 24,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(AssessmentReport.formatDuration(r.durationMs),
                  style: TextStyle(
                      color: st.onTray,
                      fontSize: 40,
                      fontWeight: FontWeight.w900)),
            ),
            Text(t('זמן', 'time'),
                style:
                    TextStyle(color: st.onTray.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 10),
            Text(
              min == null
                  ? t('${r.rotations} סיבובים', '${r.rotations} rotations')
                  : t('${r.rotations} סיבובים\n(מספיק היה $min)',
                      '${r.rotations} rotations\n($min would do)'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: st.onTray, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: he ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(t('כל הכבוד! סיימת', 'Well done! All finished'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: st.onTray,
                    fontSize: 28,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
                t('זמן כולל: ${AssessmentReport.formatDuration(total)}',
                    'Total time: ${AssessmentReport.formatDuration(total)}'),
                style:
                    TextStyle(color: st.onTray.withOpacity(0.8), fontSize: 18)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < result.rounds.length; i++)
                  card(i, result.rounds[i]),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              key: const ValueKey('summary_details'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssessmentReportScreen(
                      result: result, title: t('פירוט', 'Details')),
                ),
              ),
              icon: Icon(Icons.bar_chart, color: st.onTray.withOpacity(0.8)),
              label: Text(t('לפירוט המלא', 'Full details'),
                  style: TextStyle(color: st.onTray.withOpacity(0.8))),
            ),
          ],
        ),
      ),
    );
  }
}
