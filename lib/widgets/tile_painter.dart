import 'package:flutter/material.dart';
import '../models/carpet_tile.dart';
import '../models/score_system.dart';
import '../models/tile_color.dart';
import 'visual_style.dart';

/// Custom painter that draws a carpet tile with 4 triangular sections.
class TilePainter extends CustomPainter {
  final CarpetTile tile;
  final bool isSelected;
  final bool isHighlighted;
  final Map<int, EdgeMatchStatus>? edgeStatus;

  TilePainter({
    required this.tile,
    this.isSelected = false,
    this.isHighlighted = false,
    this.edgeStatus,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final style = VisualStyle.current;
    if (!style.isClassic) {
      _paintStyled(canvas, size, style);
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final topLeft = Offset.zero;
    final topRight = Offset(size.width, 0);
    final bottomLeft = Offset(0, size.height);
    final bottomRight = Offset(size.width, size.height);

    // Draw the four triangular sections
    _drawTriangle(canvas, [topLeft, topRight, center], tile.top.toColor());
    _drawTriangle(canvas, [topRight, bottomRight, center], tile.right.toColor());
    _drawTriangle(canvas, [bottomRight, bottomLeft, center], tile.bottom.toColor());
    _drawTriangle(canvas, [bottomLeft, topLeft, center], tile.left.toColor());

    // Draw edge match feedback if provided
    if (edgeStatus != null) {
      _drawEdgeFeedback(canvas, size, edgeStatus!);
    }

    // Draw outer border
    final outerBorderPaint = Paint()
      ..color = isSelected ? Colors.red : Colors.black87
      ..strokeWidth = isSelected ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      outerBorderPaint,
    );

    // Draw highlight if needed
    if (isHighlighted) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        highlightPaint,
      );
    }

    // Draw selection indicator
    if (isSelected) {
      final selectionPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        selectionPaint,
      );
    }
  }

  Color _c(VisualStyle st, TileColor c) => st.palette[c.index];

  /// Modern looks: rounded piece, shaded triangles, depth and gloss.
  void _paintStyled(Canvas canvas, Size size, VisualStyle st) {
    final w = size.width, h = size.height;
    final inset = w * 0.04;
    final rect = Rect.fromLTWH(inset, inset, w - 2 * inset, h - 2 * inset);
    final radius = Radius.circular(w * (st.id == 3 ? 0.18 : 0.12));
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final c = rect.center;
    final tl = rect.topLeft, tr = rect.topRight;
    final bl = rect.bottomLeft, br = rect.bottomRight;

    // Depth: drop shadow (neon: colored glow instead).
    if (st.id == 2) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = (isSelected ? Colors.red : _c(st, tile.top)).withOpacity(0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.08),
      );
    } else {
      canvas.drawRRect(
        rrect.shift(Offset(0, w * (st.id == 3 ? 0.06 : 0.05))),
        Paint()
          ..color = Colors.black.withOpacity(st.id == 3 ? 0.18 : 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05),
      );
    }

    canvas.save();
    canvas.clipRRect(rrect);

    final sides = [
      ([tl, tr, c], tile.top, Offset(c.dx, rect.top)),
      ([tr, br, c], tile.right, Offset(rect.right, c.dy)),
      ([br, bl, c], tile.bottom, Offset(c.dx, rect.bottom)),
      ([bl, tl, c], tile.left, Offset(rect.left, c.dy)),
    ];
    for (final (pts, color, edgeMid) in sides) {
      final base = _c(st, color);
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy)
        ..close();
      final List<Color> colors;
      switch (st.id) {
        case 2: // neon: deep at the center, bright at the edge
          colors = [base, Color.lerp(base, Colors.black, 0.4)!];
        case 3: // clay: soft, nearly flat
          colors = [Color.lerp(base, Colors.white, 0.12)!, base];
        default: // soft 3D: light edge, richer center
          // Very light shading so colors stay true.
          colors = [Color.lerp(base, Colors.white, 0.06)!,
              Color.lerp(base, Colors.black, 0.06)!];
      }
      canvas.drawPath(
        path,
        Paint()..shader = LinearGradient(colors: colors)
            .createShader(Rect.fromPoints(edgeMid, c)),
      );
    }

    // Seams between the four triangles.
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * (st.id == 3 ? 0.035 : 0.015)
      ..color = switch (st.id) {
        2 => Colors.white.withOpacity(0.55),
        3 => Colors.white.withOpacity(0.85),
        _ => Colors.black.withOpacity(0.25),
      };
    canvas.drawLine(tl, br, seam);
    canvas.drawLine(tr, bl, seam);

    // Gloss on the upper half (soft 3D and neon).
    if (st.id != 3) {
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.5),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(st.id == 2 ? 0.18 : 0.10),
              Colors.white.withOpacity(0),
            ],
          ).createShader(rect),
      );
    }
    canvas.restore();

    // Bevel / rim.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;
    if (st.id == 2) {
      rim.color = Colors.white.withOpacity(0.7);
      canvas.drawRRect(rrect.deflate(w * 0.01), rim);
    } else {
      rim.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(st.id == 3 ? 0.9 : 0.55),
          Colors.black.withOpacity(st.id == 3 ? 0.10 : 0.35),
        ],
      ).createShader(rect);
      canvas.drawRRect(rrect.deflate(w * 0.012), rim);
    }

    if (isHighlighted) {
      canvas.drawRRect(rrect, Paint()..color = Colors.white.withOpacity(0.3));
    }
    if (isSelected) {
      canvas.drawRRect(
        rrect.inflate(w * 0.015),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.07
          ..color = Colors.red,
      );
    }
  }

  void _drawEdgeFeedback(Canvas canvas, Size size, Map<int, EdgeMatchStatus> status) {
    const edgeWidth = 6.0;

    // Top edge (0)
    if (status[0] != EdgeMatchStatus.noAdjacent) {
      final paint = Paint()
        ..color = status[0]!.borderColor
        ..strokeWidth = edgeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(edgeWidth / 2, edgeWidth / 2),
        Offset(size.width - edgeWidth / 2, edgeWidth / 2),
        paint,
      );
    }

    // Right edge (1)
    if (status[1] != EdgeMatchStatus.noAdjacent) {
      final paint = Paint()
        ..color = status[1]!.borderColor
        ..strokeWidth = edgeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(size.width - edgeWidth / 2, edgeWidth / 2),
        Offset(size.width - edgeWidth / 2, size.height - edgeWidth / 2),
        paint,
      );
    }

    // Bottom edge (2)
    if (status[2] != EdgeMatchStatus.noAdjacent) {
      final paint = Paint()
        ..color = status[2]!.borderColor
        ..strokeWidth = edgeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(edgeWidth / 2, size.height - edgeWidth / 2),
        Offset(size.width - edgeWidth / 2, size.height - edgeWidth / 2),
        paint,
      );
    }

    // Left edge (3)
    if (status[3] != EdgeMatchStatus.noAdjacent) {
      final paint = Paint()
        ..color = status[3]!.borderColor
        ..strokeWidth = edgeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(edgeWidth / 2, edgeWidth / 2),
        Offset(edgeWidth / 2, size.height - edgeWidth / 2),
        paint,
      );
    }
  }

  void _drawTriangle(Canvas canvas, List<Offset> points, Color color) {
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TilePainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isHighlighted != isHighlighted ||
        oldDelegate.edgeStatus != edgeStatus;
  }
}
