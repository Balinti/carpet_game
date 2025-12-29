import 'package:flutter/material.dart';
import '../models/carpet_tile.dart';
import 'tile_painter.dart';

/// Widget that displays a single carpet tile.
class TileWidget extends StatelessWidget {
  final CarpetTile tile;
  final double size;
  final bool isSelected;
  final bool isHighlighted;
  final bool isDraggable;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const TileWidget({
    super.key,
    required this.tile,
    this.size = 80,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isDraggable = false,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget tileContent = GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: CustomPaint(
        size: Size(size, size),
        painter: TilePainter(
          tile: tile,
          isSelected: isSelected,
          isHighlighted: isHighlighted,
        ),
      ),
    );

    if (isDraggable) {
      return Draggable<CarpetTile>(
        data: tile,
        feedback: Material(
          color: Colors.transparent,
          elevation: 8,
          child: Opacity(
            opacity: 0.8,
            child: CustomPaint(
              size: Size(size, size),
              painter: TilePainter(
                tile: tile,
                isSelected: true,
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: tileContent,
        ),
        child: tileContent,
      );
    }

    return tileContent;
  }
}

/// Widget for an empty tile slot on the board.
class EmptyTileSlot extends StatelessWidget {
  final double size;
  final bool isValidDrop;
  final bool showHint;
  final VoidCallback? onTap;

  const EmptyTileSlot({
    super.key,
    this.size = 80,
    this.isValidDrop = false,
    this.showHint = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    double borderWidth;
    Widget? child;

    if (isValidDrop) {
      backgroundColor = const Color.fromRGBO(76, 175, 80, 0.3); // Green with 0.3 opacity
      borderColor = Colors.green;
      borderWidth = 2;
      child = const Icon(Icons.add, color: Colors.green, size: 24);
    } else if (showHint) {
      // Show a gentle hint that this position exists but doesn't match
      backgroundColor = const Color.fromRGBO(255, 152, 0, 0.15); // Orange with 0.15 opacity
      borderColor = Colors.orange.shade300;
      borderWidth = 1.5;
      child = Icon(Icons.help_outline, color: Colors.orange.shade300, size: 18);
    } else {
      backgroundColor = const Color.fromRGBO(158, 158, 158, 0.1); // Grey with 0.1 opacity
      borderColor = Colors.grey.shade400;
      borderWidth = 1;
      child = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
            style: BorderStyle.solid,
          ),
        ),
        child: child,
      ),
    );
  }
}
