import 'dart:async';

import 'package:flutter/material.dart';
import 'assessment_intro.dart';
import '../game/game_state.dart';
import '../game/practice_save.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../widgets/game_board.dart';
import '../widgets/visual_style.dart';
import '../telemetry.dart';
import '../sound_stub.dart' if (dart.library.js_interop) '../sound_web.dart';
import '../widgets/player_hand.dart';

/// Main game screen supporting Regular Flow and Shape Flow modes.
class GameScreen extends StatefulWidget {
  final GameMode mode;

  /// When set, play a single practice grid of this size (1-6).
  final int? practiceGridSize;

  /// Externally owned game (e.g. an assessment round). When set, the screen
  /// plays this state instead of creating its own, and does not dispose it.
  /// Swapping in a new instance (next round) is supported.
  final GameState? gameState;

  /// Called once each time the grid becomes solved (after the chime starts).
  final VoidCallback? onSolved;

  /// Show the restart icon (hidden in assessment so rounds can't be reset).
  final bool showRestart;

  /// Saved practice board to continue (see PracticeSave).
  final Map<String, dynamic>? resumeFrom;

  const GameScreen({
    super.key,
    required this.mode,
    this.practiceGridSize,
    this.gameState,
    this.onSolved,
    this.showRestart = true,
    this.resumeFrom,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
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

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gameState != null && widget.gameState != oldWidget.gameState) {
      _gameState.removeListener(_onGameStateChanged);
      if (oldWidget.gameState == null) _gameState.dispose();
      _gameState = widget.gameState!;
      _wasSolved = _gameState.confirmedSolved;
      _gameState.addListener(_onGameStateChanged);
    }
  }

  void _initGameState() {
    if (widget.gameState != null) {
      _gameState = widget.gameState!;
      return;
    }
    if (widget.practiceGridSize != null) {
      final resumed = widget.resumeFrom == null
          ? null
          : PracticeSave.restore(widget.resumeFrom!);
      Telemetry.log('practice_start',
          {'grid': widget.practiceGridSize, 'resumed': resumed != null});
      _gameState = resumed ?? GameState.newPractice(widget.practiceGridSize!);
      return;
    }
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
    if (widget.gameState == null) _gameState.dispose();
    _celebrationController.dispose();
    _throwBackTimer?.cancel();
    super.dispose();
  }

  bool _wasSolved = false;
  bool _wasFull = false;

  Timer? _throwBackTimer;

  void _onGameStateChanged() {
    setState(() {});
    // Wrong "I finished": show the red pieces briefly, then they drop back
    // into the Builder.
    if (_gameState.rejectedIds.isNotEmpty && _throwBackTimer == null) {
      _throwBackTimer = Timer(const Duration(milliseconds: 1400), () {
        _throwBackTimer = null;
        if (mounted) _gameState.throwBackRejected();
      });
    }
    // Free practice: keep the board so the player can come back later.
    if (widget.gameState == null && widget.practiceGridSize != null) {
      PracticeSave.save(_gameState);
    }

    // Success: chime + buzz once when the grid becomes full and all-matching.
    final solved = _gameState.confirmedSolved;
    if (solved && !_wasSolved) {
      playSuccess();
      Telemetry.log('grid_solved', {
        'grid': _gameState.targetGridSize,
        'mode': widget.practiceGridSize != null
            ? 'practice'
            : (widget.gameState != null ? 'assessment' : widget.mode.name),
      });
      widget.onSolved?.call();
    }
    _wasSolved = solved;

    // Full but not matching: log how many edges are wrong (diagnostics).
    final full = _gameState.showResult;
    if (full && !solved && !_wasFull) {
      Telemetry.log('grid_full_mismatch', {
        'grid': _gameState.targetGridSize,
        'boards': _gameState.boards,
        'mismatches': _gameState.mismatchCount,
      });
    }
    _wasFull = full;

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

  // Tap selects a piece (red frame); tap again to deselect.
  void _selectHandTile(CarpetTile tile) {
    final already = _gameState.selectedTile?.id == tile.id;
    _gameState.selectTile(already ? null : tile);
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

  void _goToPreviousLevel() {
    _gameState.goToPreviousLevel();
  }

  String _getModeTitle(AppLocalizations l10n) {
    switch (widget.mode) {
      case GameMode.regularFlow:
        if (widget.practiceGridSize != null) {
          return '${widget.practiceGridSize}×${widget.practiceGridSize}';
        }
        return 'Level ${_gameState.currentLevel}';
      case GameMode.shapeFlow:
        return 'Shape Flow (${_gameState.completedShapeTypes.length}/7)';
    }
  }

  /// Help: the same instructions screen (with examples) as before playing.
  void _showInstructions() {
    _gameState.recordHelpOpened();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AssessmentIntro(onStart: () => Navigator.pop(ctx)),
      ),
    );
  }

  // ignore: unused_element
  void _showRulesDialog() {
    final l10n = AppLocalizations.of(context);
    _gameState.recordHelpOpened();

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
          const Text('Regular Flow',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('• Complete 12 levels of increasing difficulty'),
          const SizedBox(height: 4),
          const Text('• Fill the grid with tiles'),
          const SizedBox(height: 4),
          const Text('• Try to match all edge colors!'),
          const SizedBox(height: 12),
          const Text('Level Progression:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const Text('• Levels 1-3: 2×2 (same 36 pieces)'),
          const Text('• Levels 4-5: 3×3 (reset, then continue)'),
          const Text('• Levels 6-8: 3×3 (reset, use 3 times)'),
          const Text('• Levels 9-10: 4×4 (reset, then continue)'),
          const Text('• Level 11: 5×5'),
          const Text('• Level 12: 6×6 (all 36 pieces!)'),
        ];
      case GameMode.shapeFlow:
        return [
          const Text('Shape Flow Challenge',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Build 7 shapes AND fill the entire grid:'),
          const SizedBox(height: 8),
          const Text('Diamonds:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const Text('• Small: 2 tiles with matching seam'),
          const Text('• Large: 4 tiles (2×2) with center match'),
          const SizedBox(height: 4),
          const Text('Triangles:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const Text('• Small: 1 tile with 3-1 color split'),
          const Text('• Large: 3 tiles in L-shape, matching edges'),
          const SizedBox(height: 4),
          const Text('Rectangles:',
              style: TextStyle(fontWeight: FontWeight.w600)),
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
    final st = VisualStyle.current;
    final bgColors = st.isClassic
        ? [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ]
        : st.boardBackground;
    final iconColor = st.isClassic
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : st.onTray;

    // Landscape, full screen: no app bar or info bar. Left: small
    // back/help/restart icons. Middle: the board and the big red buttons.
    // Right: the Builder with every piece visible.
    Widget smallIcon(IconData icon, VoidCallback onTap) => IconButton(
          icon: Icon(icon, color: iconColor),
          onPressed: onTap,
        );

    final portrait = _portrait;
    final icons = <Widget>[
      smallIcon(Icons.arrow_back, () => Navigator.maybePop(context)),
      if (_gameState.canGoToPreviousLevel)
        smallIcon(Icons.skip_previous, _goToPreviousLevel),
      smallIcon(Icons.help_outline, _showInstructions),
      if (widget.showRestart) smallIcon(Icons.refresh, _restartGame),
    ];
    final board = GameBoard(
      gameState: _gameState,
      onPositionTap: _placeTile,
      onTileDrop: _dropTile,
      onTileRotate: _rotatePlacedTile,
      onTileSelect: _gameState.selectBoardTile,
      onSelectedReturn: _gameState.returnTileToHand,
      onSelectedRotate: (pos, ccw) =>
          _gameState.rotatePlacedTile(pos, counterClockwise: ccw),
      onTileSwap: _swapTiles,
      onTileReplace: _replaceTile,
      showMatchFeedback: widget.mode.showMatchFeedback,
    );
    final hand = Padding(
      padding: const EdgeInsets.all(6),
      child: PlayerHand(
        player: _gameState.currentPlayer,
        isCurrentPlayer: true,
        onTileTap: _selectHandTile,
        selectedTileId: _gameState.selectedTile?.id,
        onReturnFromBoard: _gameState.returnTileToHand,
        onTileDragStart: _gameState.pickUpTile,
        onTileDragCancel: _gameState.dropCancelled,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: portrait
              // Phone held upright: icons on top, board, big buttons in a
              // row, the Builder below.
              ? Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: icons,
                    ),
                    Expanded(flex: 5, child: board),
                    _buildControlStrip(vertical: false),
                    Expanded(flex: 4, child: hand),
                  ],
                )
              : Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: icons,
                    ),
                    Expanded(flex: 3, child: board),
                    _buildControlStrip(vertical: true),
                    Expanded(flex: 2, child: hand),
                  ],
                ),
        ),
      ),
      floatingActionButton: _gameState.gameOver
          ? FloatingActionButton(
              onPressed: _restartGame,
              child: const Icon(Icons.replay),
            )
          : null,
    );
  }

  bool get _portrait {
    final size = MediaQuery.sizeOf(context);
    return size.height > size.width;
  }

  /// Big finger-size buttons acting on the red (selected) board piece:
  /// rotate left, rotate right, back to the Builder.
  Widget _buildControlStrip({required bool vertical}) {
    final pos = _gameState.selectedBoardPosition;
    final enabled = pos != null;
    final style = VisualStyle.current;
    final bg = style.isClassic
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : style.trayBackground;
    // Biggest round buttons that fit 3 high (max 72px).
    final screenH = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;
    final finish = _gameState.needsFinishCheck;
    final screenW = MediaQuery.sizeOf(context).width;
    final count = finish ? 4 : 3;
    final size = (((vertical ? screenH : screenW) - 8) / count - 12)
        .clamp(36.0, vertical ? 72.0 : 64.0);
    Widget button(IconData icon, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: enabled ? Colors.red : Colors.grey.withOpacity(0.35),
            shape: const CircleBorder(),
            elevation: enabled ? 4 : 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onTap : null,
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(icon, size: size * 0.58, color: Colors.white),
              ),
            ),
          ),
        );
    final buttons = [
      button(Icons.rotate_left,
          () => _gameState.rotatePlacedTile(pos!, counterClockwise: true)),
      button(Icons.rotate_right, () => _gameState.rotatePlacedTile(pos!)),
      button(Icons.undo, () => _gameState.returnTileToHand(pos!)),
      if (finish) _finishButton(size),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      child: vertical
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center, children: buttons)
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: buttons),
    );
  }

  /// "I finished": grey until the board is full, then a pulsing green
  /// button; pressing it checks the board (green frame or red mistakes).
  Widget _finishButton(double size) {
    final ready = _gameState.awaitingFinishCheck;
    return Pulse(
      active: ready,
      builder: (pulse) => Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: ready
              ? BoxDecoration(shape: BoxShape.circle, boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.4 + 0.5 * pulse),
                    blurRadius: 10 + 20 * pulse,
                    spreadRadius: 2 + 6 * pulse,
                  ),
                ])
              : null,
          child: Transform.scale(
            scale: 1 + 0.12 * pulse,
            child: Material(
              key: const ValueKey('finish_check'),
              color: ready
                  ? const Color(0xFF12B83A)
                  : Colors.grey.withOpacity(0.35),
              shape: const CircleBorder(),
              elevation: ready ? 6 : 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: ready
                    ? () {
                        Telemetry.log('finish_check', {
                          'grid': _gameState.targetGridSize,
                          'boards': _gameState.boards,
                          'mismatches': _gameState.mismatchCount,
                        });
                        _gameState.confirmFinished();
                      }
                    : null,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Icon(Icons.check_rounded,
                      size: size * 0.66, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
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
                widget.practiceGridSize != null
                    ? 'Practice'
                    : 'Level ${_gameState.currentLevel}/12',
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
