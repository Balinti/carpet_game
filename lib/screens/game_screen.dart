import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../models/models.dart';
import '../widgets/game_board.dart';
import '../widgets/player_hand.dart';

/// Main game screen for Color Dominoes.
class GameScreen extends StatefulWidget {
  final int playerCount;

  const GameScreen({
    super.key,
    this.playerCount = 2,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;

  @override
  void initState() {
    super.initState();
    _gameState = GameState.newGame(widget.playerCount);
    _gameState.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    _gameState.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    setState(() {});
  }

  void _selectTile(CarpetTile tile) {
    if (_gameState.selectedTile?.id == tile.id) {
      _gameState.selectTile(null);
    } else {
      _gameState.selectTile(tile);
    }
  }

  void _rotateTile() {
    _gameState.rotateSelectedTile();
  }

  void _placeTile(BoardPosition position) {
    _gameState.placeTile(position);
  }

  void _restartGame() {
    _gameState.restart();
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Color Dominoes Rules'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to Play:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Each player starts with 6 tiles.'),
              SizedBox(height: 4),
              Text('2. Take turns placing tiles on the board.'),
              SizedBox(height: 4),
              Text('3. Tiles must match colors on touching edges.'),
              SizedBox(height: 4),
              Text('4. First player to place all tiles wins!'),
              SizedBox(height: 16),
              Text(
                'Special Rules:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Solid-colored tiles grant an extra turn.'),
              SizedBox(height: 4),
              Text('• Tap a tile to select it.'),
              SizedBox(height: 4),
              Text('• Double-tap or use the Rotate button to rotate.'),
              SizedBox(height: 4),
              Text('• Tap a valid position (green) to place.'),
              SizedBox(height: 4),
              Text('• Or drag and drop tiles onto the board.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Dominoes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRulesDialog,
            tooltip: 'Rules',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartGame,
            tooltip: 'New Game',
          ),
        ],
      ),
      body: Column(
        children: [
          // Message bar
          if (_gameState.message != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: _gameState.gameOver
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_gameState.gameOver)
                    const Icon(Icons.celebration, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _gameState.message!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: _gameState.gameOver
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Game board
          Expanded(
            flex: 3,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: GameBoard(
                gameState: _gameState,
                onPositionTap: _placeTile,
              ),
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Player hands
          Expanded(
            flex: 2,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Current player's hand
                    PlayerHand(
                      player: _gameState.currentPlayer,
                      selectedTile: _gameState.selectedTile,
                      isCurrentPlayer: true,
                      onTileSelected: _selectTile,
                      onRotate: _rotateTile,
                    ),
                    const SizedBox(height: 12),
                    // Other players (collapsed view)
                    ...List.generate(_gameState.players.length, (index) {
                      if (index == _gameState.currentPlayerIndex) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PlayerHand(
                          player: _gameState.players[index],
                          isCurrentPlayer: false,
                          tileSize: 50,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Game over overlay
      floatingActionButton: _gameState.gameOver
          ? FloatingActionButton.extended(
              onPressed: _restartGame,
              icon: const Icon(Icons.replay),
              label: const Text('Play Again'),
            )
          : null,
    );
  }
}
