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

  /// Checks if the player has a specific tile.
  bool hasTile(String tileId) {
    return hand.any((t) => t.id == tileId);
  }

  /// Gets a tile by ID from the player's hand.
  CarpetTile? getTile(String tileId) {
    try {
      return hand.firstWhere((t) => t.id == tileId);
    } catch (e) {
      return null;
    }
  }

  /// Creates a copy of this player with an updated hand.
  Player copyWith({
    String? name,
    List<CarpetTile>? hand,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      hand: hand ?? List.from(this.hand),
    );
  }

  @override
  String toString() => 'Player($name, tiles: ${hand.length})';
}
