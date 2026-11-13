import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/carpet_tile.dart';
import '../models/score_system.dart';

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
    final center = Offset(size.width / 2, size.height / 2);
    final topLeft = Offset.zero;
    final topRight = Offset(size.width, 0);
    final bottomLeft = Offset(0, size.height);
    final bottomRight = Offset(size.width, size.height);

    // Draw the four triangular sections with soft shading for a woven look
    _drawTriangle(canvas, [topLeft, topRight, center], tile.top.toColor());
    _drawTriangle(canvas, [topRight, bottomRight, center], tile.right.toColor());
    _drawTriangle(canvas, [bottomRight, bottomLeft, center], tile.bottom.toColor());
    _drawTriangle(canvas, [bottomLeft, topLeft, center], tile.left.toColor());

    // Decorative center diamond ornament to give a carpet-like motif
    _drawCenterDiamond(canvas, size, center);

    // Draw edge match feedback if provided
    if (edgeStatus != null) {
      _drawEdgeFeedback(canvas, size, edgeStatus!);
    }

    // Draw outer border
    final outerBorderPaint = Paint()
      ..color = isSelected ? Colors.white : Colors.black87
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
        ..color = Colors.white
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        selectionPaint,
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

    // Shade from a lighter outer edge toward a slightly darker center,
    // giving each section a subtle plush, hand-woven appearance.
    final hsl = HSLColor.fromColor(color);
    final lighter = hsl
        .withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0))
        .toColor();
    final darker = hsl
        .withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0))
        .toColor();

    final outerMid = Offset(
      (points[0].dx + points[1].dx) / 2,
      (points[0].dy + points[1].dy) / 2,
    );

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        outerMid,
        points[2], // center of the tile
        [lighter, darker],
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  /// Draws a small diamond motif in the center of the tile.
  void _drawCenterDiamond(Canvas canvas, Size size, Offset center) {
    final r = size.shortestSide * 0.16;
    final diamond = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();

    canvas.drawPath(
      diamond,
      Paint()
        ..color = Colors.white.withOpacity(0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      diamond,
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant TilePainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isHighlighted != isHighlighted ||
        oldDelegate.edgeStatus != edgeStatus;
  }
}
