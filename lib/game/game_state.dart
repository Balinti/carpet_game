import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Represents the state of a Color Dominoes game.
class GameState extends ChangeNotifier {
  final List<Player> players;
  final Map<BoardPosition, CarpetTile> board;

  int _currentPlayerIndex;
  CarpetTile? _selectedTile;
  String? _winner;
  bool _gameOver;
  String? _message;
  List<BoardPosition> _validPositions;

  // Board boundaries (dynamic, expands as tiles are placed)
  int _minRow = 0;
  int _maxRow = 0;
  int _minCol = 0;
  int _maxCol = 0;

  GameState({
    required this.players,
    Map<BoardPosition, CarpetTile>? initialBoard,
  })  : board = initialBoard ?? {},
        _currentPlayerIndex = 0,
        _gameOver = false,
        _validPositions = [];

  // Getters
  Player get currentPlayer => players[_currentPlayerIndex];
  int get currentPlayerIndex => _currentPlayerIndex;
  CarpetTile? get selectedTile => _selectedTile;
  String? get winner => _winner;
  bool get gameOver => _gameOver;
  String? get message => _message;
  List<BoardPosition> get validPositions => _validPositions;

  int get minRow => _minRow;
  int get maxRow => _maxRow;
  int get minCol => _minCol;
  int get maxCol => _maxCol;

  /// Initialize a new game with the given number of players.
  static GameState newGame(int playerCount) {
    if (playerCount < 2 || playerCount > 4) {
      throw ArgumentError('Player count must be between 2 and 4');
    }

    final players = List.generate(
      playerCount,
      (i) => Player(id: 'player_$i', name: 'Player ${i + 1}'),
    );

    // Deal 6 tiles to each player
    int tileId = 0;
    for (final player in players) {
      for (int i = 0; i < 6; i++) {
        player.addTile(CarpetTile.generateRandom('tile_${tileId++}'));
      }
    }

    final state = GameState(players: players);
    state._updateValidPositions();
    return state;
  }

  /// Select a tile from the current player's hand.
  void selectTile(CarpetTile? tile) {
    _selectedTile = tile;
    _message = null;
    _updateValidPositions();
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
      _updateValidPositions();
      notifyListeners();
    }
  }

  /// Check if a tile can be placed at a position.
  bool canPlaceTile(CarpetTile tile, BoardPosition position) {
    // If board is empty, can place anywhere
    if (board.isEmpty) {
      return true;
    }

    // Position must be empty
    if (board.containsKey(position)) {
      return false;
    }

    // Position must be adjacent to at least one existing tile
    bool hasAdjacentTile = false;
    bool allEdgesMatch = true;

    // Check each direction
    final neighbors = [
      (position.up, 2, 0),    // Neighbor above: their bottom edge matches our top
      (position.right, 3, 1), // Neighbor right: their left edge matches our right
      (position.down, 0, 2),  // Neighbor below: their top edge matches our bottom
      (position.left, 1, 3),  // Neighbor left: their right edge matches our left
    ];

    for (final (neighborPos, neighborEdge, ourEdge) in neighbors) {
      final neighbor = board[neighborPos];
      if (neighbor != null) {
        hasAdjacentTile = true;
        if (neighbor.getEdgeColor(neighborEdge) != tile.getEdgeColor(ourEdge)) {
          allEdgesMatch = false;
          break;
        }
      }
    }

    return hasAdjacentTile && allEdgesMatch;
  }

  /// Get all valid positions for the selected tile.
  List<BoardPosition> getValidPositions(CarpetTile tile) {
    if (board.isEmpty) {
      return [const BoardPosition(0, 0)];
    }

    final validPositions = <BoardPosition>[];

    // Check all positions adjacent to existing tiles
    final positionsToCheck = <BoardPosition>{};
    for (final pos in board.keys) {
      for (final neighbor in pos.neighbors) {
        if (!board.containsKey(neighbor)) {
          positionsToCheck.add(neighbor);
        }
      }
    }

    for (final pos in positionsToCheck) {
      if (canPlaceTile(tile, pos)) {
        validPositions.add(pos);
      }
    }

    return validPositions;
  }

  void _updateValidPositions() {
    if (_selectedTile != null) {
      _validPositions = getValidPositions(_selectedTile!);
    } else {
      _validPositions = [];
    }
  }

  /// Place the selected tile at a position.
  bool placeTile(BoardPosition position) {
    if (_selectedTile == null) {
      _message = 'No tile selected';
      notifyListeners();
      return false;
    }

    if (!canPlaceTile(_selectedTile!, position)) {
      _message = 'Invalid placement';
      notifyListeners();
      return false;
    }

    // Place the tile
    board[position] = _selectedTile!;
    currentPlayer.removeTile(_selectedTile!);

    // Update board boundaries
    if (position.row < _minRow) _minRow = position.row;
    if (position.row > _maxRow) _maxRow = position.row;
    if (position.col < _minCol) _minCol = position.col;
    if (position.col > _maxCol) _maxCol = position.col;

    // Check for win condition
    if (currentPlayer.hasWon) {
      _winner = currentPlayer.name;
      _gameOver = true;
      _message = '${currentPlayer.name} wins!';
      _selectedTile = null;
      _validPositions = [];
      notifyListeners();
      return true;
    }

    // Check for extra turn (solid colored tile)
    final placedSolid = _selectedTile!.isSolid;

    _selectedTile = null;

    if (placedSolid) {
      _message = '${currentPlayer.name} placed a solid tile - Extra turn!';
    } else {
      // Next player's turn
      _nextTurn();
    }

    _updateValidPositions();
    notifyListeners();
    return true;
  }

  void _nextTurn() {
    _currentPlayerIndex = (_currentPlayerIndex + 1) % players.length;
    _message = "${currentPlayer.name}'s turn";

    // Check if current player can make any move
    bool canMakeMove = false;
    for (final tile in currentPlayer.hand) {
      // Check all 4 rotations
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
      // Skip to next player
      _nextTurn();
    }
  }

  /// Restart the game with same players.
  void restart() {
    board.clear();
    _currentPlayerIndex = 0;
    _selectedTile = null;
    _winner = null;
    _gameOver = false;
    _message = null;
    _validPositions = [];
    _minRow = 0;
    _maxRow = 0;
    _minCol = 0;
    _maxCol = 0;

    // Deal new tiles
    int tileId = 0;
    for (final player in players) {
      player.hand.clear();
      for (int i = 0; i < 6; i++) {
        player.addTile(CarpetTile.generateRandom('tile_${tileId++}'));
      }
    }

    _updateValidPositions();
    notifyListeners();
  }
}
