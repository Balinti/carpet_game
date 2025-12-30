import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../models/challenge.dart';
import '../models/progression.dart';
import '../widgets/tile_painter.dart';

/// Generic puzzle screen supporting 2x2, 3x3, and 4x4 grids.
class PuzzleScreen extends StatefulWidget {
  final GridSize gridSize;
  final Challenge? challenge;
  final ProgressionManager? progressionManager;

  const PuzzleScreen({
    super.key,
    required this.gridSize,
    this.challenge,
    this.progressionManager,
  });

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with TickerProviderStateMixin {
  // Grid state
  late List<CarpetTile?> _grid;

  // Available tiles
  late List<CarpetTile> _availableTiles;

  // Selected tile for placement
  CarpetTile? _selectedTile;
  int? _selectedIndex;

  // Rotation counter and animation
  int _rotationCount = 0;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // Timer
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _timerStarted = false;

  // Game state
  bool _puzzleComplete = false;

  // Grid dimensions
  int get _gridSize => widget.gridSize.size;
  int get _tileCount => widget.gridSize.tileCount;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.25).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeOut),
    );
    _initializePuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  void _initializePuzzle() {
    // Generate 64 tiles for all modes (full tile set)
    _availableTiles = List.generate(
      64,
      (i) => CarpetTile.generateRandom('tile_$i'),
    );
    _grid = List.filled(_tileCount, null);
    _selectedTile = null;
    _selectedIndex = null;
    _rotationCount = 0;
    _elapsedSeconds = 0;
    _timerStarted = false;
    _puzzleComplete = false;
    _timer?.cancel();
    _timer = null;
  }

  void _startTimer() {
    if (!_timerStarted) {
      _timerStarted = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && !_puzzleComplete) {
          setState(() {
            _elapsedSeconds++;
          });
        }
      });
    }
  }

  void _rotateTile(int index, {bool counterClockwise = false}) {
    _startTimer();

    // Animate rotation
    _rotationController.forward(from: 0).then((_) {
      setState(() {
        if (counterClockwise) {
          _availableTiles[index] =
              _availableTiles[index].rotateCounterClockwise();
        } else {
          _availableTiles[index] = _availableTiles[index].rotateClockwise();
        }
        _rotationCount++;
        // Update selected tile if it was the one rotated
        if (_selectedIndex == index) {
          _selectedTile = _availableTiles[index];
        }
      });
    });
  }

  void _selectTile(CarpetTile tile, int index) {
    _startTimer();
    setState(() {
      if (_selectedTile?.id == tile.id) {
        _selectedTile = null;
        _selectedIndex = null;
      } else {
        _selectedTile = tile;
        _selectedIndex = index;
      }
    });
  }

  void _placeTileOnGrid(int gridIndex) {
    if (_selectedTile == null) return;
    if (_grid[gridIndex] != null) return;

    _startTimer();

    // Check if placement is valid
    if (!_canPlaceTile(_selectedTile!, gridIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).tryAnotherSpot),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _grid[gridIndex] = _selectedTile;
      _availableTiles.removeWhere((t) => t.id == _selectedTile!.id);
      _selectedTile = null;
      _selectedIndex = null;

      // Check if puzzle is complete (grid is full)
      if (!_grid.contains(null)) {
        _puzzleComplete = true;
        _timer?.cancel();
        _showCompletionDialog();
      }
    });
  }

  void _removeTileFromGrid(int gridIndex) {
    if (_grid[gridIndex] == null) return;

    setState(() {
      _availableTiles.add(_grid[gridIndex]!);
      _grid[gridIndex] = null;
    });
  }

  bool _canPlaceTile(CarpetTile tile, int gridIndex) {
    final row = gridIndex ~/ _gridSize;
    final col = gridIndex % _gridSize;

    // Check each adjacent tile - colors must be DIFFERENT (not the same)
    // Top neighbor
    if (row > 0) {
      final topIndex = (row - 1) * _gridSize + col;
      final topTile = _grid[topIndex];
      if (topTile != null && topTile.bottom == tile.top) {
        return false; // Same color - not allowed
      }
    }

    // Bottom neighbor
    if (row < _gridSize - 1) {
      final bottomIndex = (row + 1) * _gridSize + col;
      final bottomTile = _grid[bottomIndex];
      if (bottomTile != null && bottomTile.top == tile.bottom) {
        return false; // Same color - not allowed
      }
    }

    // Left neighbor
    if (col > 0) {
      final leftIndex = row * _gridSize + (col - 1);
      final leftTile = _grid[leftIndex];
      if (leftTile != null && leftTile.right == tile.left) {
        return false; // Same color - not allowed
      }
    }

    // Right neighbor
    if (col < _gridSize - 1) {
      final rightIndex = row * _gridSize + (col + 1);
      final rightTile = _grid[rightIndex];
      if (rightTile != null && rightTile.left == tile.right) {
        return false; // Same color - not allowed
      }
    }

    return true;
  }

  Map<int, EdgeMatchStatus> _getEdgeStatus(int gridIndex) {
    final tile = _grid[gridIndex];
    if (tile == null) return {};

    final row = gridIndex ~/ _gridSize;
    final col = gridIndex % _gridSize;
    final status = <int, EdgeMatchStatus>{};

    // Top edge - DIFFERENT colors = matching (good), SAME colors = mismatched (bad)
    if (row > 0) {
      final topIndex = (row - 1) * _gridSize + col;
      final topTile = _grid[topIndex];
      if (topTile != null) {
        status[0] = topTile.bottom != tile.top
            ? EdgeMatchStatus.matching   // Different colors = good
            : EdgeMatchStatus.mismatched; // Same colors = bad
      } else {
        status[0] = EdgeMatchStatus.noAdjacent;
      }
    } else {
      status[0] = EdgeMatchStatus.noAdjacent;
    }

    // Right edge
    if (col < _gridSize - 1) {
      final rightIndex = row * _gridSize + (col + 1);
      final rightTile = _grid[rightIndex];
      if (rightTile != null) {
        status[1] = rightTile.left != tile.right
            ? EdgeMatchStatus.matching
            : EdgeMatchStatus.mismatched;
      } else {
        status[1] = EdgeMatchStatus.noAdjacent;
      }
    } else {
      status[1] = EdgeMatchStatus.noAdjacent;
    }

    // Bottom edge
    if (row < _gridSize - 1) {
      final bottomIndex = (row + 1) * _gridSize + col;
      final bottomTile = _grid[bottomIndex];
      if (bottomTile != null) {
        status[2] = bottomTile.top != tile.bottom
            ? EdgeMatchStatus.matching
            : EdgeMatchStatus.mismatched;
      } else {
        status[2] = EdgeMatchStatus.noAdjacent;
      }
    } else {
      status[2] = EdgeMatchStatus.noAdjacent;
    }

    // Left edge
    if (col > 0) {
      final leftIndex = row * _gridSize + (col - 1);
      final leftTile = _grid[leftIndex];
      if (leftTile != null) {
        status[3] = leftTile.right != tile.left
            ? EdgeMatchStatus.matching
            : EdgeMatchStatus.mismatched;
      } else {
        status[3] = EdgeMatchStatus.noAdjacent;
      }
    } else {
      status[3] = EdgeMatchStatus.noAdjacent;
    }

    return status;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog() async {
    final l10n = AppLocalizations.of(context);

    // Calculate stars
    final stars = ChallengeResult.calculateStars(
      timeSeconds: _elapsedSeconds,
      rotations: _rotationCount,
      gridSize: widget.gridSize,
    );

    // Save progress if we have a challenge
    if (widget.challenge != null && widget.progressionManager != null) {
      final result = ChallengeResult(
        challengeId: widget.challenge!.id,
        completed: true,
        timeSeconds: _elapsedSeconds,
        rotations: _rotationCount,
        stars: stars,
      );
      await widget.progressionManager!.completeChallenge(result);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.amber, size: 32),
            const SizedBox(width: 12),
            Text(l10n.puzzleComplete),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.congratulations,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            ),
            const SizedBox(height: 16),
            // Stars display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                );
              }),
            ),
            const SizedBox(height: 24),
            _buildStatRow(
              icon: Icons.timer,
              label: l10n.yourTime,
              value: _formatTime(_elapsedSeconds),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              icon: Icons.rotate_right,
              label: l10n.totalRotations,
              value: '$_rotationCount',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _initializePuzzle();
              });
            },
            icon: const Icon(Icons.replay),
            label: Text(l10n.playAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  void _showRulesDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${widget.gridSize.displayName} Puzzle Rules'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Place all ${widget.gridSize.tileCount} tiles on the ${widget.gridSize.displayName} grid.'),
            const SizedBox(height: 8),
            Text(l10n.rule2MatchColors),
            const SizedBox(height: 8),
            Text(l10n.rule3Rotate),
            const SizedBox(height: 8),
            Text(l10n.rule4Timer),
          ],
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.challenge?.name ?? '${widget.gridSize.displayName} Puzzle';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRulesDialog,
            tooltip: l10n.rules,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializePuzzle();
              });
            },
            tooltip: l10n.newGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          _buildStatsBar(l10n),

          // Instructions
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              widget.challenge?.description ?? l10n.matchingColors,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          // Grid
          Expanded(
            flex: 3,
            child: Center(
              child: _buildGrid(),
            ),
          ),

          const Divider(height: 1),

          // Available tiles with rotation button
          Expanded(
            flex: 2,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap to select, drag to place',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      // Rotation button
                      if (_selectedTile != null && _selectedIndex != null)
                        Row(
                          children: [
                            IconButton.filled(
                              onPressed: () =>
                                  _rotateTile(_selectedIndex!, counterClockwise: true),
                              icon: const Icon(Icons.rotate_left),
                              tooltip: 'Rotate left',
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: () => _rotateTile(_selectedIndex!),
                              icon: const Icon(Icons.rotate_right),
                              tooltip: 'Rotate right',
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildAvailableTiles(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Grid size indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.gridSize.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),

          // Timer
          Row(
            children: [
              const Icon(Icons.timer, size: 24),
              const SizedBox(width: 8),
              Text(
                _formatTime(_elapsedSeconds),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),

          // Rotation count
          Row(
            children: [
              const Icon(Icons.rotate_right, size: 24),
              const SizedBox(width: 8),
              Text(
                '$_rotationCount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    // Calculate tile size based on grid size
    final double tileSize;
    const double spacing = 4.0;

    switch (widget.gridSize) {
      case GridSize.twoByTwo:
        tileSize = 100.0;
        break;
      case GridSize.threeByThree:
        tileSize = 90.0;
        break;
      case GridSize.fourByFour:
        tileSize = 70.0;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_gridSize, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_gridSize, (col) {
              final index = row * _gridSize + col;
              return Padding(
                padding: const EdgeInsets.all(spacing / 2),
                child: _buildGridCell(index, tileSize),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildGridCell(int index, double size) {
    final tile = _grid[index];

    return DragTarget<CarpetTile>(
      onWillAcceptWithDetails: (details) {
        return _grid[index] == null && _canPlaceTile(details.data, index);
      },
      onAcceptWithDetails: (details) {
        final tile = details.data;
        _startTimer();
        setState(() {
          _grid[index] = tile;
          _availableTiles.removeWhere((t) => t.id == tile.id);
          _selectedTile = null;
          _selectedIndex = null;

          // Check if grid is full
          if (!_grid.contains(null)) {
            _puzzleComplete = true;
            _timer?.cancel();
            _showCompletionDialog();
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isValidDrop = candidateData.isNotEmpty;
        final isRejected = rejectedData.isNotEmpty;

        if (tile != null) {
          return GestureDetector(
            onTap: () => _removeTileFromGrid(index),
            child: CustomPaint(
              size: Size(size, size),
              painter: TilePainter(
                tile: tile,
                edgeStatus: _getEdgeStatus(index),
              ),
            ),
          );
        }

        Color bgColor;
        Color borderColor;
        Widget? icon;

        if (isValidDrop) {
          bgColor = Colors.green.withOpacity(0.3);
          borderColor = Colors.green;
          icon = const Icon(Icons.add, color: Colors.green, size: 32);
        } else if (isRejected) {
          bgColor = Colors.red.withOpacity(0.2);
          borderColor = Colors.red;
          icon = const Icon(Icons.close, color: Colors.red, size: 32);
        } else if (_selectedTile != null && _canPlaceTile(_selectedTile!, index)) {
          bgColor = Colors.green.withOpacity(0.15);
          borderColor = Colors.green.shade300;
          icon = const Icon(Icons.add, color: Colors.green, size: 24);
        } else {
          bgColor = Colors.grey.withOpacity(0.1);
          borderColor = Colors.grey.shade400;
          icon = null;
        }

        return GestureDetector(
          onTap: () => _placeTileOnGrid(index),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(child: icon),
          ),
        );
      },
    );
  }

  Widget _buildAvailableTiles() {
    // Calculate tile size based on grid size
    final double tileSize;
    switch (widget.gridSize) {
      case GridSize.twoByTwo:
        tileSize = 80.0;
        break;
      case GridSize.threeByThree:
        tileSize = 70.0;
        break;
      case GridSize.fourByFour:
        tileSize = 60.0;
        break;
    }

    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _availableTiles.asMap().entries.map((entry) {
          final index = entry.key;
          final tile = entry.value;
          final isSelected = _selectedTile?.id == tile.id;

          return GestureDetector(
            onTap: () => _selectTile(tile, index),
            onDoubleTap: () => _rotateTile(index),
            child: Draggable<CarpetTile>(
              data: tile,
              feedback: Material(
                color: Colors.transparent,
                elevation: 8,
                child: Opacity(
                  opacity: 0.9,
                  child: CustomPaint(
                    size: Size(tileSize, tileSize),
                    painter: TilePainter(
                      tile: tile,
                      isSelected: true,
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: CustomPaint(
                  size: Size(tileSize, tileSize),
                  painter: TilePainter(tile: tile),
                ),
              ),
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  final rotationValue = _selectedIndex == index
                      ? _rotationAnimation.value
                      : 0.0;
                  return Transform.rotate(
                    angle: rotationValue * 2 * 3.14159,
                    child: child,
                  );
                },
                child: Container(
                  decoration: isSelected
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        )
                      : null,
                  child: CustomPaint(
                    size: Size(tileSize, tileSize),
                    painter: TilePainter(
                      tile: tile,
                      isSelected: isSelected,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
