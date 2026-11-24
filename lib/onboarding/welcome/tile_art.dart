import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/carpet_tile.dart';
import '../../models/tile_color.dart';
import '../../widgets/tile_painter.dart';

/// One game piece, drawn by the game's own [TilePainter].
class TileArt extends StatelessWidget {
  const TileArt(this.tile, {super.key, required this.size, this.child});

  /// Same colors on all four sides.
  TileArt.solid(TileColor c, {Key? key, required double size, Widget? child})
      : this(
          CarpetTile(id: 'solid', top: c, right: c, bottom: c, left: c),
          key: key,
          size: size,
          child: child,
        );

  final CarpetTile tile;
  final double size;

  /// Drawn centered on top of the tile (e.g. a number or an icon).
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: TilePainter(tile: tile),
          child: child == null ? null : Center(child: child),
        ),
      );
}

/// A small finished carpet: [rows] x [cols] pieces whose touching edges
/// match, like a solved board. [seed] picks the colors.
///
/// [missing] (row, col) leaves an empty slot; [lifted] draws that missing
/// piece floating next to the board, turned a little, "about to be placed".
class TileMosaic extends StatelessWidget {
  const TileMosaic({
    super.key,
    required this.rows,
    required this.cols,
    required this.tileSize,
    this.gap = 4,
    this.seed = 1,
    this.missing,
    this.slotColor = const Color(0x22FFFFFF),
    this.slotBorder = const Color(0x55FFFFFF),
  });

  final int rows;
  final int cols;
  final double tileSize;
  final double gap;
  final int seed;
  final (int, int)? missing;
  final Color slotColor;
  final Color slotBorder;

  /// Edge colors for a solved board. Every inner edge is shared by two
  /// pieces, so neighbors always match.
  static List<List<CarpetTile>> solved(int rows, int cols, int seed) {
    final rnd = math.Random(seed);
    TileColor pick() => TileColor.values[rnd.nextInt(TileColor.values.length)];
    final h = [
      for (var r = 0; r <= rows; r++) [for (var c = 0; c < cols; c++) pick()]
    ];
    final v = [
      for (var r = 0; r < rows; r++) [for (var c = 0; c <= cols; c++) pick()]
    ];
    return [
      for (var r = 0; r < rows; r++)
        [
          for (var c = 0; c < cols; c++)
            CarpetTile(
              id: 't${r}_$c',
              top: h[r][c],
              bottom: h[r + 1][c],
              left: v[r][c],
              right: v[r][c + 1],
            ),
        ],
    ];
  }

  double get width => cols * tileSize + (cols - 1) * gap;
  double get height => rows * tileSize + (rows - 1) * gap;

  @override
  Widget build(BuildContext context) {
    final tiles = solved(rows, cols, seed);
    return SizedBox(
      width: width,
      height: height,
      child: Directionality(
        // The picture is the same in Hebrew and English.
        textDirection: TextDirection.ltr,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var r = 0; r < rows; r++)
              for (var c = 0; c < cols; c++)
                Positioned(
                  left: c * (tileSize + gap),
                  top: r * (tileSize + gap),
                  child: missing == (r, c)
                      ? Container(
                          width: tileSize,
                          height: tileSize,
                          decoration: BoxDecoration(
                            color: slotColor,
                            borderRadius:
                                BorderRadius.circular(tileSize * 0.14),
                            border: Border.all(color: slotBorder, width: 2),
                          ),
                        )
                      : TileArt(tiles[r][c], size: tileSize),
                ),
            if (missing != null)
              Positioned(
                left: missing!.$2 * (tileSize + gap) + tileSize * 0.55,
                top: missing!.$1 * (tileSize + gap) - tileSize * 0.45,
                child: Transform.rotate(
                  angle: 0.22,
                  child:
                      TileArt(tiles[missing!.$1][missing!.$2], size: tileSize),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A few faint pieces scattered in the corners of a screen (model 2).
class TileConfetti extends StatelessWidget {
  const TileConfetti({super.key, this.opacity = 0.16});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final tiles = TileMosaic.solved(2, 3, 7).expand((r) => r).toList();
    Widget piece(int i, double size, double angle) => Transform.rotate(
          angle: angle,
          child: TileArt(tiles[i % tiles.length], size: size),
        );
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(left: -18, top: -14, child: piece(0, 70, -0.3)),
            Positioned(left: 44, top: 30, child: piece(1, 34, 0.4)),
            Positioned(right: -22, top: 60, child: piece(2, 64, 0.25)),
            Positioned(left: -10, bottom: 40, child: piece(3, 46, 0.5)),
            Positioned(right: 30, bottom: -20, child: piece(4, 80, -0.2)),
            Positioned(right: 110, bottom: 50, child: piece(5, 28, 0.6)),
          ],
        ),
      ),
    );
  }
}
