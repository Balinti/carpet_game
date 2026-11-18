import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/visual_style.dart';
import 'assessment_models.dart';

/// Performance report for one finished assessment: a metrics row per round
/// plus two graphs (time per round, seconds before each piece).
/// Shown to the player at the end and to admins from the dashboard.
class AssessmentReport extends StatelessWidget {
  final AssessmentResult result;

  const AssessmentReport({super.key, required this.result});

  static String formatDuration(int? ms) {
    if (ms == null) return '–';
    final s = ms / 1000;
    if (s < 60) return '${s.toStringAsFixed(1)}s';
    final m = ms ~/ 60000;
    final rest = ((ms % 60000) / 1000).round();
    return '$m:${rest.toString().padLeft(2, '0')}';
  }

  /// Color of round [i] in the graphs.
  static Color roundColor(VisualStyle st, int i) =>
      [st.palette[2], st.palette[3], st.palette[1], st.palette[0]][i % 4];

  @override
  Widget build(BuildContext context) {
    final st = _style();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < result.rounds.length; i++)
          _metricsRow(st, i, result.rounds[i]),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _panel(
                  st,
                  Icons.timer_outlined,
                  CustomPaint(
                    key: const ValueKey('report_round_bars'),
                    painter: _RoundBarsPainter(result.rounds, st),
                    size: Size.infinite,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: _panel(
                  st,
                  Icons.show_chart,
                  CustomPaint(
                    key: const ValueKey('report_piece_line'),
                    painter: _PieceTimesPainter(result.rounds, st),
                    size: Size.infinite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static VisualStyle _style() =>
      VisualStyle.current.isClassic ? VisualStyle.soft3d : VisualStyle.current;

  Widget _panel(VisualStyle st, IconData icon, Widget chart) => Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
        decoration: BoxDecoration(
          color: st.trayCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: st.boardFrame.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: st.onTray.withOpacity(0.8), size: 20),
            const SizedBox(height: 4),
            Expanded(child: chart),
          ],
        ),
      );

  Widget _metricsRow(VisualStyle st, int i, RoundMetrics r) {
    Widget cell(IconData icon, String value) => Expanded(
          child: Row(
            children: [
              Icon(icon, color: st.onTray.withOpacity(0.75), size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: st.onTray,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: st.trayCard,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: roundColor(st, i), width: 6),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              r.label,
              style: TextStyle(
                color: roundColor(st, i),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          cell(Icons.timer_outlined, formatDuration(r.durationMs)),
          cell(Icons.rotate_right, '${r.rotations}'),
          cell(Icons.undo, '${r.backToBuilder}'),
          cell(Icons.help_outline, '${r.helpOpens}'),
        ],
      ),
    );
  }
}

TextPainter _label(String s, Color c, double size) => TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: c, fontSize: size, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

/// One bar per round: seconds to solve.
class _RoundBarsPainter extends CustomPainter {
  final List<RoundMetrics> rounds;
  final VisualStyle st;
  _RoundBarsPainter(this.rounds, this.st);

  @override
  void paint(Canvas canvas, Size size) {
    if (rounds.isEmpty) return;
    const top = 18.0, bottom = 20.0;
    final h = size.height - top - bottom;
    final maxMs = rounds
        .map((r) => r.durationMs ?? 0)
        .fold<int>(1, (a, b) => math.max(a, b));
    final slot = size.width / rounds.length;
    final barW = math.min(slot * 0.6, 56.0);
    for (var i = 0; i < rounds.length; i++) {
      final r = rounds[i];
      final ms = r.durationMs ?? 0;
      final bh = h * ms / maxMs;
      final x = slot * i + (slot - barW) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, top + h - bh, barW, bh),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      );
      canvas.drawRRect(
          rect, Paint()..color = AssessmentReport.roundColor(st, i));
      final v =
          _label(AssessmentReport.formatDuration(r.durationMs), st.onTray, 12);
      v.paint(canvas,
          Offset(x + barW / 2 - v.width / 2, top + h - bh - v.height - 2));
      final l = _label(r.label, st.onTray.withOpacity(0.8), 11);
      l.paint(canvas,
          Offset(slot * i + slot / 2 - l.width / 2, size.height - l.height));
    }
    canvas.drawLine(
      Offset(0, top + h),
      Offset(size.width, top + h),
      Paint()
        ..color = st.onTray.withOpacity(0.3)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _RoundBarsPainter old) => old.rounds != rounds;
}

/// Seconds before each placed piece, all rounds in a row (pace and drift).
class _PieceTimesPainter extends CustomPainter {
  final List<RoundMetrics> rounds;
  final VisualStyle st;
  _PieceTimesPainter(this.rounds, this.st);

  /// Per round: wait before each placement (first one from round start).
  static List<List<int>> gaps(List<RoundMetrics> rounds) => [
        for (final r in rounds)
          [
            if (r.placementTimestampsMs.isNotEmpty)
              r.placementTimestampsMs.first,
            ...r.placementIntervalsMs,
          ],
      ];

  @override
  void paint(Canvas canvas, Size size) {
    final all = gaps(rounds);
    final n = all.fold<int>(0, (s, g) => s + g.length);
    if (n == 0) return;
    const left = 30.0, bottom = 6.0, top = 4.0;
    final w = size.width - left;
    final h = size.height - top - bottom;
    final maxMs =
        all.expand((g) => g).fold<int>(1000, (a, b) => math.max(a, b));
    // Round the axis up to whole seconds.
    final maxS = (maxMs / 1000).ceil().toDouble();
    final grid = Paint()
      ..color = st.onTray.withOpacity(0.12)
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = top + h - h * f;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      final t = _label(
          '${(maxS * f).toStringAsFixed(0)}s', st.onTray.withOpacity(0.6), 10);
      t.paint(canvas, Offset(0, y - t.height / 2));
    }
    final step = n > 1 ? w / (n - 1) : 0.0;
    var k = 0;
    for (var ri = 0; ri < all.length; ri++) {
      final color = AssessmentReport.roundColor(st, ri);
      final g = all[ri];
      if (ri > 0 && g.isNotEmpty) {
        final x = left + step * (k - 0.5);
        canvas.drawLine(
          Offset(x, top),
          Offset(x, top + h),
          Paint()
            ..color = st.onTray.withOpacity(0.25)
            ..strokeWidth = 1,
        );
      }
      final path = Path();
      final pts = <Offset>[];
      for (var j = 0; j < g.length; j++, k++) {
        final p = Offset(
          n > 1 ? left + step * k : left + w / 2,
          top + h - h * (g[j] / 1000) / maxS,
        );
        pts.add(p);
        j == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
      for (final p in pts) {
        canvas.drawCircle(p, 4, Paint()..color = color);
        canvas.drawCircle(
          p,
          4,
          Paint()
            ..color = Colors.white.withOpacity(0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PieceTimesPainter old) => old.rounds != rounds;
}

/// Full-screen report with a back button (admin dashboard).
class AssessmentReportScreen extends StatelessWidget {
  final AssessmentResult result;
  final String? title;
  const AssessmentReportScreen({super.key, required this.result, this.title});

  @override
  Widget build(BuildContext context) {
    final st = AssessmentReport._style();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: st.boardBackground,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: st.onTray),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  if (title != null)
                    Text(
                      title!,
                      style: TextStyle(
                        color: st.onTray,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ]),
                Expanded(child: AssessmentReport(result: result)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
