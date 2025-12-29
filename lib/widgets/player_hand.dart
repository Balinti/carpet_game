import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import 'tile_widget.dart';

/// Widget that displays a player's hand of tiles.
class PlayerHand extends StatelessWidget {
  final Player player;
  final CarpetTile? selectedTile;
  final bool isCurrentPlayer;
  final double tileSize;
  final Function(CarpetTile)? onTileSelected;
  final VoidCallback? onRotate;

  const PlayerHand({
    super.key,
    required this.player,
    this.selectedTile,
    this.isCurrentPlayer = false,
    this.tileSize = 70,
    this.onTileSelected,
    this.onRotate,
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...player.hand.map((tile) {
                  final isSelected = selectedTile?.id == tile.id;
                  return TileWidget(
                    tile: tile,
                    size: tileSize,
                    isSelected: isSelected,
                    isDraggable: true,
                    onTap: () => onTileSelected?.call(tile),
                    onDoubleTap: isSelected ? onRotate : null,
                  );
                }),
              ],
            )
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
          if (isCurrentPlayer && selectedTile != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: onRotate,
                  icon: const Icon(Icons.rotate_right),
                  label: Text(l10n.rotate),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.doubleTapRotate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
