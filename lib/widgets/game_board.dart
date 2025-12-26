import 'package:flutter/material.dart';
import '../models/models.dart';
import '../game/game_state.dart';
import 'tile_widget.dart';

/// Widget that displays the game board with placed tiles.
class GameBoard extends StatelessWidget {
  final GameState gameState;
  final double tileSize;
  final Function(BoardPosition)? onPositionTap;

  const GameBoard({
    super.key,
    required this.gameState,
    this.tileSize = 70,
    this.onPositionTap,
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
                        child: DragTarget<CarpetTile>(
                          onWillAcceptWithDetails: (details) {
                            return gameState.canPlaceTile(details.data, position);
                          },
                          onAcceptWithDetails: (details) {
                            onPositionTap?.call(position);
                          },
                          builder: (context, candidateData, rejectedData) {
                            final isHovering = candidateData.isNotEmpty;
                            return GestureDetector(
                              onTap: isValidDrop
                                  ? () => onPositionTap?.call(position)
                                  : null,
                              child: EmptyTileSlot(
                                size: tileSize,
                                isValidDrop: isValidDrop || isHovering,
                              ),
                            );
                          },
                        ),
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
}
