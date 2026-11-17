import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import 'tile_widget.dart';
import 'visual_style.dart';

/// Widget that displays a player's hand of tiles.
class PlayerHand extends StatelessWidget {
  final Player player;
  final bool isCurrentPlayer;
  final double tileSize;
  final Function(CarpetTile)? onTileTap;

  /// Id of the selected tile (drawn with a red frame).
  final String? selectedTileId;
  final VoidCallback? onRotateLeft;
  final VoidCallback? onRotateRight;

  /// Called when a piece is dragged from the board back onto the tray.
  final void Function(BoardPosition)? onReturnFromBoard;

  const PlayerHand({
    super.key,
    required this.player,
    this.isCurrentPlayer = false,
    this.tileSize = 70,
    this.onTileTap,
    this.selectedTileId,
    this.onRotateLeft,
    this.onRotateRight,
    this.onReturnFromBoard,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Drag a placed piece from the board onto the tray to take it back.
    return DragTarget<MapEntry<CarpetTile, BoardPosition>>(
      onWillAcceptWithDetails: (_) => isCurrentPlayer,
      onAcceptWithDetails: (d) => onReturnFromBoard?.call(d.data.value),
      builder: (context, candidates, _) => _buildBody(
        context,
        l10n,
        hovering: candidates.isNotEmpty,
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n,
      {required bool hovering}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: !VisualStyle.current.isClassic
            ? VisualStyle.current.trayCard
            : isCurrentPlayer
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: hovering
            ? Border.all(color: Colors.green, width: 4)
            : isCurrentPlayer
            ? Border.all(
                color: VisualStyle.current.isClassic
                    ? Theme.of(context).colorScheme.primary
                    : VisualStyle.current.boardFrame.withOpacity(0.5),
                width: 2,
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isCurrentPlayer)
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    player.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight:
                              isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ],
              ),
              Text(
                l10n.tilesCount(player.tileCount),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isCurrentPlayer)
            // Rows of 12 tiles (36 tiles = 3 rows of 12). Tiles shrink so a
            // full row always fits the width.
            LayoutBuilder(builder: (context, constraints) {
              // 12 per row when there is room (landscape), 6 when narrow.
              final int perRow = constraints.maxWidth >= 700 ? 12 : 8;
              const double spacing = 4;
              final fit = (constraints.maxWidth - (perRow - 1) * spacing) / perRow;
              final size = fit < tileSize ? fit : tileSize;
              final hand = player.hand;
              final rows = <Widget>[];
              for (var start = 0; start < hand.length; start += perRow) {
                final end =
                    start + perRow < hand.length ? start + perRow : hand.length;
                if (start > 0) rows.add(const SizedBox(height: spacing));
                rows.add(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = start; i < end; i++) ...[
                      if (i > start) const SizedBox(width: spacing),
                      _buildHandTile(hand[i], size),
                    ],
                  ],
                ));
              }
              return SizedBox(
                width: constraints.maxWidth,
                child: Column(children: rows),
              );
            })
          else
            // Show face-down tiles for other players
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                player.tileCount,
                (index) => Container(
                  width: tileSize * 0.8,
                  height: tileSize * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade500),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.grid_view,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// A tray tile; the selected one gets a red frame and two rotate
  /// buttons drawn inside the piece (left = counter-clockwise, right = clockwise).
  Widget _buildHandTile(CarpetTile tile, double size) {
    final selected = tile.id == selectedTileId;
    final widget = TileWidget(
      tile: tile,
      size: size,
      isSelected: selected,
      isDraggable: true,
      onTap: () => onTileTap?.call(tile),
    );
    return widget;
  }
}
