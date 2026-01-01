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
  final Function(CarpetTile, BoardPosition)? onTileDrop;
  final bool showMatchFeedback;

  const GameBoard({
    super.key,
    required this.gameState,
    this.tileSize = 70,
    this.onPositionTap,
    this.onTileDrop,
    this.showMatchFeedback = false,
  });

  @override
  Widget build(BuildContext context) {
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
        onTileDrop?.call(details.data, position);
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
