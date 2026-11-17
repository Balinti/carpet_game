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

  /// A tray piece started being dragged / was dropped nowhere.
  final void Function(CarpetTile)? onTileDragStart;
  final void Function(CarpetTile)? onTileDragCancel;

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
    this.onTileDragStart,
    this.onTileDragCancel,
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
    final st = VisualStyle.current;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: st.isClassic
            ? Theme.of(context).colorScheme.primaryContainer
            : st.trayCard,
        borderRadius: BorderRadius.circular(12),
        border: hovering
            ? Border.all(color: Colors.green, width: 4)
            : Border.all(
                color: st.isClassic
                    ? Theme.of(context).colorScheme.primary
                    : st.boardFrame.withOpacity(0.5),
                width: 2,
              ),
      ),
      // All pieces always visible: pick the number per row that gives the
      // biggest piece that still fits both the width and the height.
      child: LayoutBuilder(builder: (context, c) {
        const double spacing = 4;
        final hand = player.hand;
        final n = hand.isEmpty ? 1 : hand.length;
        var bestPerRow = 1;
        var best = 0.0;
        for (var perRow = 1; perRow <= n; perRow++) {
          final rowsNeeded = (n + perRow - 1) ~/ perRow;
          final w = (c.maxWidth - (perRow - 1) * spacing) / perRow;
          final h = (c.maxHeight - (rowsNeeded - 1) * spacing) / rowsNeeded;
          final size = w < h ? w : h;
          if (size > best) {
            best = size;
            bestPerRow = perRow;
          }
        }
        final size = (best < tileSize * 1.6 ? best : tileSize * 1.6)
            .floorToDouble();
        final rows = <Widget>[];
        for (var start = 0; start < hand.length; start += bestPerRow) {
          final end = start + bestPerRow < hand.length
              ? start + bestPerRow
              : hand.length;
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
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        );
      }),
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
      onDragStarted:
          onTileDragStart == null ? null : () => onTileDragStart!(tile),
      onDragCanceled:
          onTileDragCancel == null ? null : () => onTileDragCancel!(tile),
    );
    return widget;
  }
}
