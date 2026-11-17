import 'package:flutter/material.dart';

/// Look-and-feel options for the board and pieces.
///
/// 0 = classic (original flat look), 1 = Soft 3D, 2 = Neon glass, 3 = Clay.
/// On the web the style can be picked with `?style=N` in the URL so the
/// options can be compared side by side.
class VisualStyle {
  final int id;
  final String name;

  /// Colors for red, green, blue, yellow (same order as TileColor).
  final List<Color> palette;

  /// Background behind the board.
  final List<Color> boardBackground;

  /// Background of the Builder tray area.
  final Color trayBackground;

  /// Card behind the tray pieces.
  final Color trayCard;

  /// Board frame and empty squares.
  final Color boardFrame;
  final Color emptySlot;
  final Color emptySlotBorder;

  /// Text/icon color on the tray card.
  final Color onTray;

  const VisualStyle({
    required this.id,
    required this.name,
    required this.palette,
    required this.boardBackground,
    required this.trayBackground,
    required this.trayCard,
    required this.boardFrame,
    required this.emptySlot,
    required this.emptySlotBorder,
    required this.onTray,
  });

  bool get isClassic => id == 0;

  static const classic = VisualStyle(
    id: 0,
    name: 'Classic',
    palette: [
      Color(0xFFE53935),
      Color(0xFF43A047),
      Color(0xFF1E88E5),
      Color(0xFFFFB300),
    ],
    boardBackground: [],
    trayBackground: Colors.transparent,
    trayCard: Colors.transparent,
    boardFrame: Colors.transparent,
    emptySlot: Colors.transparent,
    emptySlotBorder: Colors.transparent,
    onTray: Colors.white,
  );

  static const soft3d = VisualStyle(
    id: 1,
    name: 'Soft 3D',
    palette: [
      Color(0xFFFF4D5E),
      Color(0xFF2ECC71),
      Color(0xFF3D8BFF),
      Color(0xFFFFC233),
    ],
    boardBackground: [Color(0xFF1B1F3B), Color(0xFF2B1F4D), Color(0xFF14172B)],
    trayBackground: Color(0xFF12152A),
    trayCard: Color(0xFF1E2244),
    boardFrame: Color(0xFF7C83FF),
    emptySlot: Color(0x22FFFFFF),
    emptySlotBorder: Color(0x33FFFFFF),
    onTray: Colors.white,
  );

  static const neon = VisualStyle(
    id: 2,
    name: 'Neon glass',
    palette: [
      Color(0xFFFF2E63),
      Color(0xFF00F5A0),
      Color(0xFF00B8FF),
      Color(0xFFFFE600),
    ],
    boardBackground: [Color(0xFF05010F), Color(0xFF120B2E), Color(0xFF02040A)],
    trayBackground: Color(0xFF05010F),
    trayCard: Color(0xFF0E0A22),
    boardFrame: Color(0xFF00E5FF),
    emptySlot: Color(0x1400E5FF),
    emptySlotBorder: Color(0x5500E5FF),
    onTray: Color(0xFFB8F7FF),
  );

  static const clay = VisualStyle(
    id: 3,
    name: 'Clay',
    palette: [
      Color(0xFFF2675C),
      Color(0xFF5CC48C),
      Color(0xFF5B9DF2),
      Color(0xFFF7C04A),
    ],
    boardBackground: [Color(0xFFFFF4E6), Color(0xFFFCE7F3), Color(0xFFE8F1FF)],
    trayBackground: Color(0xFFF7EFE6),
    trayCard: Color(0xFFFFFFFF),
    boardFrame: Color(0xFFE2D4C4),
    emptySlot: Color(0xFFF1E7DC),
    emptySlotBorder: Color(0xFFE2D4C4),
    onTray: Color(0xFF4A3F35),
  );

  static const all = [classic, soft3d, neon, clay];

  /// The style in use. Default: classic, overridable with `?style=N`.
  static final VisualStyle current = _fromUrl();

  static VisualStyle _fromUrl() {
    final n = int.tryParse(Uri.base.queryParameters['style'] ?? '');
    if (n != null && n >= 0 && n < all.length) return all[n];
    return classic;
  }
}
