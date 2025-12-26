import 'package:flutter/material.dart';

/// The four colors used in the carpet tile game.
enum TileColor {
  red,
  green,
  blue,
  yellow;

  Color toColor() {
    switch (this) {
      case TileColor.red:
        return const Color(0xFFE53935);
      case TileColor.green:
        return const Color(0xFF43A047);
      case TileColor.blue:
        return const Color(0xFF1E88E5);
      case TileColor.yellow:
        return const Color(0xFFFFB300);
    }
  }

  String get displayName {
    switch (this) {
      case TileColor.red:
        return 'Red';
      case TileColor.green:
        return 'Green';
      case TileColor.blue:
        return 'Blue';
      case TileColor.yellow:
        return 'Yellow';
    }
  }
}
