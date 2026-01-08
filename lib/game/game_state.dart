import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'shape_detector.dart';

/// Represents the state of a carpet tile game supporting Regular Flow and Shape Flow modes.
class GameState extends ChangeNotifier {
  final GameMode mode;
  final List<Player> players;
  final Map<BoardPosition, CarpetTile> board;
  final ScoreSystem score;
  final List<ScoreSystem> playerScores;

  int _currentPlayerIndex;
  CarpetTile? _selectedTile;
  String? _winner;
  bool _gameOver;
  String? _message;
  List<BoardPosition> _validPositions;
  List<BoardPosition> _allAdjacentPositions;
  PlacementResult? _lastPlacementResult;
  int _nextTileId;

  // Target grid size for the current level
  int _targetGridSize = 0;

  // Board boundaries
  int _minRow = 0;
  int _maxRow = 0;
  int _minCol = 0;
  int _maxCol = 0;

  // Undo support
  final List<_GameAction> _history = [];

  // === Regular Flow specific ===
  int _currentLevel = 1;
  List<CarpetTile> _availablePieces = []; // Pieces available across levels

  // === Shape Flow specific ===
  final Set<GeometricShapeType> _completedShapeTypes = {};
  List<DetectedShape> _detectedShapes = [];
  GeometricShapeType? _currentTargetShape;
  int _shapeFlowLevel = 1;

  GameState({
    required this.mode,
    required this.players,
    Map<BoardPosition, CarpetTile>? initialBoard,
  })  : board = initialBoard ?? {},
        score = ScoreSystem(),
        playerScores = players.map((_) => ScoreSystem()).toList(),
        _currentPlayerIndex = 0,
        _gameOver = false,
        _validPositions = [],
        _allAdjacentPositions = [],
        _nextTileId = 0;

  // Getters
  Player get currentPlayer => players[_currentPlayerIndex];
  int get currentPlayerIndex => _currentPlayerIndex;
  CarpetTile? get selectedTile => _selectedTile;
  String? get winner => _winner;
  bool get gameOver => _gameOver;
  String? get message => _message;
  List<BoardPosition> get validPositions => _validPositions;
  List<BoardPosition> get allAdjacentPositions => _allAdjacentPositions;
  PlacementResult? get lastPlacementResult => _lastPlacementResult;
  bool get canUndo => _history.isNotEmpty;

  int get minRow => _minRow;
  int get maxRow => _maxRow;
  int get minCol => _minCol;
  int get maxCol => _maxCol;
  int get targetGridSize => _targetGridSize;

  // Regular Flow getters
  int get currentLevel => _currentLevel;
  int get availablePiecesCount => _availablePieces.length;

  // Shape Flow getters
  Set<GeometricShapeType> get completedShapeTypes => _completedShapeTypes;
  List<DetectedShape> get detectedShapes => _detectedShapes;
  GeometricShapeType? get currentTargetShape => _currentTargetShape;
  int get shapeFlowLevel => _shapeFlowLevel;

  /// Get the current player's score.
  ScoreSystem get currentScore {
    return playerScores[_currentPlayerIndex];
  }

  /// Initialize a new Regular Flow game.
  static GameState newRegularFlow() {
    final players = [Player(id: 'player_0', name: 'Builder')];
    final state = GameState(mode: GameMode.regularFlow, players: players);

    // Initialize with all 36 pieces
    state._availablePieces = CarpetTile.getBuildTiles()
        .map((t) => t.copyWithId('tile_${state._nextTileId++}'))
        .toList();

    // Start at level 1
    state._initLevel(1);

    return state;
  }

  /// Initialize a new Shape Flow game.
  static GameState newShapeFlow() {
    final players = [Player(id: 'player_0', name: 'Builder')];
    final state = GameState(mode: GameMode.shapeFlow, players: players);

    // Give all 36 build tiles
    final buildTiles = CarpetTile.getBuildTiles();
    for (final tile in buildTiles) {
      players[0].addTile(tile.copyWithId('tile_${state._nextTileId++}'));
    }

    // Start with 2x2 grid and first shape target
    state._shapeFlowLevel = 1;
    state._targetGridSize = 2;
    state._selectNextTargetShape();
    state._updatePositions();

    return state;
  }

  /// Initialize a specific level for Regular Flow.
  void _initLevel(int level) {
    _currentLevel = level;
    final config = getLevelConfig(level);
    _targetGridSize = config.gridSize;

    // Reset pieces if needed
    if (config.resetPieces) {
      _availablePieces = CarpetTile.getBuildTiles()
          .map((t) => t.copyWithId('tile_${_nextTileId++}'))
          .toList();
    }

    // Clear board
    board.clear();
    _history.clear();
    _recalculateBoundaries();

    // Give player pieces from available pool
    currentPlayer.hand.clear();
    final piecesToGive = List<CarpetTile>.from(_availablePieces);
    piecesToGive.shuffle();
    for (final tile in piecesToGive) {
      currentPlayer.addTile(tile);
    }

    _message = 'Level $level: Fill the ${config.gridDescription} grid! (${_availablePieces.length} pieces)';
    _updatePositions();
    notifyListeners();
  }

  /// Advance to the next level in Regular Flow.
  void _advanceToNextLevel() {
    if (_currentLevel >= totalRegularFlowLevels) {
      _gameOver = true;
      _message = 'Congratulations! You completed all 12 levels!';
      notifyListeners();
      return;
    }

    // Remove used pieces from available pool
    final usedPieceIds = board.values.map((t) => t.id).toSet();
    _availablePieces.removeWhere((t) => usedPieceIds.contains(t.id));

    _initLevel(_currentLevel + 1);
  }

  /// Select the next target shape for Shape Flow.
  void _selectNextTargetShape() {
    final remaining = ShapeDetector.getRemainingShapes(_completedShapeTypes);
    if (remaining.isEmpty) {
      _currentTargetShape = null;
      return;
    }

    // Prioritize shapes by difficulty (easier first)
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
        _currentTargetShape = shape;

        // Determine grid size based on shape
        // Small shapes (1-2 tiles) use 2x2, larger shapes use 3x3
        if (shape == GeometricShapeType.smallTriangle ||
            shape == GeometricShapeType.smallDiamond ||
            shape == GeometricShapeType.smallRectangle) {
          _targetGridSize = 2;
        } else {
          _targetGridSize = 3;
        }

        _message = 'Build a ${shape.displayName} and fill the ${_targetGridSize}x$_targetGridSize grid!';
        return;
      }
    }
  }

  /// Select a tile from the current player's hand.
  void selectTile(CarpetTile? tile) {
    _selectedTile = tile;
    _message = null;
    _lastPlacementResult = null;
    _updatePositions();
    notifyListeners();
  }

  /// Rotate the selected tile clockwise.
  void rotateSelectedTile() {
    if (_selectedTile == null) return;

    final index = currentPlayer.hand.indexWhere((t) => t.id == _selectedTile!.id);
    if (index >= 0) {
      final rotated = _selectedTile!.rotateClockwise();
      currentPlayer.hand[index] = rotated;
      _selectedTile = rotated;
      _updatePositions();
      notifyListeners();
    }
  }

  /// Rotate a tile in the current player's hand.
  void rotateHandTile(CarpetTile tile) {
    final index = currentPlayer.hand.indexWhere((t) => t.id == tile.id);
    if (index >= 0) {
      final rotated = tile.rotateClockwise();
      currentPlayer.hand[index] = rotated;
      notifyListeners();
    }
  }

  /// Check edge match status for a tile at a position.
  Map<int, EdgeMatchStatus> getEdgeMatchStatus(CarpetTile tile, BoardPosition position) {
    final status = <int, EdgeMatchStatus>{};

    final neighbors = [
      (position.up, 2, 0),    // top edge
      (position.right, 3, 1), // right edge
      (position.down, 0, 2),  // bottom edge
      (position.left, 1, 3),  // left edge
    ];

    for (final (neighborPos, neighborEdge, ourEdge) in neighbors) {
      final neighbor = board[neighborPos];
      if (neighbor == null) {
        status[ourEdge] = EdgeMatchStatus.noAdjacent;
      } else if (neighbor.getEdgeColor(neighborEdge) == tile.getEdgeColor(ourEdge)) {
        status[ourEdge] = EdgeMatchStatus.matching;
      } else {
        status[ourEdge] = EdgeMatchStatus.mismatched;
      }
    }

    return status;
  }

  /// Count matching edges for a tile at a position.
  (int matching, int total) countMatchingEdges(CarpetTile tile, BoardPosition position) {
    int matching = 0;
    int total = 0;

    final neighbors = [
      (position.up, 2, 0),
      (position.right, 3, 1),
      (position.down, 0, 2),
      (position.left, 1, 3),
    ];

    for (final (neighborPos, neighborEdge, ourEdge) in neighbors) {
      final neighbor = board[neighborPos];
      if (neighbor != null) {
        total++;
        if (neighbor.getEdgeColor(neighborEdge) == tile.getEdgeColor(ourEdge)) {
          matching++;
        }
      }
    }

    return (matching, total);
  }

  /// Check if a tile can be placed at a position (strict rules - all edges must match).
  bool canPlaceTileStrict(CarpetTile tile, BoardPosition position) {
    if (board.isEmpty) return true;
    if (board.containsKey(position)) return false;

    final (matching, total) = countMatchingEdges(tile, position);
    return total > 0 && matching == total;
  }

  /// Check if a tile can be placed (mode-aware).
  bool canPlaceTile(CarpetTile tile, BoardPosition position) {
    if (board.containsKey(position)) return false;

    // Fixed grid - allow placing anywhere in the grid
    if (_targetGridSize > 0) {
      return position.row >= 0 && position.row < _targetGridSize &&
             position.col >= 0 && position.col < _targetGridSize;
    }

    return canPlaceTileStrict(tile, position);
  }

  /// Get all valid positions for a tile.
  List<BoardPosition> getValidPositions(CarpetTile tile) {
    // Fixed grid modes - return all empty positions in the grid
    if (_targetGridSize > 0) {
      final positions = <BoardPosition>[];
      for (int row = 0; row < _targetGridSize; row++) {
        for (int col = 0; col < _targetGridSize; col++) {
          final pos = BoardPosition(row, col);
          if (!board.containsKey(pos)) {
            positions.add(pos);
          }
        }
      }
      return positions;
    }

    if (board.isEmpty) {
      return [const BoardPosition(0, 0)];
    }

    final positions = <BoardPosition>[];
    final positionsToCheck = _getAdjacentEmptyPositions();

    for (final pos in positionsToCheck) {
      if (canPlaceTile(tile, pos)) {
        positions.add(pos);
      }
    }

    return positions;
  }

  Set<BoardPosition> _getAdjacentEmptyPositions() {
    final positions = <BoardPosition>{};
    for (final pos in board.keys) {
      for (final neighbor in pos.neighbors) {
        if (!board.containsKey(neighbor)) {
          positions.add(neighbor);
        }
      }
    }
    return positions;
  }

  void _updatePositions() {
    _allAdjacentPositions = _getAdjacentEmptyPositions().toList();

    if (_selectedTile != null) {
      _validPositions = getValidPositions(_selectedTile!);
    } else {
      _validPositions = [];
    }
  }

  /// Place the selected tile at a position.
  bool placeTile(BoardPosition position) {
    if (_selectedTile == null) {
      _message = 'Select a tile first!';
      notifyListeners();
      return false;
    }
    return placeTileAt(_selectedTile!, position);
  }

  /// Place a specific tile at a position (used for drag-and-drop).
  bool placeTileAt(CarpetTile tile, BoardPosition position) {
    if (!canPlaceTile(tile, position)) {
      _message = 'Try another spot!';
      notifyListeners();
      return false;
    }

    // Save for undo
    _history.add(_GameAction(
      tile: tile,
      position: position,
      playerIndex: _currentPlayerIndex,
    ));

    // Calculate score
    final (matching, total) = countMatchingEdges(tile, position);
    _lastPlacementResult = currentScore.addTilePlacement(
      matchingEdges: matching,
      totalAdjacentTiles: total,
    );

    // Place the tile
    board[position] = tile;
    currentPlayer.removeTile(tile);

    // Update board boundaries
    if (position.row < _minRow) _minRow = position.row;
    if (position.row > _maxRow) _maxRow = position.row;
    if (position.col < _minCol) _minCol = position.col;
    if (position.col > _maxCol) _maxCol = position.col;

    // Generate feedback message
    _generatePlacementMessage();

    // Handle mode-specific logic
    switch (mode) {
      case GameMode.regularFlow:
        _handleRegularFlowPlacement();
        break;
      case GameMode.shapeFlow:
        _handleShapeFlowPlacement();
        break;
    }

    _selectedTile = null;
    _updatePositions();
    notifyListeners();
    return true;
  }

  /// Rotate a tile that is already placed on the board.
  void rotatePlacedTile(BoardPosition position) {
    final tile = board[position];
    if (tile == null) return;

    board[position] = tile.rotateClockwise();

    // Update message with current status
    _updateStatusMessage();

    notifyListeners();
  }

  /// Swap or move a tile from one position to another.
  void swapTiles(BoardPosition from, BoardPosition to) {
    if (from == to) return;

    final fromTile = board[from];
    final toTile = board[to];

    if (fromTile == null) return;

    // Perform the swap
    if (toTile != null) {
      board[from] = toTile;
      board[to] = fromTile;
    } else {
      // Just move to empty position
      board.remove(from);
      board[to] = fromTile;
    }

    _updateStatusMessage();
    notifyListeners();
  }

  /// Replace a tile on the board with a tile from hand.
  void replaceTile(CarpetTile handTile, BoardPosition position) {
    final boardTile = board[position];
    if (boardTile == null) return;

    // Remove hand tile from player's hand
    currentPlayer.removeTile(handTile);

    // Put board tile back in player's hand
    currentPlayer.addTile(boardTile);

    // Put hand tile on the board
    board[position] = handTile;

    // Clear selection
    _selectedTile = null;

    _updateStatusMessage();
    _updatePositions();
    notifyListeners();
  }

  void _updateStatusMessage() {
    if (_targetGridSize > 0) {
      final target = _targetGridSize * _targetGridSize;
      final tilesPlaced = board.length;
      final tilesNeeded = target - tilesPlaced;
      if (tilesNeeded > 0) {
        final mismatches = _countMismatches();
        if (mismatches > 0) {
          _message = '$tilesNeeded to go - $mismatches mismatch${mismatches == 1 ? '' : 'es'}';
        } else {
          _message = '$tilesNeeded more tile${tilesNeeded == 1 ? '' : 's'} to go!';
        }
      }
    }
  }

  void _generatePlacementMessage() {
    if (_lastPlacementResult == null) return;

    final result = _lastPlacementResult!;
    if (result.hasAchievements) {
      _message = result.newAchievements.join(' ');
    } else if (result.isPerfectMatch) {
      _message = 'Perfect match! +${result.pointsEarned} points';
    } else if (result.matchingEdges > 0) {
      _message = 'Nice! +${result.pointsEarned} points';
    } else {
      _message = '+${result.pointsEarned} points';
    }
  }

  /// Handle placement in Regular Flow mode.
  void _handleRegularFlowPlacement() {
    final target = _targetGridSize * _targetGridSize;
    final tilesPlaced = board.length;
    final tilesNeeded = target - tilesPlaced;

    if (tilesNeeded <= 0) {
      // Level complete!
      final mismatches = _countMismatches();
      if (mismatches == 0) {
        _message = 'Level $_currentLevel complete! Perfect match!';
      } else {
        _message = 'Level $_currentLevel complete! $mismatches mismatch${mismatches == 1 ? '' : 'es'}';
      }

      // Advance to next level after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        _advanceToNextLevel();
      });
    } else {
      final mismatches = _countMismatches();
      if (mismatches > 0) {
        _message = '$tilesNeeded to go - $mismatches mismatch${mismatches == 1 ? '' : 'es'}';
      } else {
        _message = '$tilesNeeded more tile${tilesNeeded == 1 ? '' : 's'} to go!';
      }
    }
  }

  /// Handle placement in Shape Flow mode.
  void _handleShapeFlowPlacement() {
    // Detect shapes on the board
    _detectedShapes = ShapeDetector.detectAllShapes(board);

    // Check if target shape is completed
    bool targetShapeCompleted = false;
    for (final shape in _detectedShapes) {
      if (shape.type == _currentTargetShape && !_completedShapeTypes.contains(shape.type)) {
        targetShapeCompleted = true;
        break;
      }
    }

    // Check if grid is full
    final target = _targetGridSize * _targetGridSize;
    final tilesPlaced = board.length;
    final gridFull = tilesPlaced >= target;

    if (gridFull) {
      final mismatches = _countMismatches();

      if (targetShapeCompleted) {
        // Success! Shape completed AND grid is full
        _completedShapeTypes.add(_currentTargetShape!);
        _shapeFlowLevel++;

        // Check if all shapes are completed
        if (_completedShapeTypes.length == GeometricShapeType.values.length) {
          _gameOver = true;
          _message = 'Amazing! You completed all shapes!';
          return;
        }

        // Return tiles to hand and select next shape
        _returnTilesToHand();
        _selectNextTargetShape();
        _message = '${_currentTargetShape?.displayName ?? "Shape"} complete! (${_completedShapeTypes.length}/7) - Now: Build a ${_currentTargetShape?.displayName}!';
      } else {
        // Grid full but target shape not completed
        _message = 'Grid full but ${_currentTargetShape?.displayName} not found! $mismatches mismatch${mismatches == 1 ? '' : 'es'}. Try rearranging!';
      }
    } else {
      // Grid not full yet
      final tilesNeeded = target - tilesPlaced;
      if (targetShapeCompleted) {
        _message = '${_currentTargetShape?.displayName} found! Fill ${tilesNeeded} more tile${tilesNeeded == 1 ? '' : 's'}!';
      } else {
        _message = 'Build ${_currentTargetShape?.displayName}! $tilesNeeded tile${tilesNeeded == 1 ? '' : 's'} to go.';
      }
    }
  }

  void _returnTilesToHand() {
    for (final tile in board.values) {
      currentPlayer.addTile(tile);
    }
    board.clear();
    _history.clear();
    _recalculateBoundaries();
  }

  /// Count the number of mismatched edges in the current board.
  int _countMismatches() {
    int mismatches = 0;
    for (final entry in board.entries) {
      final position = entry.key;
      final tile = entry.value;
      final status = getEdgeMatchStatus(tile, position);
      for (final edgeStatus in status.values) {
        if (edgeStatus == EdgeMatchStatus.mismatched) {
          mismatches++;
        }
      }
    }
    // Each mismatch is counted twice (once from each tile), so divide by 2
    return mismatches ~/ 2;
  }

  /// Undo the last placement.
  void undo() {
    if (_history.isEmpty) return;

    final action = _history.removeLast();
    board.remove(action.position);
    players[action.playerIndex].addTile(action.tile);
    _currentPlayerIndex = action.playerIndex;

    // Recalculate boundaries
    _recalculateBoundaries();
    _updatePositions();
    _message = 'Undone!';
    _lastPlacementResult = null;
    notifyListeners();
  }

  void _recalculateBoundaries() {
    if (board.isEmpty) {
      _minRow = _maxRow = _minCol = _maxCol = 0;
      return;
    }

    _minRow = board.keys.map((p) => p.row).reduce((a, b) => a < b ? a : b);
    _maxRow = board.keys.map((p) => p.row).reduce((a, b) => a > b ? a : b);
    _minCol = board.keys.map((p) => p.col).reduce((a, b) => a < b ? a : b);
    _maxCol = board.keys.map((p) => p.col).reduce((a, b) => a > b ? a : b);
  }

  /// Restart the game.
  void restart() {
    board.clear();
    _currentPlayerIndex = 0;
    _selectedTile = null;
    _winner = null;
    _gameOver = false;
    _message = null;
    _validPositions = [];
    _allAdjacentPositions = [];
    _lastPlacementResult = null;
    _history.clear();
    _minRow = _maxRow = _minCol = _maxCol = 0;

    score.reset();
    for (final ps in playerScores) {
      ps.reset();
    }

    _nextTileId = 0;

    // Mode-specific restart
    if (mode == GameMode.regularFlow) {
      _currentLevel = 1;
      _availablePieces = CarpetTile.getBuildTiles()
          .map((t) => t.copyWithId('tile_${_nextTileId++}'))
          .toList();
      _initLevel(1);
    } else if (mode == GameMode.shapeFlow) {
      _completedShapeTypes.clear();
      _detectedShapes = [];
      _shapeFlowLevel = 1;

      // Reset tiles
      for (final player in players) {
        player.hand.clear();
      }
      final buildTiles = CarpetTile.getBuildTiles();
      for (final tile in buildTiles) {
        players[0].addTile(tile.copyWithId('tile_${_nextTileId++}'));
      }

      _targetGridSize = 2;
      _selectNextTargetShape();
      _updatePositions();
    }

    notifyListeners();
  }

  /// Skip to a specific level (for testing/debugging).
  void skipToLevel(int level) {
    if (mode != GameMode.regularFlow) return;
    if (level < 1 || level > totalRegularFlowLevels) return;

    _initLevel(level);
  }
}

/// Represents an action for undo support.
class _GameAction {
  final CarpetTile tile;
  final BoardPosition position;
  final int playerIndex;

  _GameAction({
    required this.tile,
    required this.position,
    required this.playerIndex,
  });
}
