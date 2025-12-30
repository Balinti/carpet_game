import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Represents the state of a carpet tile game supporting multiple modes.
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
  List<CarpetTile> _tilePool; // For free play mode
  int _nextTileId;

  // Board boundaries (dynamic, expands as tiles are placed)
  int _minRow = 0;
  int _maxRow = 0;
  int _minCol = 0;
  int _maxCol = 0;

  // Undo support
  final List<_GameAction> _history = [];

  // Clue system
  int _cluesUsed = 0;
  static const int cluePointPenalty = 15;

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
        _tilePool = [],
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
  int get cluesUsed => _cluesUsed;

  /// Whether scores should be hidden (for deferred validation modes).
  bool get hideScores => mode.hasDeferredValidation && !_gameOver;

  /// Get the current player's score (or team score for cooperative).
  ScoreSystem get currentScore {
    if (mode == GameMode.cooperative) {
      return score;
    }
    return playerScores[_currentPlayerIndex];
  }

  /// Initialize a new competitive Color Dominoes game.
  static GameState newColorDominoes(int playerCount) {
    if (playerCount < 2 || playerCount > 4) {
      throw ArgumentError('Player count must be between 2 and 4');
    }

    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: 'Player ${i + 1}'),
    );

    final state = GameState(mode: GameMode.colorDominoes, players: players);

    // Deal 6 tiles to each player
    for (final player in players) {
      for (int i = 0; i < 6; i++) {
        player.addTile(CarpetTile.generateRandom('tile_${state._nextTileId++}'));
      }
    }

    state._updatePositions();
    return state;
  }

  /// Initialize a new Free Play sandbox game.
  static GameState newFreePlay({int playerCount = 1}) {
    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: playerCount == 1 ? 'Builder' : 'Player ${i + 1}'),
    );

    final state = GameState(mode: GameMode.freePlay, players: players);

    // Give initial tiles
    for (final player in players) {
      for (int i = 0; i < 8; i++) {
        player.addTile(CarpetTile.generateRandom('tile_${state._nextTileId++}'));
      }
    }

    // Create tile pool for drawing
    state._refillTilePool();
    state._updatePositions();
    return state;
  }

  /// Initialize a new Guided Learning game.
  static GameState newGuidedLearning({int playerCount = 1}) {
    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: playerCount == 1 ? 'Learner' : 'Player ${i + 1}'),
    );

    final state = GameState(mode: GameMode.guidedLearning, players: players);

    // Give initial tiles
    for (final player in players) {
      for (int i = 0; i < 8; i++) {
        player.addTile(CarpetTile.generateRandom('tile_${state._nextTileId++}'));
      }
    }

    state._refillTilePool();
    state._updatePositions();
    return state;
  }

  /// Initialize a new Cooperative game.
  static GameState newCooperative(int playerCount) {
    if (playerCount < 1 || playerCount > 4) {
      throw ArgumentError('Player count must be between 1 and 4');
    }

    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: 'Player ${i + 1}'),
    );

    final state = GameState(mode: GameMode.cooperative, players: players);

    // Deal tiles to each player
    for (final player in players) {
      for (int i = 0; i < 6; i++) {
        player.addTile(CarpetTile.generateRandom('tile_${state._nextTileId++}'));
      }
    }

    state._refillTilePool();
    state._updatePositions();
    state._message = "Let's build together!";
    return state;
  }

  /// Initialize a new Shape Builder game.
  static GameState newShapeBuilder({int playerCount = 1}) {
    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: playerCount == 1 ? 'Builder' : 'Player ${i + 1}'),
    );

    final state = GameState(mode: GameMode.shapeBuilder, players: players);

    // Give initial tiles
    for (final player in players) {
      for (int i = 0; i < 8; i++) {
        player.addTile(CarpetTile.generateRandom('tile_${state._nextTileId++}'));
      }
    }

    // Create tile pool for drawing
    state._refillTilePool();
    state._updatePositions();
    return state;
  }

  /// Initialize a new Geometric Shapes game.
  static GameState newGeometricShapes({int playerCount = 1}) {
    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: playerCount == 1 ? 'Builder' : 'Player ${i + 1}'),
    );

    final state = GameState(mode: GameMode.geometricShapes, players: players);

    // Give initial tiles - more tiles for building shapes
    for (final player in players) {
      for (int i = 0; i < 12; i++) {
        player.addTile(CarpetTile.generateRandom('tile_${state._nextTileId++}'));
      }
    }

    // Create tile pool for drawing
    state._refillTilePool();
    state._updatePositions();
    state._message = 'Build a 2×2 square!';
    return state;
  }

  void _refillTilePool() {
    // Keep a pool of tiles to draw from
    while (_tilePool.length < 20) {
      _tilePool.add(CarpetTile.generateRandom('tile_${_nextTileId++}'));
    }
  }

  /// Draw a new tile from the pool (for non-competitive modes).
  void drawTile() {
    if (mode == GameMode.colorDominoes) return;

    _refillTilePool();
    if (_tilePool.isNotEmpty) {
      currentPlayer.addTile(_tilePool.removeAt(0));
      notifyListeners();
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

  /// Rotate the selected tile counter-clockwise.
  void rotateSelectedTileCounterClockwise() {
    if (_selectedTile == null) return;

    final index = currentPlayer.hand.indexWhere((t) => t.id == _selectedTile!.id);
    if (index >= 0) {
      final rotated = _selectedTile!.rotateCounterClockwise();
      currentPlayer.hand[index] = rotated;
      _selectedTile = rotated;
      _updatePositions();
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

  /// Check if a tile can be placed at a position (strict rules).
  bool canPlaceTileStrict(CarpetTile tile, BoardPosition position) {
    if (board.isEmpty) return true;
    if (board.containsKey(position)) return false;

    final (matching, total) = countMatchingEdges(tile, position);
    return total > 0 && matching == total;
  }

  /// Check if a tile can be placed (mode-aware).
  bool canPlaceTile(CarpetTile tile, BoardPosition position) {
    if (board.containsKey(position)) return false;

    // Free play, guided learning, and shape builder allow any adjacent placement
    if (mode.allowsFreePlacement) {
      if (board.isEmpty) return true;
      return position.neighbors.any((n) => board.containsKey(n));
    }

    // Competitive and cooperative require matching
    return canPlaceTileStrict(tile, position);
  }

  /// Get all valid positions for a tile.
  List<BoardPosition> getValidPositions(CarpetTile tile) {
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

    if (!canPlaceTile(_selectedTile!, position)) {
      _message = 'Try another spot!';
      notifyListeners();
      return false;
    }

    // Save for undo
    _history.add(_GameAction(
      tile: _selectedTile!,
      position: position,
      playerIndex: _currentPlayerIndex,
    ));

    // Calculate score
    final (matching, total) = countMatchingEdges(_selectedTile!, position);
    _lastPlacementResult = currentScore.addTilePlacement(
      matchingEdges: matching,
      totalAdjacentTiles: total,
    );

    // Place the tile
    board[position] = _selectedTile!;
    currentPlayer.removeTile(_selectedTile!);

    // Update board boundaries
    if (position.row < _minRow) _minRow = position.row;
    if (position.row > _maxRow) _maxRow = position.row;
    if (position.col < _minCol) _minCol = position.col;
    if (position.col > _maxCol) _maxCol = position.col;

    // Generate feedback message
    _generatePlacementMessage();

    // Handle mode-specific logic
    switch (mode) {
      case GameMode.colorDominoes:
        _handleColorDominoesPlacement();
        break;
      case GameMode.freePlay:
        _handleFreePlayPlacement();
        break;
      case GameMode.guidedLearning:
        _handleGuidedLearningPlacement();
        break;
      case GameMode.cooperative:
        _handleCooperativePlacement();
        break;
      case GameMode.starterPuzzle:
        // Starter Puzzle uses its own screen, fallback to free play behavior
        _handleFreePlayPlacement();
        break;
      case GameMode.shapeBuilder:
        _handleShapeBuilderPlacement();
        break;
      case GameMode.geometricShapes:
        _handleGeometricShapesPlacement();
        break;
    }

    _selectedTile = null;
    _updatePositions();
    notifyListeners();
    return true;
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

  void _handleColorDominoesPlacement() {
    // Check for win
    if (currentPlayer.hasWon) {
      _winner = currentPlayer.name;
      _gameOver = true;
      _message = '🎉 ${currentPlayer.name} wins!';
      return;
    }

    // Extra turn for solid tiles
    if (_history.last.tile.isSolid) {
      _message = '${_message ?? ''} Extra turn!';
    } else {
      _nextTurn();
    }
  }

  void _handleFreePlayPlacement() {
    // Auto-draw a new tile if hand is getting low
    if (currentPlayer.hand.length < 3) {
      drawTile();
      drawTile();
    }

    // Rotate players if multiplayer
    if (players.length > 1) {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % players.length;
    }
  }

  void _handleGuidedLearningPlacement() {
    // Similar to free play but with encouragement
    if (currentPlayer.hand.length < 3) {
      drawTile();
      drawTile();
    }

    final result = _lastPlacementResult!;
    if (result.matchingEdges == 0 && board.length > 1) {
      _message = '${_message ?? ''}\nTry matching the colors next time!';
    }

    if (players.length > 1) {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % players.length;
    }
  }

  void _handleCooperativePlacement() {
    // Check cooperative goal (e.g., build a certain size carpet)
    if (board.length >= 20) {
      _gameOver = true;
      _message = '🎉 Amazing! You built a beautiful carpet together!';
      return;
    }

    // Refill hand
    if (currentPlayer.hand.length < 3) {
      drawTile();
      drawTile();
    }

    // Next player
    _currentPlayerIndex = (_currentPlayerIndex + 1) % players.length;
    _message = '${_message ?? ""}\n${currentPlayer.name}\'s turn!';
  }

  void _handleShapeBuilderPlacement() {
    // Don't show score feedback during placement
    _message = null;

    // Auto-draw a new tile if hand is getting low
    if (currentPlayer.hand.length < 3) {
      drawTile();
      drawTile();
    }

    // Rotate players if multiplayer
    if (players.length > 1) {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % players.length;
    }
  }

  void _handleGeometricShapesPlacement() {
    // Check if current shape goal is complete
    final shapeComplete = _checkGeometricShapeComplete();

    if (shapeComplete) {
      final currentShape = _getCurrentShapeName();
      final nextShape = _getNextShapeName();
      if (nextShape != null) {
        _message = '✓ $currentShape complete! Now build a $nextShape!';
      } else {
        _gameOver = true;
        _message = '🎉 Amazing! You completed all geometric shapes!';
      }
    } else {
      // Show progress message
      final tilesNeeded = _getTilesNeededForCurrentShape();
      if (tilesNeeded > 0) {
        _message = 'Place ${tilesNeeded} more tile${tilesNeeded == 1 ? '' : 's'} to complete the shape!';
      }
    }

    // Auto-draw a new tile if hand is getting low
    if (currentPlayer.hand.length < 4) {
      drawTile();
      drawTile();
    }

    // Rotate players if multiplayer
    if (players.length > 1) {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % players.length;
    }
  }

  /// Check if the current geometric shape goal is complete.
  bool _checkGeometricShapeComplete() {
    final tilesPlaced = board.length;
    // Shapes: 2x2 square (4), 3x2 rectangle (6), L-shape (5), T-shape (4), 3x3 square (9)
    if (tilesPlaced < 4) return false;

    // Check for 2x2 square first
    if (tilesPlaced >= 4 && tilesPlaced < 6) {
      return _isSquare(2);
    }
    // Check for 3x2 rectangle
    if (tilesPlaced >= 6 && tilesPlaced < 9) {
      return _isRectangle(3, 2) || _isRectangle(2, 3);
    }
    // Check for 3x3 square
    if (tilesPlaced >= 9) {
      return _isSquare(3);
    }
    return false;
  }

  bool _isSquare(int size) {
    if (board.length < size * size) return false;

    // Find the bounding box
    final rows = board.keys.map((p) => p.row).toSet();
    final cols = board.keys.map((p) => p.col).toSet();

    if (rows.length != size || cols.length != size) return false;

    final minR = rows.reduce((a, b) => a < b ? a : b);
    final minC = cols.reduce((a, b) => a < b ? a : b);

    // Check all positions are filled
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (!board.containsKey(BoardPosition(minR + r, minC + c))) {
          return false;
        }
      }
    }
    return true;
  }

  bool _isRectangle(int width, int height) {
    if (board.length < width * height) return false;

    final rows = board.keys.map((p) => p.row).toSet();
    final cols = board.keys.map((p) => p.col).toSet();

    if (rows.length != height || cols.length != width) return false;

    final minR = rows.reduce((a, b) => a < b ? a : b);
    final minC = cols.reduce((a, b) => a < b ? a : b);

    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        if (!board.containsKey(BoardPosition(minR + r, minC + c))) {
          return false;
        }
      }
    }
    return true;
  }

  String _getCurrentShapeName() {
    final tilesPlaced = board.length;
    if (tilesPlaced < 4) return '2×2 Square';
    if (tilesPlaced < 6) return '2×2 Square';
    if (tilesPlaced < 9) return '3×2 Rectangle';
    return '3×3 Square';
  }

  String? _getNextShapeName() {
    final tilesPlaced = board.length;
    if (tilesPlaced < 4) return null; // Still on first shape
    if (tilesPlaced < 6) return '3×2 Rectangle';
    if (tilesPlaced < 9) return '3×3 Square';
    return null; // All complete
  }

  int _getTilesNeededForCurrentShape() {
    final tilesPlaced = board.length;
    if (tilesPlaced < 4) return 4 - tilesPlaced;
    if (tilesPlaced < 6) return 6 - tilesPlaced;
    if (tilesPlaced < 9) return 9 - tilesPlaced;
    return 0;
  }

  void _nextTurn() {
    _currentPlayerIndex = (_currentPlayerIndex + 1) % players.length;

    // Check if current player can make any move
    bool canMakeMove = false;
    for (final tile in currentPlayer.hand) {
      CarpetTile rotatedTile = tile;
      for (int r = 0; r < 4; r++) {
        if (getValidPositions(rotatedTile).isNotEmpty) {
          canMakeMove = true;
          break;
        }
        rotatedTile = rotatedTile.rotateClockwise();
      }
      if (canMakeMove) break;
    }

    if (!canMakeMove) {
      _message = "${currentPlayer.name} cannot play - skipping turn";
      _nextTurn();
    }
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

  /// Remove a tile from the board and return it to the current player's hand.
  void removeTileFromBoard(BoardPosition position) {
    final tile = board[position];
    if (tile == null) return;

    // Remove from history if it exists
    _history.removeWhere((action) => action.position == position);

    board.remove(position);
    currentPlayer.addTile(tile);

    // Recalculate boundaries
    _recalculateBoundaries();
    _updatePositions();
    _message = 'Tile returned to hand';
    notifyListeners();
  }

  /// Use a clue to highlight a valid placement for the selected tile.
  /// Returns true if a clue was available, false otherwise.
  bool useClue() {
    if (_selectedTile == null) {
      _message = 'Select a tile first!';
      notifyListeners();
      return false;
    }

    // Find a valid position with good matching
    BoardPosition? bestPosition;
    int bestMatches = -1;

    for (final pos in _allAdjacentPositions) {
      if (canPlaceTile(_selectedTile!, pos)) {
        final (matching, _) = countMatchingEdges(_selectedTile!, pos);
        if (matching > bestMatches) {
          bestMatches = matching;
          bestPosition = pos;
        }
      }
    }

    if (bestPosition != null) {
      _cluesUsed++;
      // Deduct points for using a clue
      currentScore.deductPoints(cluePointPenalty);
      _message = 'Hint: Try the highlighted position! (-$cluePointPenalty points)';
      // The valid positions will be highlighted in the UI
      notifyListeners();
      return true;
    } else {
      _message = 'No valid placement found. Try rotating the tile!';
      notifyListeners();
      return false;
    }
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
    _cluesUsed = 0;

    score.reset();
    for (final ps in playerScores) {
      ps.reset();
    }

    _nextTileId = 0;
    _tilePool.clear();

    // Deal new tiles based on mode
    final tilesPerPlayer = mode == GameMode.colorDominoes ? 6 : 8;
    for (final player in players) {
      player.hand.clear();
      for (int i = 0; i < tilesPerPlayer; i++) {
        player.addTile(CarpetTile.generateRandom('tile_${_nextTileId++}'));
      }
    }

    if (mode != GameMode.colorDominoes) {
      _refillTilePool();
    }

    _updatePositions();
    notifyListeners();
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
