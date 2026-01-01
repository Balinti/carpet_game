import 'dart:math';
import 'tile_color.dart';

/// Represents a carpet tile with 4 triangular sections.
/// Each section is identified by its position: top, right, bottom, left.
///
/// Visual representation:
///       /\
///      /  \
///     / T  \
///    /______\
///   |\      /|
///   | \ L  / |
///   |L \  / R|
///   |   \/   |
///   |   /\   |
///   |  /  \  |
///   | / B  \ |
///   |/______\|
///
class CarpetTile {
  final String id;
  final TileColor top;
  final TileColor right;
  final TileColor bottom;
  final TileColor left;

  const CarpetTile({
    required this.id,
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  /// Returns true if all four sections are the same color (solid tile).
  bool get isSolid => top == right && right == bottom && bottom == left;

  /// Returns the number of unique colors in this tile.
  int get uniqueColorCount => {top, right, bottom, left}.length;

  /// Returns true if 3 or 4 sections are the same color.
  bool get hasThreeOrFourSameColor {
    final colorCounts = <TileColor, int>{};
    for (final color in [top, right, bottom, left]) {
      colorCounts[color] = (colorCounts[color] ?? 0) + 1;
    }
    return colorCounts.values.any((count) => count >= 3);
  }

  /// Get the color of a specific edge.
  /// Edges are: 0=top, 1=right, 2=bottom, 3=left
  TileColor getEdgeColor(int edge) {
    switch (edge % 4) {
      case 0:
        return top;
      case 1:
        return right;
      case 2:
        return bottom;
      case 3:
        return left;
      default:
        return top;
    }
  }

  /// Returns a new tile rotated 90 degrees clockwise.
  CarpetTile rotateClockwise() {
    return CarpetTile(
      id: id,
      top: left,
      right: top,
      bottom: right,
      left: bottom,
    );
  }

  /// Returns a new tile rotated 90 degrees counter-clockwise.
  CarpetTile rotateCounterClockwise() {
    return CarpetTile(
      id: id,
      top: right,
      right: bottom,
      bottom: left,
      left: top,
    );
  }

  /// Creates a copy of this tile with a new ID.
  CarpetTile copyWithId(String newId) {
    return CarpetTile(
      id: newId,
      top: top,
      right: right,
      bottom: bottom,
      left: left,
    );
  }

  @override
  String toString() =>
      'CarpetTile($id: T=$top, R=$right, B=$bottom, L=$left)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarpetTile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom &&
          left == other.left;

  @override
  int get hashCode => Object.hash(id, top, right, bottom, left);

  // Static factory methods for generating different tile types

  static final Random _random = Random();

  /// Generates a random solid-colored tile.
  static CarpetTile generateSolid(String id) {
    final color = TileColor.values[_random.nextInt(TileColor.values.length)];
    return CarpetTile(id: id, top: color, right: color, bottom: color, left: color);
  }

  /// Generates a tile with two colors split diagonally.
  static CarpetTile generateTwoColor(String id) {
    final colors = List<TileColor>.from(TileColor.values)..shuffle(_random);
    final color1 = colors[0];
    final color2 = colors[1];

    // Different two-color patterns
    final patterns = [
      [color1, color2, color1, color2], // Opposite pairs
      [color1, color1, color2, color2], // Adjacent pairs (horizontal split)
      [color1, color2, color2, color1], // Adjacent pairs (vertical split)
    ];

    final pattern = patterns[_random.nextInt(patterns.length)];
    return CarpetTile(
      id: id,
      top: pattern[0],
      right: pattern[1],
      bottom: pattern[2],
      left: pattern[3],
    );
  }

  /// Generates a tile with three triangles of one color and one of another.
  static CarpetTile generateThreeColor(String id) {
    final colors = List<TileColor>.from(TileColor.values)..shuffle(_random);
    final mainColor = colors[0];
    final accentColor = colors[1];

    // One section is different
    final position = _random.nextInt(4);
    final sections = List.filled(4, mainColor);
    sections[position] = accentColor;

    return CarpetTile(
      id: id,
      top: sections[0],
      right: sections[1],
      bottom: sections[2],
      left: sections[3],
    );
  }

  /// Generates a tile with all four sections different colors.
  static CarpetTile generateFourColor(String id) {
    final colors = List<TileColor>.from(TileColor.values)..shuffle(_random);
    return CarpetTile(
      id: id,
      top: colors[0],
      right: colors[1],
      bottom: colors[2],
      left: colors[3],
    );
  }

  /// Generates a random tile of any type.
  static CarpetTile generateRandom(String id) {
    final type = _random.nextInt(10);
    if (type < 2) {
      return generateSolid(id); // 20% chance
    } else if (type < 5) {
      return generateTwoColor(id); // 30% chance
    } else if (type < 8) {
      return generateThreeColor(id); // 30% chance
    } else {
      return generateFourColor(id); // 20% chance
    }
  }

  /// Returns the canonical form of this tile (smallest rotation).
  /// Used to identify unique tiles regardless of rotation.
  String get canonicalKey {
    final rotations = [
      '${top.index}${right.index}${bottom.index}${left.index}',
      '${left.index}${top.index}${right.index}${bottom.index}',
      '${bottom.index}${left.index}${top.index}${right.index}',
      '${right.index}${bottom.index}${left.index}${top.index}',
    ];
    rotations.sort();
    return rotations.first;
  }

  /// Returns a unique key representing the current rotation state.
  String get rotationKey => '${top.index}${right.index}${bottom.index}${left.index}';

  /// The 36 specific build tiles (codes: top-right-bottom-left).
  /// Colors: r=red, g=green, b=blue, y=yellow
  static const List<String> buildTileCodes = [
    'yybr', 'ybbr', 'rbgy', 'gybr', 'byry', 'rbyg',
    'rrby', 'bbbb', 'bbrb', 'yyry', 'yyyy', 'yggb',
    'brby', 'rgbb', 'gygb', 'gbby', 'byyy', 'ygyr',
    'yggy', 'ggbr', 'bgry', 'rggb', 'grgy', 'grbr',
    'bbgg', 'yggg', 'gggg', 'yrgy', 'rrrr', 'rybr',
    'gyyb', 'yrgg', 'grbg', 'brgy', 'gryr', 'ybry',
  ];

  /// Creates a tile from a 4-character code (top-right-bottom-left).
  /// Colors: r=red, g=green, b=blue, y=yellow
  static CarpetTile fromCode(String id, String code) {
    TileColor charToColor(String c) {
      switch (c) {
        case 'r': return TileColor.red;
        case 'g': return TileColor.green;
        case 'b': return TileColor.blue;
        case 'y': return TileColor.yellow;
        default: return TileColor.red;
      }
    }
    return CarpetTile(
      id: id,
      top: charToColor(code[0]),
      right: charToColor(code[1]),
      bottom: charToColor(code[2]),
      left: charToColor(code[3]),
    );
  }

  /// Returns the 36 specific build tiles, shuffled.
  static List<CarpetTile> getBuildTiles() {
    final tiles = <CarpetTile>[];
    for (int i = 0; i < buildTileCodes.length; i++) {
      tiles.add(fromCode('build_$i', buildTileCodes[i]));
    }
    tiles.shuffle(_random);
    return tiles;
  }

  /// Returns a random tile from the 36 build tiles.
  static CarpetTile getRandomBuildTile(String id) {
    final code = buildTileCodes[_random.nextInt(buildTileCodes.length)];
    return fromCode(id, code);
  }

  /// Generates all 64 unique tiles (one representative per rotation equivalence class).
  /// With 4 colors and 4 positions, there are 256 combinations.
  /// Removing rotational duplicates gives us ~70 unique tiles, but we take 64.
  static List<CarpetTile> generateAllUniqueTiles() {
    final uniqueTiles = <String, CarpetTile>{};
    final colors = TileColor.values;
    var id = 0;

    // Generate all 256 combinations
    for (final top in colors) {
      for (final right in colors) {
        for (final bottom in colors) {
          for (final left in colors) {
            final tile = CarpetTile(
              id: 'tile_$id',
              top: top,
              right: right,
              bottom: bottom,
              left: left,
            );

            // Only keep one tile per rotation equivalence class
            final key = tile.canonicalKey;
            if (!uniqueTiles.containsKey(key)) {
              uniqueTiles[key] = tile;
              id++;
            }
          }
        }
      }
    }

    // Shuffle and return all unique tiles
    final tiles = uniqueTiles.values.toList();
    tiles.shuffle(_random);
    return tiles;
  }
}
