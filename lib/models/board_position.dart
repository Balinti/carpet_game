/// Represents a position on the game board.
class BoardPosition {
  final int row;
  final int col;

  const BoardPosition(this.row, this.col);

  /// Returns the position above this one.
  BoardPosition get up => BoardPosition(row - 1, col);

  /// Returns the position below this one.
  BoardPosition get down => BoardPosition(row + 1, col);

  /// Returns the position to the left.
  BoardPosition get left => BoardPosition(row, col - 1);

  /// Returns the position to the right.
  BoardPosition get right => BoardPosition(row, col + 1);

  /// Returns all adjacent positions.
  List<BoardPosition> get neighbors => [up, right, down, left];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ (col.hashCode << 16);

  @override
  String toString() => 'BoardPosition($row, $col)';
}
