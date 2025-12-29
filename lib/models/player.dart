import 'carpet_tile.dart';

/// Represents a player in the Color Dominoes game.
class Player {
  final String id;
  final String name;
  final List<CarpetTile> hand;

  Player({
    required this.id,
    required this.name,
    List<CarpetTile>? hand,
  }) : hand = hand ?? [];

  /// Returns true if the player has no tiles left (winner condition).
  bool get hasWon => hand.isEmpty;

  /// Returns the number of tiles in the player's hand.
  int get tileCount => hand.length;

  /// Adds a tile to the player's hand.
  void addTile(CarpetTile tile) {
    hand.add(tile);
  }

  /// Removes a tile from the player's hand.
  void removeTile(CarpetTile tile) {
    hand.removeWhere((t) => t.id == tile.id);
  }

  @override
  String toString() => 'Player($name, tiles: ${hand.length})';
}
