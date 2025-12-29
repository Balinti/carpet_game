import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../widgets/tile_painter.dart';

/// Starter Puzzle screen - 3x3 grid puzzle with timer and rotation counter.
class StarterPuzzleScreen extends StatefulWidget {
  const StarterPuzzleScreen({super.key});

  @override
  State<StarterPuzzleScreen> createState() => _StarterPuzzleScreenState();
}

class _StarterPuzzleScreenState extends State<StarterPuzzleScreen> {
  // Grid state: 3x3 = 9 positions, null means empty
  final List<CarpetTile?> _grid = List.filled(9, null);

  // All 9 tiles - always visible at bottom (never removed from this list)
  late List<CarpetTile> _allTiles;

  // Selected tile for placement
  CarpetTile? _selectedTile;

  // Rotation counter
  int _rotationCount = 0;

  // Timer
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _timerStarted = false;

  // Game state
  bool _puzzleComplete = false;

  // Unsuccessful attempt counter (when trying to place in invalid position)
  int _unsuccessfulAttempts = 0;

  @override
  void initState() {
    super.initState();
    _initializePuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializePuzzle() {
    // Generate the specific 36 tile combinations for Starter Puzzle
    _allTiles = CarpetTile.generateStarterPuzzleTiles();
    _grid.fillRange(0, 9, null);
    _selectedTile = null;
    _rotationCount = 0;
    _elapsedSeconds = 0;
    _timerStarted = false;
    _puzzleComplete = false;
    _unsuccessfulAttempts = 0;
    _timer?.cancel();
    _timer = null;
  }

  // Check if a tile is already placed on the grid
  bool _isTilePlaced(CarpetTile tile) {
    return _grid.any((t) => t?.id == tile.id);
  }

  // Get the number of tiles still available (not placed)
  int get _availableTileCount => _allTiles.where((t) => !_isTilePlaced(t)).length;

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

  void _rotateTile(int index) {
    // Don't rotate if tile is already placed
    if (_isTilePlaced(_allTiles[index])) return;

    _startTimer();
    setState(() {
      _allTiles[index] = _allTiles[index].rotateClockwise();
      _rotationCount++;
    });
  }

  void _selectTile(CarpetTile tile) {
    // Don't select if tile is already placed
    if (_isTilePlaced(tile)) return;

    _startTimer();
    setState(() {
      if (_selectedTile?.id == tile.id) {
        _selectedTile = null;
      } else {
        _selectedTile = tile;
      }
    });
  }

  void _placeTileOnGrid(int gridIndex) {
    if (_selectedTile == null) return;
    if (_grid[gridIndex] != null) return;
    if (_isTilePlaced(_selectedTile!)) return;

    _startTimer();

    // Check if placement is valid (matching colors with adjacent tiles)
    if (!_canPlaceTile(_selectedTile!, gridIndex)) {
      setState(() {
        _unsuccessfulAttempts++;
      });
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
      _selectedTile = null;

      // Check if puzzle is complete (all 9 tiles placed)
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
      _grid[gridIndex] = null;
    });
  }

  bool _canPlaceTile(CarpetTile tile, int gridIndex) {
    // Get row and column from grid index
    final row = gridIndex ~/ 3;
    final col = gridIndex % 3;

    // Check each adjacent tile
    // Top neighbor
    if (row > 0) {
      final topIndex = (row - 1) * 3 + col;
      final topTile = _grid[topIndex];
      if (topTile != null && topTile.bottom != tile.top) {
        return false;
      }
    }

    // Bottom neighbor
    if (row < 2) {
      final bottomIndex = (row + 1) * 3 + col;
      final bottomTile = _grid[bottomIndex];
      if (bottomTile != null && bottomTile.top != tile.bottom) {
        return false;
      }
    }

    // Left neighbor
    if (col > 0) {
      final leftIndex = row * 3 + (col - 1);
      final leftTile = _grid[leftIndex];
      if (leftTile != null && leftTile.right != tile.left) {
        return false;
      }
    }

    // Right neighbor
    if (col < 2) {
      final rightIndex = row * 3 + (col + 1);
      final rightTile = _grid[rightIndex];
      if (rightTile != null && rightTile.left != tile.right) {
        return false;
      }
    }

    return true;
  }

  Map<int, EdgeMatchStatus> _getEdgeStatus(int gridIndex) {
    final tile = _grid[gridIndex];
    if (tile == null) return {};

    final row = gridIndex ~/ 3;
    final col = gridIndex % 3;
    final status = <int, EdgeMatchStatus>{};

    // Top edge
    if (row > 0) {
      final topIndex = (row - 1) * 3 + col;
      final topTile = _grid[topIndex];
      if (topTile != null) {
        status[0] = topTile.bottom == tile.top
            ? EdgeMatchStatus.matching
            : EdgeMatchStatus.mismatched;
      } else {
        status[0] = EdgeMatchStatus.noAdjacent;
      }
    } else {
      status[0] = EdgeMatchStatus.noAdjacent;
    }

    // Right edge
    if (col < 2) {
      final rightIndex = row * 3 + (col + 1);
      final rightTile = _grid[rightIndex];
      if (rightTile != null) {
        status[1] = rightTile.left == tile.right
            ? EdgeMatchStatus.matching
            : EdgeMatchStatus.mismatched;
      } else {
        status[1] = EdgeMatchStatus.noAdjacent;
      }
    } else {
      status[1] = EdgeMatchStatus.noAdjacent;
    }

    // Bottom edge
    if (row < 2) {
      final bottomIndex = (row + 1) * 3 + col;
      final bottomTile = _grid[bottomIndex];
      if (bottomTile != null) {
        status[2] = bottomTile.top == tile.bottom
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
      final leftIndex = row * 3 + (col - 1);
      final leftTile = _grid[leftIndex];
      if (leftTile != null) {
        status[3] = leftTile.right == tile.left
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

  void _showCompletionDialog() {
    final l10n = AppLocalizations.of(context);

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
            const SizedBox(height: 12),
            _buildStatRow(
              icon: Icons.warning_amber,
              label: l10n.totalMisses,
              value: '$_unsuccessfulAttempts',
              color: Colors.orange,
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
    Color? color,
  }) {
    final displayColor = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: displayColor),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: displayColor,
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
        title: Text(l10n.starterPuzzleRules),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.rule1Place9),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.starterPuzzle),
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
          // Stats bar (timer and rotation count)
          _buildStatsBar(l10n),

          // Instructions
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              l10n.matchingColors,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 3x3 Grid
          Expanded(
            flex: 3,
            child: Center(
              child: _buildGrid(),
            ),
          ),

          const Divider(height: 1),

          // Available tiles
          Expanded(
            flex: 2,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_allTiles.length} ${l10n.tilesAvailable}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.tapToRotate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        l10n.dragToPlace,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
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
          // Timer
          Row(
            children: [
              const Icon(Icons.timer, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.time,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
                l10n.rotations,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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

          // Unsuccessful attempts counter
          Row(
            children: [
              Icon(Icons.warning_amber, size: 24, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                l10n.misses,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
              Text(
                '$_unsuccessfulAttempts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    const tileSize = 90.0;
    const spacing = 4.0;

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
        children: List.generate(3, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (col) {
              final index = row * 3 + col;
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
        // Don't accept if cell is occupied or tile is already placed elsewhere
        if (_grid[index] != null) return false;
        if (_isTilePlaced(details.data)) return false;
        return _canPlaceTile(details.data, index);
      },
      onAcceptWithDetails: (details) {
        final tile = details.data;
        _startTimer();
        setState(() {
          _grid[index] = tile;
          _selectedTile = null;

          // Check if puzzle is complete (all 9 tiles placed)
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
          // Show placed tile with edge feedback
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

        // Empty cell
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
    // 36 tiles - larger size for better visibility
    const tileSize = 60.0;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: tileSize + 8,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: _allTiles.length,
      itemBuilder: (context, index) {
        final tile = _allTiles[index];
        final isPlaced = _isTilePlaced(tile);
        final isSelected = _selectedTile?.id == tile.id;

        // If tile is placed, show it grayed out
        if (isPlaced) {
          return Opacity(
            opacity: 0.3,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(tileSize, tileSize),
                  painter: TilePainter(tile: tile),
                ),
                // Checkmark overlay for placed tiles
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () => _selectTile(tile),
          onDoubleTap: () => _rotateTile(index),
          child: Draggable<CarpetTile>(
            data: tile,
            onDraggableCanceled: (velocity, offset) {
              // Increment misses when drag is dropped on invalid position
              _startTimer();
              setState(() {
                _unsuccessfulAttempts++;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).tryAnotherSpot),
                  duration: const Duration(milliseconds: 800),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            feedback: Material(
              color: Colors.transparent,
              elevation: 8,
              child: Opacity(
                opacity: 0.9,
                child: CustomPaint(
                  size: const Size(tileSize, tileSize),
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
                size: const Size(tileSize, tileSize),
                painter: TilePainter(tile: tile),
              ),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(tileSize, tileSize),
                  painter: TilePainter(
                    tile: tile,
                    isSelected: isSelected,
                  ),
                ),
                // Rotate indicator (smaller for compact tiles)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.rotate_right,
                      size: 10,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
