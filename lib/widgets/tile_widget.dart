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
  final VoidCallback? onRotateClockwise;
  final VoidCallback? onRotateCounterClockwise;

  const TileWidget({
    super.key,
    required this.tile,
    this.size = 80,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isDraggable = false,
    this.onTap,
    this.onDoubleTap,
    this.onRotateClockwise,
    this.onRotateCounterClockwise,
  });

  void _handleTapDown(TapDownDetails details, BuildContext context) {
    if (!isSelected || (onRotateClockwise == null && onRotateCounterClockwise == null)) {
      onTap?.call();
      return;
    }

    // Determine if tap is on left or right side
    final localX = details.localPosition.dx;
    final threshold = size / 3;

    if (localX < threshold && onRotateCounterClockwise != null) {
      // Left side - rotate counter-clockwise
      onRotateCounterClockwise!();
    } else if (localX > size - threshold && onRotateClockwise != null) {
      // Right side - rotate clockwise
      onRotateClockwise!();
    } else {
      // Center - normal tap
      onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget tileContent = GestureDetector(
      onTapDown: (details) => _handleTapDown(details, context),
      onDoubleTap: onDoubleTap,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: TilePainter(
              tile: tile,
              isSelected: isSelected,
              isHighlighted: isHighlighted,
            ),
          ),
          // Show rotation hints when selected
          if (isSelected && (onRotateClockwise != null || onRotateCounterClockwise != null))
            Positioned.fill(
              child: Row(
                children: [
                  // Left rotation zone
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(
                        Icons.rotate_left,
                        size: size * 0.2,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  // Center spacer
                  const Expanded(child: SizedBox()),
                  // Right rotation zone
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        Icons.rotate_right,
                        size: size * 0.2,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
  final bool hideValidationFeedback;
  final VoidCallback? onTap;

  const EmptyTileSlot({
    super.key,
    this.size = 80,
    this.isValidDrop = false,
    this.showHint = false,
    this.hideValidationFeedback = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    double borderWidth;
    Widget? child;

    // If hiding validation feedback, show neutral styling
    if (hideValidationFeedback) {
      backgroundColor = Colors.grey.withOpacity(0.1);
      borderColor = Colors.grey.shade400;
      borderWidth = 1;
      child = null;
    } else if (isValidDrop) {
      backgroundColor = Colors.green.withOpacity(0.3);
      borderColor = Colors.green;
      borderWidth = 2;
      child = const Icon(Icons.add, color: Colors.green, size: 24);
    } else if (showHint) {
      // Show a gentle hint that this position exists but doesn't match
      backgroundColor = Colors.orange.withOpacity(0.15);
      borderColor = Colors.orange.shade300;
      borderWidth = 1.5;
      child = Icon(Icons.help_outline, color: Colors.orange.shade300, size: 18);
    } else {
      backgroundColor = Colors.grey.withOpacity(0.1);
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
