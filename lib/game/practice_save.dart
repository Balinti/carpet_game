import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'game_state.dart';

/// Keeps an unfinished practice board on this device so the player can stop
/// and come back later (Shemer). Saved after every move, one per grid size;
/// removed once the board is solved.
class PracticeSave {
  static String _key(int size) => 'practice_save_$size';

  static Map<String, dynamic> _tile(CarpetTile t) => {
        'id': t.id,
        't': t.top.index,
        'r': t.right.index,
        'b': t.bottom.index,
        'l': t.left.index,
      };

  static CarpetTile _fromTile(Map<String, dynamic> j) => CarpetTile(
        id: j['id'] as String,
        top: TileColor.values[j['t'] as int],
        right: TileColor.values[j['r'] as int],
        bottom: TileColor.values[j['b'] as int],
        left: TileColor.values[j['l'] as int],
      );

  /// The board and Builder of [g] as JSON.
  static Map<String, dynamic> snapshot(GameState g) => {
        'size': g.practiceGridSize,
        'boards': g.boards,
        'board': [
          for (final e in g.board.entries)
            {'row': e.key.row, 'col': e.key.col, ..._tile(e.value)},
        ],
        'hand': [for (final t in g.currentPlayer.hand) _tile(t)],
      };

  /// A practice game rebuilt from [snapshot]; null if it doesn't fit.
  static GameState? restore(Map<String, dynamic> s) {
    try {
      final size = s['size'] as int;
      final g = GameState.newPractice(size, boards: (s['boards'] as int?) ?? 1);
      final board = <BoardPosition, CarpetTile>{
        for (final m in (s['board'] as List).cast<Map>())
          BoardPosition(m['row'] as int, m['col'] as int):
              _fromTile(Map<String, dynamic>.from(m)),
      };
      final hand = [
        for (final m in (s['hand'] as List).cast<Map>())
          _fromTile(Map<String, dynamic>.from(m)),
      ];
      // Must be exactly the dealt set of pieces.
      final ids = {...board.values.map((t) => t.id), ...hand.map((t) => t.id)};
      final dealt = g.currentPlayer.hand.map((t) => t.id).toSet();
      if (ids.length != board.length + hand.length ||
          ids.length != dealt.length ||
          !ids.containsAll(dealt)) {
        return null;
      }
      g.loadPracticeBoard(board, hand);
      return g;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> load(int size) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key(size));
      if (raw == null) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Save [g], or forget the save when its board is empty or solved.
  static Future<void> save(GameState g) async {
    final size = g.practiceGridSize;
    if (size == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      if (g.board.isEmpty || g.confirmedSolved) {
        await p.remove(_key(size));
      } else {
        await p.setString(_key(size), jsonEncode(snapshot(g)));
      }
    } catch (_) {}
  }
}
