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
  final VoidCallback? onTap;

  const EmptyTileSlot({
    super.key,
    this.size = 80,
    this.isValidDrop = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isValidDrop
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          border: Border.all(
            color: isValidDrop ? Colors.green : Colors.grey.shade400,
            width: isValidDrop ? 2 : 1,
            style: BorderStyle.solid,
          ),
        ),
        child: isValidDrop
            ? const Icon(Icons.add, color: Colors.green, size: 24)
            : null,
      ),
    );
  }
}
