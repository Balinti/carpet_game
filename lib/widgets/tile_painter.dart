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

    // Draw the four triangular sections
    _drawTriangle(canvas, [topLeft, topRight, center], tile.top.toColor());
    _drawTriangle(canvas, [topRight, bottomRight, center], tile.right.toColor());
    _drawTriangle(canvas, [bottomRight, bottomLeft, center], tile.bottom.toColor());
    _drawTriangle(canvas, [bottomLeft, topLeft, center], tile.left.toColor());

    // Draw borders between sections
    final borderPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(topLeft, bottomRight, borderPaint);
    canvas.drawLine(topRight, bottomLeft, borderPaint);

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
        ..color = const Color.fromRGBO(255, 255, 255, 0.3) // White with 0.3 opacity
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

    // Helper to draw edge line
    void drawEdge(int edgeIndex, Offset start, Offset end) {
      final edgeStatus = status[edgeIndex];
      if (edgeStatus != null && edgeStatus != EdgeMatchStatus.noAdjacent) {
        final paint = Paint()
          ..color = edgeStatus.borderColor
          ..strokeWidth = edgeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(start, end, paint);
      }
    }

    // Top edge (0)
    drawEdge(0, Offset(edgeWidth / 2, edgeWidth / 2), Offset(size.width - edgeWidth / 2, edgeWidth / 2));

    // Right edge (1)
    drawEdge(1, Offset(size.width - edgeWidth / 2, edgeWidth / 2), Offset(size.width - edgeWidth / 2, size.height - edgeWidth / 2));

    // Bottom edge (2)
    drawEdge(2, Offset(edgeWidth / 2, size.height - edgeWidth / 2), Offset(size.width - edgeWidth / 2, size.height - edgeWidth / 2));

    // Left edge (3)
    drawEdge(3, Offset(edgeWidth / 2, edgeWidth / 2), Offset(edgeWidth / 2, size.height - edgeWidth / 2));
  }

  void _drawTriangle(Canvas canvas, List<Offset> points, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..close();

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
