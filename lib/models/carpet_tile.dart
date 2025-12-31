import 'dart:math';
import 'tile_color.dart';

/// The 36 specific build tiles for the game.
/// Format: each 4-letter code represents top, right, bottom, left colors
/// Colors: y=yellow, b=blue, r=red, g=green
const List<String> kBuildTileCodes = [
  // Row 1
  'yybr', 'ybbr', 'rbgy', 'gybr', 'byry', 'rbyg',
  // Row 2
  'rrby', 'bbbb', 'bbrb', 'yyry', 'yyyy', 'yggb',
  // Row 3
  'brby', 'rgbb', 'gygb', 'gbby', 'byyy', 'ygyr',
  // Row 4
  'yggy', 'ggbr', 'bgry', 'rggb', 'grgy', 'grbr',
  // Row 5
  'bbgg', 'yggg', 'gggg', 'yrgy', 'rrrr', 'rybr',
  // Row 6
  'gyyb', 'yrgg', 'grbg', 'brgy', 'gryr', 'ybry',
];

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
          id == other.id;

  @override
  int get hashCode => id.hashCode;

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

  /// Parse a color character to TileColor.
  static TileColor _parseColor(String char) {
    switch (char.toLowerCase()) {
      case 'r':
        return TileColor.red;
      case 'g':
        return TileColor.green;
      case 'b':
        return TileColor.blue;
      case 'y':
        return TileColor.yellow;
      default:
        throw ArgumentError('Invalid color character: $char');
    }
  }

  /// Creates a tile from a 4-character code.
  /// Code format: TRBL (top, right, bottom, left)
  /// Colors: y=yellow, b=blue, r=red, g=green
  static CarpetTile fromCode(String id, String code) {
    if (code.length != 4) {
      throw ArgumentError('Tile code must be exactly 4 characters: $code');
    }
    return CarpetTile(
      id: id,
      top: _parseColor(code[0]),
      right: _parseColor(code[1]),
      bottom: _parseColor(code[2]),
      left: _parseColor(code[3]),
    );
  }

  /// Get all 36 build tiles as CarpetTile objects.
  static List<CarpetTile> getBuildTiles() {
    return List.generate(
      kBuildTileCodes.length,
      (i) => fromCode('build_tile_$i', kBuildTileCodes[i]),
    );
  }

  /// Get a random tile from the 36 build tiles.
  static CarpetTile getRandomBuildTile(String id) {
    final code = kBuildTileCodes[_random.nextInt(kBuildTileCodes.length)];
    return fromCode(id, code);
  }
}
