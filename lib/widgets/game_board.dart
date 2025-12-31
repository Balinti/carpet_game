import 'package:flutter/material.dart';
import '../models/models.dart';
import '../game/game_state.dart';
import 'tile_widget.dart';
import 'tile_painter.dart';

/// Widget that displays the game board with placed tiles.
class GameBoard extends StatelessWidget {
  final GameState gameState;
  final double tileSize;
  final Function(BoardPosition)? onPositionTap;
  final Function(BoardPosition)? onTileRotate;
  final Function(BoardPosition, BoardPosition)? onTileSwap;
  final Function(CarpetTile, BoardPosition)? onTileReplace;
  final bool showMatchFeedback;

  const GameBoard({
    super.key,
    required this.gameState,
    this.tileSize = 70,
    this.onPositionTap,
    this.onTileRotate,
    this.onTileSwap,
    this.onTileReplace,
    this.showMatchFeedback = false,
  });

  @override
  Widget build(BuildContext context) {
    // For square modes with fixed grid, show only the target grid
    final gridSize = gameState.targetGridSize;
    if (gridSize > 0) {
      return _buildFixedGrid(context, gridSize);
    }

    // Calculate visible board area with padding
    final minRow = gameState.minRow - 1;
    final maxRow = gameState.maxRow + 1;
    final minCol = gameState.minCol - 1;
    final maxCol = gameState.maxCol + 1;

    final rowCount = maxRow - minRow + 1;
    final colCount = maxCol - minCol + 1;

    // Ensure minimum board size
    final displayRows = rowCount < 5 ? 5 : rowCount;
    final displayCols = colCount < 5 ? 5 : colCount;

    final rowOffset = rowCount < 5 ? (5 - rowCount) ~/ 2 : 0;
    final colOffset = colCount < 5 ? (5 - colCount) ~/ 2 : 0;

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(displayRows, (displayRow) {
                final row = minRow + displayRow - rowOffset;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(displayCols, (displayCol) {
                    final col = minCol + displayCol - colOffset;
                    final position = BoardPosition(row, col);
                    final tile = gameState.board[position];
                    final isValidDrop = gameState.validPositions.contains(position);
                    final isAdjacent = gameState.allAdjacentPositions.contains(position);

                    if (tile != null) {
                      return Padding(
                        padding: const EdgeInsets.all(1),
                        child: TileWidget(
                          tile: tile,
                          size: tileSize,
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.all(1),
                        child: _buildDropTarget(context, position, isValidDrop, isAdjacent),
                      );
                    }
                  }),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedGrid(BuildContext context, int gridSize) {
    // Calculate tile size to fit the grid nicely on screen
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final availableSize = (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.7;
    final calculatedTileSize = (availableSize / gridSize).clamp(60.0, 100.0);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(gridSize, (row) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(gridSize, (col) {
                  final position = BoardPosition(row, col);
                  final tile = gameState.board[position];

                  if (tile != null) {
                    // Show placed tile - tap to rotate, drag to swap
                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: _buildPlacedTile(context, tile, position, calculatedTileSize),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: _buildFixedGridSlot(context, position, calculatedTileSize),
                    );
                  }
                }),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Build a placed tile that can be rotated (tap), swapped (drag from board), or replaced (drag from hand)
  Widget _buildPlacedTile(BuildContext context, CarpetTile tile, BoardPosition position, double slotSize) {
    // Outer DragTarget for tiles from hand (replacement)
    return DragTarget<CarpetTile>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        // Replace: hand tile goes to board, board tile goes to hand
        onTileReplace?.call(details.data, position);
      },
      builder: (context, handCandidateData, handRejectedData) {
        final isHandHovering = handCandidateData.isNotEmpty;

        // Inner DragTarget for tiles from board (swap)
        return DragTarget<MapEntry<CarpetTile, BoardPosition>>(
          onWillAcceptWithDetails: (details) => details.data.value != position,
          onAcceptWithDetails: (details) {
            // Swap tiles between positions
            onTileSwap?.call(details.data.value, position);
          },
          builder: (context, boardCandidateData, boardRejectedData) {
            final isBoardHovering = boardCandidateData.isNotEmpty;
            final isHovering = isHandHovering || isBoardHovering;

            return Draggable<MapEntry<CarpetTile, BoardPosition>>(
              data: MapEntry(tile, position),
              feedback: Material(
                color: Colors.transparent,
                elevation: 8,
                child: Opacity(
                  opacity: 0.8,
                  child: CustomPaint(
                    size: Size(slotSize, slotSize),
                    painter: TilePainter(tile: tile),
                  ),
                ),
              ),
              childWhenDragging: Container(
                width: slotSize,
                height: slotSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: GestureDetector(
                onTap: () => onTileRotate?.call(position),
                child: Container(
                  decoration: isHovering
                      ? BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                        )
                      : null,
                  child: CustomPaint(
                    size: Size(slotSize, slotSize),
                    painter: TilePainter(tile: tile),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFixedGridSlot(BuildContext context, BoardPosition position, double slotSize) {
    return DragTarget<MapEntry<CarpetTile, BoardPosition>>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        // Move tile from old position to this empty position
        onTileSwap?.call(details.data.value, position);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: gameState.selectedTile != null ? () => onPositionTap?.call(position) : null,
          child: DragTarget<CarpetTile>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              onPositionTap?.call(position);
            },
            builder: (context, candidateData2, rejectedData2) {
              final isHovering2 = candidateData2.isNotEmpty || isHovering;
              return Container(
                width: slotSize,
                height: slotSize,
                decoration: BoxDecoration(
                  color: isHovering2
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: gameState.selectedTile != null || isHovering2
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: gameState.selectedTile != null || isHovering2 ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: gameState.selectedTile != null
                    ? Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                        size: slotSize * 0.4,
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDropTarget(
    BuildContext context,
    BoardPosition position,
    bool isValidDrop,
    bool isAdjacent,
  ) {
    return DragTarget<CarpetTile>(
      onWillAcceptWithDetails: (details) {
        return gameState.canPlaceTile(details.data, position);
      },
      onAcceptWithDetails: (details) {
        onPositionTap?.call(position);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final showPreview = isHovering && showMatchFeedback && candidateData.first != null;

        if (showPreview) {
          // Show preview with edge match feedback
          final tile = candidateData.first!;
          final edgeStatus = gameState.getEdgeMatchStatus(tile, position);

          return GestureDetector(
            onTap: isValidDrop ? () => onPositionTap?.call(position) : null,
            child: Opacity(
              opacity: 0.7,
              child: CustomPaint(
                size: Size(tileSize, tileSize),
                painter: TilePainter(
                  tile: tile,
                  edgeStatus: edgeStatus,
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: isValidDrop ? () => onPositionTap?.call(position) : null,
          child: EmptyTileSlot(
            size: tileSize,
            isValidDrop: isValidDrop || isHovering,
            showHint: isAdjacent && !isValidDrop && gameState.selectedTile != null,
          ),
        );
      },
    );
  }
}
