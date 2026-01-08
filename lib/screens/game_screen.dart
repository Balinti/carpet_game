import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../widgets/game_board.dart';
import '../widgets/player_hand.dart';

/// Main game screen supporting Regular Flow and Shape Flow modes.
class GameScreen extends StatefulWidget {
  final GameMode mode;

  const GameScreen({
    super.key,
    required this.mode,
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
      case GameMode.regularFlow:
        _gameState = GameState.newRegularFlow();
        break;
      case GameMode.shapeFlow:
        _gameState = GameState.newShapeFlow();
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

  void _dropTile(CarpetTile tile, BoardPosition position) {
    _gameState.placeTileAt(tile, position);
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

  String _getModeTitle(AppLocalizations l10n) {
    switch (widget.mode) {
      case GameMode.regularFlow:
        return 'Level ${_gameState.currentLevel}';
      case GameMode.shapeFlow:
        return 'Shape Flow (${_gameState.completedShapeTypes.length}/7)';
    }
  }

  void _showRulesDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${widget.mode.displayName} - ${l10n.rules}'),
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
      case GameMode.regularFlow:
        return [
          const Text('Regular Flow', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('• Complete 12 levels of increasing difficulty'),
          const SizedBox(height: 4),
          const Text('• Fill the grid with tiles'),
          const SizedBox(height: 4),
          const Text('• Try to match all edge colors!'),
          const SizedBox(height: 12),
          const Text('Level Progression:', style: TextStyle(fontWeight: FontWeight.w600)),
          const Text('• Levels 1-3: 2×2 (same 36 pieces)'),
          const Text('• Levels 4-5: 3×3 (reset, then continue)'),
          const Text('• Levels 6-8: 3×3 (reset, use 3 times)'),
          const Text('• Levels 9-10: 4×4 (reset, then continue)'),
          const Text('• Level 11: 5×5'),
          const Text('• Level 12: 6×6 (all 36 pieces!)'),
        ];
      case GameMode.shapeFlow:
        return [
          const Text('Shape Flow Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Build 7 shapes AND fill the entire grid:'),
          const SizedBox(height: 8),
          const Text('Diamonds:', style: TextStyle(fontWeight: FontWeight.w600)),
          const Text('• Small: 2 tiles with matching seam'),
          const Text('• Large: 4 tiles (2×2) with center match'),
          const SizedBox(height: 4),
          const Text('Triangles:', style: TextStyle(fontWeight: FontWeight.w600)),
          const Text('• Small: 1 tile with 3-1 color split'),
          const Text('• Large: 3 tiles in L-shape, matching edges'),
          const SizedBox(height: 4),
          const Text('Rectangles:', style: TextStyle(fontWeight: FontWeight.w600)),
          const Text('• Small: 2 tiles with color stripe'),
          const Text('• Large: 3 tiles in line with stripe'),
          const SizedBox(height: 4),
          const Text('Arrows:', style: TextStyle(fontWeight: FontWeight.w600)),
          const Text('• 3+ tiles forming a pointed shape'),
          const SizedBox(height: 8),
          const Text('Small shapes use 2×2 grid, large shapes use 3×3!',
              style: TextStyle(fontStyle: FontStyle.italic)),
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
          // Undo button
          if (_gameState.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undo,
              tooltip: l10n.undo,
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
              // Info bar
              _buildInfoBar(l10n),

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
                    onTileDrop: _dropTile,
                    onTileRotate: _rotatePlacedTile,
                    onTileSwap: _swapTiles,
                    onTileReplace: _replaceTile,
                    showMatchFeedback: widget.mode.showMatchFeedback,
                  ),
                ),
              ),

              // Divider
              const Divider(height: 1),

              // Player hand
              Expanded(
                flex: 2,
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: PlayerHand(
                      player: _gameState.currentPlayer,
                      isCurrentPlayer: true,
                      onTileTap: _rotateHandTile,
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

  Widget _buildInfoBar(AppLocalizations l10n) {
    final score = _gameState.currentScore;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mode-specific info
          if (widget.mode == GameMode.regularFlow) ...[
            // Level info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Level ${_gameState.currentLevel}/12',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
            // Grid size
            Text(
              '${_gameState.targetGridSize}×${_gameState.targetGridSize}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            // Pieces remaining
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_gameState.currentPlayer.hand.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ] else ...[
            // Shape Flow info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_gameState.completedShapeTypes.length}/7 Shapes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
              ),
            ),
            // Current target
            if (_gameState.currentTargetShape != null)
              Text(
                _gameState.currentTargetShape!.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
              ),
            // Grid size
            Text(
              '${_gameState.targetGridSize}×${_gameState.targetGridSize}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
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
