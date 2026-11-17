import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import 'tile_widget.dart';

/// Widget that displays a player's hand of tiles.
class PlayerHand extends StatelessWidget {
  final Player player;
  final bool isCurrentPlayer;
  final double tileSize;
  final Function(CarpetTile)? onTileTap;

  const PlayerHand({
    super.key,
    required this.player,
    this.isCurrentPlayer = false,
    this.tileSize = 70,
    this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentPlayer
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
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
              const int perRow = 12;
              const double spacing = 8;
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
                      TileWidget(
                        tile: hand[i],
                        size: size,
                        isDraggable: true,
                        onTap: () => onTileTap?.call(hand[i]),
                      ),
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
          if (isCurrentPlayer) ...[
            const SizedBox(height: 8),
            Text(
              l10n.tapRotateDragPlace,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
