import '../models/models.dart';

/// Represents a detected geometric shape on the board.
class DetectedShape {
  final GeometricShapeType type;
  final Set<BoardPosition> positions;
  final String description;

  const DetectedShape({
    required this.type,
    required this.positions,
    required this.description,
  });

  @override
  String toString() => '$type at ${positions.first}';
}

/// Types of geometric shapes that can be detected.
enum GeometricShapeType {
  smallDiamond,
  largeDiamond,
  smallTriangle,
  largeTriangle,
  smallRectangle,
  largeRectangle,
  arrow;

  String get displayName {
    switch (this) {
      case GeometricShapeType.smallDiamond:
        return 'Small Diamond';
      case GeometricShapeType.largeDiamond:
        return 'Large Diamond';
      case GeometricShapeType.smallTriangle:
        return 'Small Triangle';
      case GeometricShapeType.largeTriangle:
        return 'Large Triangle';
      case GeometricShapeType.smallRectangle:
        return 'Small Rectangle';
      case GeometricShapeType.largeRectangle:
        return 'Large Rectangle';
      case GeometricShapeType.arrow:
        return 'Arrow';
    }
  }

  String get description {
    switch (this) {
      case GeometricShapeType.smallDiamond:
        return '2 tiles with matching colors forming a diamond at the seam';
      case GeometricShapeType.largeDiamond:
        return '4 tiles (2x2) with matching colors forming a large diamond';
      case GeometricShapeType.smallTriangle:
        return '1 tile where one color forms a small triangle (1/4 of tile)';
      case GeometricShapeType.largeTriangle:
        return '3 tiles in L-shape with matching colors forming a triangle';
      case GeometricShapeType.smallRectangle:
        return '2 tiles with matching colors forming a rectangle stripe';
      case GeometricShapeType.largeRectangle:
        return '3-4 tiles in a line with matching colors forming a long rectangle';
      case GeometricShapeType.arrow:
        return '3-5 tiles forming an arrow shape pointing in a direction';
    }
  }

  int get minTiles {
    switch (this) {
      case GeometricShapeType.smallDiamond:
        return 2;
      case GeometricShapeType.largeDiamond:
        return 4;
      case GeometricShapeType.smallTriangle:
        return 1;
      case GeometricShapeType.largeTriangle:
        return 3;
      case GeometricShapeType.smallRectangle:
        return 2;
      case GeometricShapeType.largeRectangle:
        return 3;
      case GeometricShapeType.arrow:
        return 3;
    }
  }
}

/// Detects geometric shapes formed by matching edge colors across tiles.
class ShapeDetector {
  /// Detect all shapes on the board.
  static List<DetectedShape> detectAllShapes(Map<BoardPosition, CarpetTile> board) {
    final shapes = <DetectedShape>[];

    // Detect each shape type
    shapes.addAll(detectSmallDiamonds(board));
    shapes.addAll(detectLargeDiamonds(board));
    shapes.addAll(detectSmallTriangles(board));
    shapes.addAll(detectLargeTriangles(board));
    shapes.addAll(detectSmallRectangles(board));
    shapes.addAll(detectLargeRectangles(board));
    shapes.addAll(detectArrows(board));

    return shapes;
  }

  /// Detect small diamonds (2 tiles, horizontal or vertical).
  /// A small diamond is formed when 2 adjacent tiles have matching colors
  /// at their shared edge, creating a diamond shape at the seam.
  static List<DetectedShape> detectSmallDiamonds(Map<BoardPosition, CarpetTile> board) {
    final shapes = <DetectedShape>[];
    final checked = <String>{};

    for (final entry in board.entries) {
      final pos = entry.key;
      final tile = entry.value;

      // Check horizontal pair (right neighbor)
      final rightPos = pos.right;
      if (board.containsKey(rightPos)) {
        final key = '${pos.row},${pos.col}-${rightPos.row},${rightPos.col}';
        if (!checked.contains(key)) {
          checked.add(key);
          final rightTile = board[rightPos]!;
          // Diamond forms when right edge of left tile matches left edge of right tile
          if (tile.right == rightTile.left) {
            shapes.add(DetectedShape(
              type: GeometricShapeType.smallDiamond,
              positions: {pos, rightPos},
              description: 'Horizontal diamond (${tile.right.name})',
            ));
          }
        }
      }

      // Check vertical pair (bottom neighbor)
      final bottomPos = pos.down;
      if (board.containsKey(bottomPos)) {
        final key = '${pos.row},${pos.col}-${bottomPos.row},${bottomPos.col}';
        if (!checked.contains(key)) {
          checked.add(key);
          final bottomTile = board[bottomPos]!;
          // Diamond forms when bottom edge of top tile matches top edge of bottom tile
          if (tile.bottom == bottomTile.top) {
            shapes.add(DetectedShape(
              type: GeometricShapeType.smallDiamond,
              positions: {pos, bottomPos},
              description: 'Vertical diamond (${tile.bottom.name})',
            ));
          }
        }
      }
    }

    return shapes;
  }

  /// Detect large diamonds (4 tiles in 2x2 arrangement).
  /// A large diamond forms when all 4 tiles meet at the center with matching colors.
  static List<DetectedShape> detectLargeDiamonds(Map<BoardPosition, CarpetTile> board) {
    final shapes = <DetectedShape>[];
    final checked = <String>{};

    for (final entry in board.entries) {
      final topLeft = entry.key;
      final topLeftTile = entry.value;

      final topRight = topLeft.right;
      final bottomLeft = topLeft.down;
      final bottomRight = BoardPosition(topLeft.row + 1, topLeft.col + 1);

      // Check if all 4 positions have tiles
      if (!board.containsKey(topRight) ||
          !board.containsKey(bottomLeft) ||
          !board.containsKey(bottomRight)) {
        continue;
      }

      final key = '${topLeft.row},${topLeft.col}';
      if (checked.contains(key)) continue;
      checked.add(key);

      final topRightTile = board[topRight]!;
      final bottomLeftTile = board[bottomLeft]!;
      final bottomRightTile = board[bottomRight]!;

      // Large diamond: center meeting point has matching colors
      // The 4 corners meeting at center are:
      // - topLeft.right + topLeft.bottom
      // - topRight.left + topRight.bottom
      // - bottomLeft.right + bottomLeft.top
      // - bottomRight.left + bottomRight.top

      // For a large diamond, the inner edges meeting at center should share a color
      // Check if there's a dominant color at the center crossing
      final centerColors = [
        topLeftTile.right,
        topLeftTile.bottom,
        topRightTile.left,
        topRightTile.bottom,
        bottomLeftTile.right,
        bottomLeftTile.top,
        bottomRightTile.left,
        bottomRightTile.top,
      ];

      // Count colors
      final colorCount = <TileColor, int>{};
      for (final c in centerColors) {
        colorCount[c] = (colorCount[c] ?? 0) + 1;
      }

      // A large diamond forms when at least 4 of the 8 edges share the same color
      // forming a diamond pattern across the center
      for (final entry in colorCount.entries) {
        if (entry.value >= 4) {
          // Verify the diamond pattern: the color should appear on adjacent edges
          // Check horizontal seam (topLeft.right == topRight.left) and
          // vertical seam (topLeft.bottom == bottomLeft.top)
          final color = entry.key;
          final hasHorizontalTop = topLeftTile.right == color && topRightTile.left == color;
          final hasHorizontalBottom = bottomLeftTile.right == color && bottomRightTile.left == color;
          final hasVerticalLeft = topLeftTile.bottom == color && bottomLeftTile.top == color;
          final hasVerticalRight = topRightTile.bottom == color && bottomRightTile.top == color;

          // Diamond pattern: either cross pattern or rotated pattern
          if ((hasHorizontalTop && hasHorizontalBottom) ||
              (hasVerticalLeft && hasVerticalRight) ||
              (hasHorizontalTop && hasVerticalLeft) ||
              (hasHorizontalTop && hasVerticalRight) ||
              (hasHorizontalBottom && hasVerticalLeft) ||
              (hasHorizontalBottom && hasVerticalRight)) {
            shapes.add(DetectedShape(
              type: GeometricShapeType.largeDiamond,
              positions: {topLeft, topRight, bottomLeft, bottomRight},
              description: 'Large diamond (${color.name})',
            ));
            break;
          }
        }
      }
    }

    return shapes;
  }

  /// Detect small triangles (single tile with one distinct color in 1/4).
  /// A small triangle is when one section of a tile has a unique color
  /// that stands out from the other 3 sections.
  static List<DetectedShape> detectSmallTriangles(Map<BoardPosition, CarpetTile> board) {
    final shapes = <DetectedShape>[];

    for (final entry in board.entries) {
      final pos = entry.key;
      final tile = entry.value;

      // Count colors
      final colors = [tile.top, tile.right, tile.bottom, tile.left];
      final colorCount = <TileColor, int>{};
      for (final c in colors) {
        colorCount[c] = (colorCount[c] ?? 0) + 1;
      }

      // Small triangle: exactly one section has a unique color (3-1 pattern)
      if (colorCount.length == 2) {
        TileColor? singleColor;
        for (final entry in colorCount.entries) {
          if (entry.value == 1) {
            singleColor = entry.key;
            break;
          }
        }
        if (singleColor != null) {
          String direction;
          if (tile.top == singleColor) {
            direction = 'top';
          } else if (tile.right == singleColor) {
            direction = 'right';
          } else if (tile.bottom == singleColor) {
            direction = 'bottom';
          } else {
            direction = 'left';
          }
          shapes.add(DetectedShape(
            type: GeometricShapeType.smallTriangle,
            positions: {pos},
            description: 'Small triangle at $direction (${singleColor.name})',
          ));
        }
      }
    }

    return shapes;
  }

  /// Detect large triangles (3 tiles in L-shape with matching colors).
  /// A large triangle forms across 3 tiles arranged in an L or corner pattern.
  static List<DetectedShape> detectLargeTriangles(Map<BoardPosition, CarpetTile> board) {
    final shapes = <DetectedShape>[];
    final checked = <String>{};

    for (final entry in board.entries) {
      final corner = entry.key;
      final cornerTile = entry.value;

      // Check all 4 possible L-shapes with this tile as corner
      final lShapes = [
        // Corner at top-left, L opens to bottom-right
        (corner, corner.right, corner.down),
        // Corner at top-right, L opens to bottom-left
        (corner, corner.left, corner.down),
        // Corner at bottom-left, L opens to top-right
        (corner, corner.right, corner.up),
        // Corner at bottom-right, L opens to top-left
        (corner, corner.left, corner.up),
      ];

      for (final (c, h, v) in lShapes) {
        if (!board.containsKey(h) || !board.containsKey(v)) continue;

        final positions = [c, h, v];
        positions.sort((a, b) {
          if (a.row != b.row) return a.row.compareTo(b.row);
          return a.col.compareTo(b.col);
        });
        final key = positions.map((p) => '${p.row},${p.col}').join('-');
        if (checked.contains(key)) continue;
        checked.add(key);

        final hTile = board[h]!;
        final vTile = board[v]!;

        // Check for matching edges forming a triangle pattern
        // The triangle is formed when the corner tile connects to both neighbors
        // with the same color, creating a triangular visual

        TileColor? cornerToH;
        TileColor? cornerToV;

        if (h == corner.right) {
          cornerToH = cornerTile.right;
          if (hTile.left != cornerToH) cornerToH = null;
        } else {
          cornerToH = cornerTile.left;
          if (hTile.right != cornerToH) cornerToH = null;
        }

        if (v == corner.down) {
          cornerToV = cornerTile.bottom;
          if (vTile.top != cornerToV) cornerToV = null;
        } else {
          cornerToV = cornerTile.top;
          if (vTile.bottom != cornerToV) cornerToV = null;
        }

        // Large triangle: corner connects to both neighbors with same color
        if (cornerToH != null && cornerToV != null && cornerToH == cornerToV) {
          String direction;
          if (h == corner.right && v == corner.down) {
            direction = 'pointing top-left';
          } else if (h == corner.left && v == corner.down) {
            direction = 'pointing top-right';
          } else if (h == corner.right && v == corner.up) {
            direction = 'pointing bottom-left';
          } else {
            direction = 'pointing bottom-right';
          }

          shapes.add(DetectedShape(
            type: GeometricShapeType.largeTriangle,
            positions: {c, h, v},
            description: 'Large triangle $direction (${cornerToH.name})',
          ));
        }
      }
    }

    return shapes;
  }

  /// Detect small rectangles (2 tiles with matching stripe).
  /// A small rectangle is an elongated color block across 2 tiles.
  static List<DetectedShape> detectSmallRectangles(Map<BoardPosition, CarpetTile> board) {
    final shapes = <DetectedShape>[];
    final checked = <String>{};

    for (final entry in board.entries) {
      final pos = entry.key;
      final tile = entry.value;

      // Horizontal rectangle (2 tiles side by side)
      final rightPos = pos.right;
      if (board.containsKey(rightPos)) {
        final key = 'h-${pos.row},${pos.col}';
        if (!checked.contains(key)) {
          checked.add(key);
          final rightTile = board[rightPos]!;

          // Rectangle: matching edge AND the color extends across both tiles
          // (top sections match or bottom sections match, creating a stripe)
          if (tile.right == rightTile.left) {
            final matchColor = tile.right;
            // Check if top stripe exists (both tops are the matching color)
            if (tile.top == matchColor && rightTile.top == matchColor) {
              shapes.add(DetectedShape(
                type: GeometricShapeType.smallRectangle,
                positions: {pos, rightPos},
                description: 'Top horizontal rectangle (${matchColor.name})',
              ));
            }
            // Check if bottom stripe exists
            if (tile.bottom == matchColor && rightTile.bottom == matchColor) {
              shapes.add(DetectedShape(
                type: GeometricShapeType.smallRectangle,
                positions: {pos, rightPos},
                description: 'Bottom horizontal rectangle (${matchColor.name})',
              ));
            }
          }
        }
      }

      // Vertical rectangle (2 tiles stacked)
      final bottomPos = pos.down;
      if (board.containsKey(bottomPos)) {
        final key = 'v-${pos.row},${pos.col}';
        if (!checked.contains(key)) {
          checked.add(key);
          final bottomTile = board[bottomPos]!;

          if (tile.bottom == bottomTile.top) {
            final matchColor = tile.bottom;
            // Check if left stripe exists
            if (tile.left == matchColor && bottomTile.left == matchColor) {
              shapes.add(DetectedShape(
                type: GeometricShapeType.smallRectangle,
                positions: {pos, bottomPos},
                description: 'Left vertical rectangle (${matchColor.name})',
              ));
            }
            // Check if right stripe exists
            if (tile.right == matchColor && bottomTile.right == matchColor) {
              shapes.add(DetectedShape(
                type: GeometricShapeType.smallRectangle,
                positions: {pos, bottomPos},
                description: 'Right vertical rectangle (${matchColor.name})',
              ));
            }
          }
        }
      }
    }

    return shapes;
  }

  /// Detect large rectangles (3-4 tiles in a line with matching stripe).
  static List<DetectedShape> detectLargeRectangles(Map<BoardPosition, CarpetTile> board) {
    final shapes = <DetectedShape>[];
    final checked = <String>{};

    for (final entry in board.entries) {
      final start = entry.key;
      final startTile = entry.value;

      // Check horizontal lines of 3-4 tiles
      for (final length in [4, 3]) {
        final positions = <BoardPosition>[start];
        var current = start;
        var valid = true;

        for (int i = 1; i < length; i++) {
          final next = current.right;
          if (!board.containsKey(next)) {
            valid = false;
            break;
          }
          positions.add(next);
          current = next;
        }

        if (!valid || positions.length != length) continue;

        final key = 'h$length-${start.row},${start.col}';
        if (checked.contains(key)) continue;
        checked.add(key);

        // Check for continuous stripe (top or bottom)
        for (final checkTop in [true, false]) {
          TileColor? stripeColor;
          var hasStripe = true;

          for (int i = 0; i < positions.length; i++) {
            final tile = board[positions[i]]!;
            final edgeColor = checkTop ? tile.top : tile.bottom;

            if (i == 0) {
              stripeColor = edgeColor;
            } else if (edgeColor != stripeColor) {
              hasStripe = false;
              break;
            }

            // Check internal edges match
            if (i < positions.length - 1) {
              final nextTile = board[positions[i + 1]]!;
              if (tile.right != nextTile.left || tile.right != stripeColor) {
                hasStripe = false;
                break;
              }
            }
          }

          if (hasStripe && stripeColor != null) {
            shapes.add(DetectedShape(
              type: GeometricShapeType.largeRectangle,
              positions: positions.toSet(),
              description: '${checkTop ? "Top" : "Bottom"} ${length}-tile rectangle (${stripeColor.name})',
            ));
          }
        }
      }

      // Check vertical lines of 3-4 tiles
      for (final length in [4, 3]) {
        final positions = <BoardPosition>[start];
        var current = start;
        var valid = true;

        for (int i = 1; i < length; i++) {
          final next = current.down;
          if (!board.containsKey(next)) {
            valid = false;
            break;
          }
          positions.add(next);
          current = next;
        }

        if (!valid || positions.length != length) continue;

        final key = 'v$length-${start.row},${start.col}';
        if (checked.contains(key)) continue;
        checked.add(key);

        // Check for continuous stripe (left or right)
        for (final checkLeft in [true, false]) {
          TileColor? stripeColor;
          var hasStripe = true;

          for (int i = 0; i < positions.length; i++) {
            final tile = board[positions[i]]!;
            final edgeColor = checkLeft ? tile.left : tile.right;

            if (i == 0) {
              stripeColor = edgeColor;
            } else if (edgeColor != stripeColor) {
              hasStripe = false;
              break;
            }

            // Check internal edges match
            if (i < positions.length - 1) {
              final nextTile = board[positions[i + 1]]!;
              if (tile.bottom != nextTile.top || tile.bottom != stripeColor) {
                hasStripe = false;
                break;
              }
            }
          }

          if (hasStripe && stripeColor != null) {
            shapes.add(DetectedShape(
              type: GeometricShapeType.largeRectangle,
              positions: positions.toSet(),
              description: '${checkLeft ? "Left" : "Right"} ${length}-tile rectangle (${stripeColor.name})',
            ));
          }
        }
      }
    }

    return shapes;
  }

  /// Detect arrows (3-5 tiles forming arrow shapes).
  /// Arrows have a pointed end and a wide base.
  static List<DetectedShape> detectArrows(Map<BoardPosition, CarpetTile> board) {
    final shapes = <DetectedShape>[];
    final checked = <String>{};

    for (final entry in board.entries) {
      final tip = entry.key;
      final tipTile = entry.value;

      // Arrow pointing right: tip at left, shaft going right
      _checkArrowPattern(board, tip, tipTile, 'right', shapes, checked);
      // Arrow pointing left: tip at right, shaft going left
      _checkArrowPattern(board, tip, tipTile, 'left', shapes, checked);
      // Arrow pointing down: tip at top, shaft going down
      _checkArrowPattern(board, tip, tipTile, 'down', shapes, checked);
      // Arrow pointing up: tip at bottom, shaft going up
      _checkArrowPattern(board, tip, tipTile, 'up', shapes, checked);
    }

    return shapes;
  }

  static void _checkArrowPattern(
    Map<BoardPosition, CarpetTile> board,
    BoardPosition tip,
    CarpetTile tipTile,
    String direction,
    List<DetectedShape> shapes,
    Set<String> checked,
  ) {
    // Arrow pattern: pointed tip connects to 2-3 tiles in the body
    // forming a pointed shape in the given direction

    BoardPosition Function(BoardPosition) getNext;
    BoardPosition Function(BoardPosition) getSide1;
    BoardPosition Function(BoardPosition) getSide2;
    TileColor Function(CarpetTile) getTipEdge;
    TileColor Function(CarpetTile) getBackEdge;
    TileColor Function(CarpetTile) getSide1Edge;
    TileColor Function(CarpetTile) getSide2Edge;

    switch (direction) {
      case 'right':
        getNext = (p) => p.right;
        getSide1 = (p) => p.up;
        getSide2 = (p) => p.down;
        getTipEdge = (t) => t.right;
        getBackEdge = (t) => t.left;
        getSide1Edge = (t) => t.top;
        getSide2Edge = (t) => t.bottom;
        break;
      case 'left':
        getNext = (p) => p.left;
        getSide1 = (p) => p.up;
        getSide2 = (p) => p.down;
        getTipEdge = (t) => t.left;
        getBackEdge = (t) => t.right;
        getSide1Edge = (t) => t.top;
        getSide2Edge = (t) => t.bottom;
        break;
      case 'down':
        getNext = (p) => p.down;
        getSide1 = (p) => p.left;
        getSide2 = (p) => p.right;
        getTipEdge = (t) => t.bottom;
        getBackEdge = (t) => t.top;
        getSide1Edge = (t) => t.left;
        getSide2Edge = (t) => t.right;
        break;
      case 'up':
      default:
        getNext = (p) => p.up;
        getSide1 = (p) => p.left;
        getSide2 = (p) => p.right;
        getTipEdge = (t) => t.top;
        getBackEdge = (t) => t.bottom;
        getSide1Edge = (t) => t.left;
        getSide2Edge = (t) => t.right;
        break;
    }

    // Check for arrow with shaft and wings
    final shaft1 = getNext(tip);
    if (!board.containsKey(shaft1)) return;

    final shaft1Tile = board[shaft1]!;
    final arrowColor = getTipEdge(tipTile);

    // Tip must connect to shaft with matching color
    if (getBackEdge(shaft1Tile) != arrowColor) return;

    // Check for wings at shaft position (forming the arrowhead spread)
    final wing1 = getSide1(shaft1);
    final wing2 = getSide2(shaft1);

    final hasWing1 = board.containsKey(wing1);
    final hasWing2 = board.containsKey(wing2);

    if (!hasWing1 && !hasWing2) return;

    final positions = <BoardPosition>{tip, shaft1};
    var validArrow = false;

    if (hasWing1 && hasWing2) {
      final wing1Tile = board[wing1]!;
      final wing2Tile = board[wing2]!;

      // Wings should connect to shaft with arrow color
      final wing1Edge = switch (direction) {
        'right' || 'left' => wing1Tile.bottom,
        _ => wing1Tile.right,
      };
      final wing2Edge = switch (direction) {
        'right' || 'left' => wing2Tile.top,
        _ => wing2Tile.left,
      };

      final shaft1Side1 = getSide1Edge(shaft1Tile);
      final shaft1Side2 = getSide2Edge(shaft1Tile);

      if (wing1Edge == arrowColor && shaft1Side1 == arrowColor &&
          wing2Edge == arrowColor && shaft1Side2 == arrowColor) {
        positions.add(wing1);
        positions.add(wing2);
        validArrow = true;
      }
    } else if (hasWing1) {
      final wing1Tile = board[wing1]!;
      final wing1Edge = switch (direction) {
        'right' || 'left' => wing1Tile.bottom,
        _ => wing1Tile.right,
      };
      final shaft1Side1 = getSide1Edge(shaft1Tile);
      if (wing1Edge == arrowColor && shaft1Side1 == arrowColor) {
        positions.add(wing1);
        validArrow = true;
      }
    } else if (hasWing2) {
      final wing2Tile = board[wing2]!;
      final wing2Edge = switch (direction) {
        'right' || 'left' => wing2Tile.top,
        _ => wing2Tile.left,
      };
      final shaft1Side2 = getSide2Edge(shaft1Tile);
      if (wing2Edge == arrowColor && shaft1Side2 == arrowColor) {
        positions.add(wing2);
        validArrow = true;
      }
    }

    if (!validArrow) return;

    // Optionally extend shaft
    final shaft2 = getNext(shaft1);
    if (board.containsKey(shaft2)) {
      final shaft2Tile = board[shaft2]!;
      if (getBackEdge(shaft2Tile) == arrowColor && getTipEdge(shaft1Tile) == arrowColor) {
        positions.add(shaft2);
      }
    }

    if (positions.length < 3) return;

    final sortedPos = positions.toList()..sort((a, b) {
      if (a.row != b.row) return a.row.compareTo(b.row);
      return a.col.compareTo(b.col);
    });
    final key = '$direction-${sortedPos.map((p) => '${p.row},${p.col}').join('-')}';
    if (checked.contains(key)) return;
    checked.add(key);

    shapes.add(DetectedShape(
      type: GeometricShapeType.arrow,
      positions: positions,
      description: 'Arrow pointing $direction (${arrowColor.name})',
    ));
  }

  /// Get the list of shapes still needed to complete the challenge.
  static List<GeometricShapeType> getRemainingShapes(Set<GeometricShapeType> completed) {
    return GeometricShapeType.values
        .where((type) => !completed.contains(type))
        .toList();
  }

  /// Get a hint for what shape to build next.
  static String getNextShapeHint(Set<GeometricShapeType> completed) {
    final remaining = getRemainingShapes(completed);
    if (remaining.isEmpty) {
      return 'All shapes completed!';
    }

    // Suggest shapes in order of difficulty (easiest first)
    final priority = [
      GeometricShapeType.smallTriangle,
      GeometricShapeType.smallDiamond,
      GeometricShapeType.smallRectangle,
      GeometricShapeType.largeDiamond,
      GeometricShapeType.largeTriangle,
      GeometricShapeType.largeRectangle,
      GeometricShapeType.arrow,
    ];

    for (final shape in priority) {
      if (remaining.contains(shape)) {
        return 'Build a ${shape.displayName}!';
      }
    }

    return 'Build any remaining shape!';
  }
}
