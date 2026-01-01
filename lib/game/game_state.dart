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

  // Target grid size for square modes (0 = no fixed grid)
  int _targetGridSize = 0;

  // Board boundaries (dynamic, expands as tiles are placed)
  int _minRow = 0;
  int _maxRow = 0;
  int _minCol = 0;
  int _maxCol = 0;

  // Undo support
  final List<_GameAction> _history = [];

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
  int get targetGridSize => _targetGridSize;

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

  /// Initialize a new 2x2 Square game.
  static GameState newSquare2x2({int playerCount = 1}) {
    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: 'Builder'),
    );
    final state = GameState(mode: GameMode.square2x2, players: players);
    state._targetGridSize = 2;
    // Give all 36 build tiles
    final buildTiles = CarpetTile.getBuildTiles();
    for (final tile in buildTiles) {
      players[0].addTile(tile.copyWithId('tile_${state._nextTileId++}'));
    }
    state._updatePositions();
    state._message = 'Fill the 2×2 grid!';
    return state;
  }

  /// Initialize a new 3x3 Square game.
  static GameState newSquare3x3({int playerCount = 1}) {
    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: 'Builder'),
    );
    final state = GameState(mode: GameMode.square3x3, players: players);
    state._targetGridSize = 3;
    // Give all 36 build tiles
    final buildTiles = CarpetTile.getBuildTiles();
    for (final tile in buildTiles) {
      players[0].addTile(tile.copyWithId('tile_${state._nextTileId++}'));
    }
    state._updatePositions();
    state._message = 'Fill the 3×3 grid!';
    return state;
  }

  /// Initialize a new 4x4 Square game.
  static GameState newSquare4x4({int playerCount = 1}) {
    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: 'Builder'),
    );
    final state = GameState(mode: GameMode.square4x4, players: players);
    state._targetGridSize = 4;
    // Give all 36 build tiles
    final buildTiles = CarpetTile.getBuildTiles();
    for (final tile in buildTiles) {
      players[0].addTile(tile.copyWithId('tile_${state._nextTileId++}'));
    }
    state._updatePositions();
    state._message = 'Fill the 4×4 grid!';
    return state;
  }

  /// Initialize a new Square Progression game.
  static GameState newSquareProgression({int playerCount = 1}) {
    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: 'Builder'),
    );
    final state = GameState(mode: GameMode.squareProgression, players: players);
    // Give all 36 build tiles
    final buildTiles = CarpetTile.getBuildTiles();
    for (final tile in buildTiles) {
      players[0].addTile(tile.copyWithId('tile_${state._nextTileId++}'));
    }
    state._updatePositions();
    state._message = 'Start with a 2×2 square!';
    return state;
  }

  /// Initialize a new Geometric Shapes game.
  static GameState newGeometricShapes({int playerCount = 1}) {
    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: 'Builder'),
    );
    final state = GameState(mode: GameMode.geometricShapes, players: players);
    // Give all 36 build tiles
    final buildTiles = CarpetTile.getBuildTiles();
    for (final tile in buildTiles) {
      players[0].addTile(tile.copyWithId('tile_${state._nextTileId++}'));
    }
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

    // Fixed grid modes allow placing anywhere in the grid
    if (_targetGridSize > 0) {
      return position.row >= 0 && position.row < _targetGridSize &&
             position.col >= 0 && position.col < _targetGridSize;
    }

    // Free play and guided learning allow any adjacent placement
    if (mode == GameMode.freePlay || mode == GameMode.guidedLearning) {
      if (board.isEmpty) return true;
      return position.neighbors.any((n) => board.containsKey(n));
    }

    // Competitive and cooperative require matching
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
        _handleFreePlayPlacement();
        break;
      case GameMode.square2x2:
        _handleSquarePlacement(2);
        break;
      case GameMode.square3x3:
        _handleSquarePlacement(3);
        break;
      case GameMode.square4x4:
        _handleSquarePlacement(4);
        break;
      case GameMode.squareProgression:
        _handleSquareProgressionPlacement();
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

  /// Rotate a tile that is already placed on the board.
  void rotatePlacedTile(BoardPosition position) {
    final tile = board[position];
    if (tile == null) return;

    board[position] = tile.rotateClockwise();

    // Update message with current status
    if (_targetGridSize > 0) {
      final target = _targetGridSize * _targetGridSize;
      final tilesPlaced = board.length;
      final tilesNeeded = target - tilesPlaced;
      if (tilesNeeded > 0) {
        _message = '$tilesNeeded more tile${tilesNeeded == 1 ? '' : 's'} to go!';
      }
    }

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

    // Update message with current status
    if (_targetGridSize > 0) {
      final target = _targetGridSize * _targetGridSize;
      final tilesPlaced = board.length;
      final tilesNeeded = target - tilesPlaced;
      if (tilesNeeded > 0) {
        _message = '$tilesNeeded more tile${tilesNeeded == 1 ? '' : 's'} to go!';
      }
    }

    notifyListeners();
  }

  /// Replace a tile on the board with a tile from hand.
  /// The board tile goes back to hand, the hand tile goes to board.
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

    // Update message with current status
    if (_targetGridSize > 0) {
      final target = _targetGridSize * _targetGridSize;
      final tilesPlaced = board.length;
      final tilesNeeded = target - tilesPlaced;
      if (tilesNeeded > 0) {
        _message = '$tilesNeeded more tile${tilesNeeded == 1 ? '' : 's'} to go!';
      }
    }

    _updatePositions();
    notifyListeners();
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

  void _handleSquarePlacement(int size) {
    final target = size * size;
    final tilesPlaced = board.length;
    final tilesNeeded = target - tilesPlaced;

    if (tilesNeeded <= 0) {
      final mismatches = _countMismatches();
      _gameOver = true;
      if (mismatches == 0) {
        _message = '🎉 Perfect! All colors match!';
      } else {
        _message = '✓ Grid filled! $mismatches mismatch${mismatches == 1 ? '' : 'es'} - try again for perfect!';
      }
    } else {
      final mismatches = _countMismatches();
      if (mismatches > 0) {
        _message = '$tilesNeeded to go • $mismatches mismatch${mismatches == 1 ? '' : 'es'}';
      } else {
        _message = '$tilesNeeded more tile${tilesNeeded == 1 ? '' : 's'} to go!';
      }
    }

    if (currentPlayer.hand.length < 4) {
      drawTile();
      drawTile();
    }
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

  int _progressionStage = 0;

  void _handleSquareProgressionPlacement() {
    final tilesPlaced = board.length;

    if (_progressionStage == 0) {
      if (tilesPlaced >= 4 && _isSquare(2)) {
        _progressionStage = 1;
        _message = '✓ 2×2 complete! Now build a 3×3!';
        board.clear();
        _recalculateBoundaries();
      } else {
        final needed = 4 - tilesPlaced;
        if (needed > 0) _message = 'Place $needed more for 2×2!';
      }
    } else if (_progressionStage == 1) {
      if (tilesPlaced >= 9 && _isSquare(3)) {
        _progressionStage = 2;
        _message = '✓ 3×3 complete! Now build a 4×4!';
        board.clear();
        _recalculateBoundaries();
      } else {
        final needed = 9 - tilesPlaced;
        if (needed > 0) _message = 'Place $needed more for 3×3!';
      }
    } else {
      if (tilesPlaced >= 16 && _isSquare(4)) {
        _gameOver = true;
        _message = '🎉 Amazing! You completed the progression!';
      } else {
        final needed = 16 - tilesPlaced;
        if (needed > 0) _message = 'Place $needed more for 4×4!';
      }
    }

    if (currentPlayer.hand.length < 4) {
      drawTile();
      drawTile();
    }
  }

  void _handleGeometricShapesPlacement() {
    final tilesPlaced = board.length;

    if (tilesPlaced >= 4 && _isSquare(2)) {
      if (tilesPlaced >= 9 && _isSquare(3)) {
        _gameOver = true;
        _message = '🎉 Amazing! You completed all shapes!';
      } else {
        _message = 'Now build a 3×3 square!';
      }
    } else {
      final needed = 4 - tilesPlaced;
      if (needed > 0) _message = 'Place $needed more for 2×2!';
    }

    if (currentPlayer.hand.length < 4) {
      drawTile();
      drawTile();
    }
  }

  bool _isSquare(int size) {
    if (board.length < size * size) return false;
    final rows = board.keys.map((p) => p.row).toSet();
    final cols = board.keys.map((p) => p.col).toSet();
    if (rows.length != size || cols.length != size) return false;
    final minR = rows.reduce((a, b) => a < b ? a : b);
    final minC = cols.reduce((a, b) => a < b ? a : b);
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (!board.containsKey(BoardPosition(minR + r, minC + c))) return false;
      }
    }
    return true;
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
