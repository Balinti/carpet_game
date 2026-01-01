import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../l10n/l10n.dart';
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
      case GameMode.starterPuzzle:
        _gameState = GameState.newFreePlay(playerCount: 1);
        break;
      case GameMode.square2x2:
        _gameState = GameState.newSquare2x2();
        break;
      case GameMode.square3x3:
        _gameState = GameState.newSquare3x3();
        break;
      case GameMode.square4x4:
        _gameState = GameState.newSquare4x4();
        break;
      case GameMode.squareProgression:
        _gameState = GameState.newSquareProgression();
        break;
      case GameMode.geometricShapes:
        _gameState = GameState.newGeometricShapes();
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

  void _rotateHandTile(CarpetTile tile) {
    _gameState.rotateHandTile(tile);
  }

  void _placeTile(BoardPosition position) {
    _gameState.placeTile(position);
  }

  void _rotatePlacedTile(BoardPosition position) {
    _gameState.rotatePlacedTile(position);
  }

  void _swapTiles(BoardPosition from, BoardPosition to) {
    _gameState.swapTiles(from, to);
  }

  void _replaceTile(CarpetTile handTile, BoardPosition position) {
    _gameState.replaceTile(handTile, position);
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

  String _getModeTitle(AppLocalizations l10n) {
    switch (widget.mode) {
      case GameMode.colorDominoes:
        return l10n.colorDominoes;
      case GameMode.freePlay:
        return l10n.freePlay;
      case GameMode.guidedLearning:
        return l10n.learningMode;
      case GameMode.cooperative:
        return l10n.buildTogether;
      case GameMode.starterPuzzle:
        return l10n.starterPuzzle;
      case GameMode.square2x2:
        return '2×2 Square';
      case GameMode.square3x3:
        return '3×3 Square';
      case GameMode.square4x4:
        return '4×4 Square';
      case GameMode.squareProgression:
        return 'Progression';
      case GameMode.geometricShapes:
        return 'Geometric Shapes';
    }
  }

  void _showRulesDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_getModeTitle(l10n)} - ${l10n.rules}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _getRulesContent(l10n),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.gotIt),
          ),
        ],
      ),
    );
  }

  List<Widget> _getRulesContent(AppLocalizations l10n) {
    switch (widget.mode) {
      case GameMode.colorDominoes:
        return [
          Text(l10n.howToPlay, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.rule1Tiles),
          const SizedBox(height: 4),
          Text(l10n.rule2Turns),
          const SizedBox(height: 4),
          Text(l10n.rule3Match),
          const SizedBox(height: 4),
          Text(l10n.rule4Win),
          const SizedBox(height: 16),
          Text(l10n.specialRules, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.solidTileExtra),
        ];
      case GameMode.freePlay:
        return [
          Text(l10n.freePlayMode, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.noRulesPlace),
          const SizedBox(height: 4),
          Text(l10n.createPatterns),
          const SizedBox(height: 4),
          Text(l10n.earnPointsMatching),
          const SizedBox(height: 4),
          Text(l10n.drawMoreTiles),
          const SizedBox(height: 4),
          Text(l10n.useUndoExperiment),
        ];
      case GameMode.guidedLearning:
        return [
          Text(l10n.learningModeTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.placeAnywhere),
          const SizedBox(height: 4),
          Text(l10n.greenEdgesMatch),
          const SizedBox(height: 4),
          Text(l10n.orangeEdgesDont),
          const SizedBox(height: 4),
          Text(l10n.earnMoreMatching),
          const SizedBox(height: 4),
          Text(l10n.learnNoPressure),
        ];
      case GameMode.cooperative:
        return [
          Text(l10n.buildTogetherTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.workAsTeam),
          const SizedBox(height: 4),
          Text(l10n.takeTurnsPlacing),
          const SizedBox(height: 4),
          Text(l10n.tilesMustMatch),
          const SizedBox(height: 4),
          Text(l10n.goalBuild20),
          const SizedBox(height: 4),
          Text(l10n.everyoneShares),
        ];
      case GameMode.starterPuzzle:
        return [
          Text(l10n.starterPuzzleRules, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.rule1Place9),
          const SizedBox(height: 4),
          Text(l10n.rule2MatchColors),
          const SizedBox(height: 4),
          Text(l10n.rule3Rotate),
          const SizedBox(height: 4),
          Text(l10n.rule4Timer),
        ];
      case GameMode.square2x2:
      case GameMode.square3x3:
      case GameMode.square4x4:
        return [
          const Text('Square Building', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('• Place tiles to form a complete square'),
          const SizedBox(height: 4),
          const Text('• Tiles must be next to each other'),
          const SizedBox(height: 4),
          const Text('• Complete the square to win!'),
        ];
      case GameMode.squareProgression:
        return [
          const Text('Progression Mode', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('• Build a 2×2 square first'),
          const SizedBox(height: 4),
          const Text('• Then build a 3×3 square'),
          const SizedBox(height: 4),
          const Text('• Finally build a 4×4 square to win!'),
        ];
      case GameMode.geometricShapes:
        return [
          const Text('Geometric Shapes', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('• Build different geometric shapes'),
          const SizedBox(height: 4),
          const Text('• Start with a 2×2 square'),
          const SizedBox(height: 4),
          const Text('• Then build a 3×3 square to win!'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getModeTitle(l10n)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Undo button (non-competitive modes)
          if (widget.mode != GameMode.colorDominoes && _gameState.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undo,
              tooltip: l10n.undo,
            ),
          // Draw tile button (non-competitive modes)
          if (widget.mode != GameMode.colorDominoes)
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              onPressed: _drawTile,
              tooltip: l10n.drawTile,
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRulesDialog,
            tooltip: l10n.rules,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartGame,
            tooltip: l10n.newGame,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Score bar
              _buildScoreBar(l10n),

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
                    onTileRotate: _rotatePlacedTile,
                    onTileSwap: _swapTiles,
                    onTileReplace: _replaceTile,
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
                          isCurrentPlayer: true,
                          onTileTap: _rotateHandTile,
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
              label: Text(l10n.playAgain),
            )
          : null,
    );
  }

  Widget _buildScoreBar(AppLocalizations l10n) {
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
                l10n.points,
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
