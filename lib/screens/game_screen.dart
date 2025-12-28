import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../models/models.dart';
import '../widgets/game_board.dart';
import '../widgets/player_hand.dart';

/// Main game screen supporting all game modes.
class GameScreen extends StatefulWidget {
  final GameMode mode;
  final int playerCount;

  const GameScreen({
    super.key,
    required this.mode,
    this.playerCount = 2,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameState _gameState;
  late AnimationController _celebrationController;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _initGameState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _gameState.addListener(_onGameStateChanged);
  }

  void _initGameState() {
    switch (widget.mode) {
      case GameMode.colorDominoes:
        _gameState = GameState.newColorDominoes(widget.playerCount);
        break;
      case GameMode.freePlay:
        _gameState = GameState.newFreePlay(playerCount: widget.playerCount);
        break;
      case GameMode.guidedLearning:
        _gameState = GameState.newGuidedLearning(playerCount: widget.playerCount);
        break;
      case GameMode.cooperative:
        _gameState = GameState.newCooperative(widget.playerCount);
        break;
    }
  }

  @override
  void dispose() {
    _gameState.removeListener(_onGameStateChanged);
    _celebrationController.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    setState(() {});

    // Trigger celebration animation for achievements
    if (_gameState.lastPlacementResult?.hasAchievements == true) {
      _showCelebration = true;
      _celebrationController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _showCelebration = false);
        }
      });
    }
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

  void _undo() {
    _gameState.undo();
  }

  void _drawTile() {
    _gameState.drawTile();
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.mode.displayName} Rules'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _getRulesContent(),
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

  List<Widget> _getRulesContent() {
    switch (widget.mode) {
      case GameMode.colorDominoes:
        return const [
          Text('How to Play:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('1. Each player starts with 6 tiles.'),
          SizedBox(height: 4),
          Text('2. Take turns placing tiles on the board.'),
          SizedBox(height: 4),
          Text('3. Tiles must match colors on touching edges.'),
          SizedBox(height: 4),
          Text('4. First player to place all tiles wins!'),
          SizedBox(height: 16),
          Text('Special Rules:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('• Solid-colored tiles grant an extra turn.'),
        ];
      case GameMode.freePlay:
        return const [
          Text('Free Play Mode', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('• No rules - place tiles anywhere you like!'),
          SizedBox(height: 4),
          Text('• Create any pattern you can imagine.'),
          SizedBox(height: 4),
          Text('• Earn points for matching colors.'),
          SizedBox(height: 4),
          Text('• Draw more tiles whenever you need them.'),
          SizedBox(height: 4),
          Text('• Use Undo to experiment freely!'),
        ];
      case GameMode.guidedLearning:
        return const [
          Text('Learning Mode', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('• Place tiles anywhere next to existing tiles.'),
          SizedBox(height: 4),
          Text('• Green edges = colors match!'),
          SizedBox(height: 4),
          Text('• Orange edges = colors don\'t match yet.'),
          SizedBox(height: 4),
          Text('• Earn more points for matching colors.'),
          SizedBox(height: 4),
          Text('• Learn at your own pace - no pressure!'),
        ];
      case GameMode.cooperative:
        return const [
          Text('Build Together!', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('• Work as a team to build a beautiful carpet!'),
          SizedBox(height: 4),
          Text('• Take turns placing tiles.'),
          SizedBox(height: 4),
          Text('• Tiles must match colors on touching edges.'),
          SizedBox(height: 4),
          Text('• Goal: Build a carpet with 20 tiles!'),
          SizedBox(height: 4),
          Text('• Everyone shares the same score.'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.displayName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Undo button (non-competitive modes)
          if (widget.mode != GameMode.colorDominoes && _gameState.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undo,
              tooltip: 'Undo',
            ),
          // Draw tile button (non-competitive modes)
          if (widget.mode != GameMode.colorDominoes)
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              onPressed: _drawTile,
              tooltip: 'Draw Tile',
            ),
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
      body: Stack(
        children: [
          Column(
            children: [
              // Score bar
              _buildScoreBar(),

              // Message bar
              if (_gameState.message != null) _buildMessageBar(),

              // Game board
              Expanded(
                flex: 3,
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: GameBoard(
                    gameState: _gameState,
                    onPositionTap: _placeTile,
                    showMatchFeedback: widget.mode.showMatchFeedback,
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
                        PlayerHand(
                          player: _gameState.currentPlayer,
                          selectedTile: _gameState.selectedTile,
                          isCurrentPlayer: true,
                          onTileSelected: _selectTile,
                          onRotate: _rotateTile,
                        ),
                        if (_gameState.players.length > 1) ...[
                          const SizedBox(height: 12),
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Celebration overlay
          if (_showCelebration) _buildCelebrationOverlay(),
        ],
      ),

      // Game over button
      floatingActionButton: _gameState.gameOver
          ? FloatingActionButton.extended(
              onPressed: _restartGame,
              icon: const Icon(Icons.replay),
              label: const Text('Play Again'),
            )
          : null,
    );
  }

  Widget _buildScoreBar() {
    final score = _gameState.currentScore;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Stars
          Row(
            children: [
              ...List.generate(
                score.stars.clamp(0, 5),
                (i) => const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.star, color: Colors.amber, size: 24),
                ),
              ),
              if (score.stars == 0)
                Icon(Icons.star_border,
                    color: Colors.grey.shade400, size: 24),
            ],
          ),
          // Points
          Row(
            children: [
              Text(
                '${score.points}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                'points',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
          // Tiles placed
          Row(
            children: [
              const Icon(Icons.grid_view, size: 20),
              const SizedBox(width: 4),
              Text(
                '${score.tilesPlaced}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: _gameState.gameOver
          ? Theme.of(context).colorScheme.primaryContainer
          : (_gameState.lastPlacementResult?.isPerfectMatch == true
              ? Colors.green.withOpacity(0.2)
              : Theme.of(context).colorScheme.surfaceContainerHighest),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_gameState.gameOver)
            const Icon(Icons.celebration, size: 20)
          else if (_gameState.lastPlacementResult?.isPerfectMatch == true)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _gameState.message!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: _gameState.gameOver
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return IgnorePointer(
          child: Center(
            child: Transform.scale(
              scale: 1.0 + (_celebrationController.value * 0.5),
              child: Opacity(
                opacity: 1.0 - _celebrationController.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    _gameState.lastPlacementResult?.newAchievements.first ?? '',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
