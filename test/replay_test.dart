import 'package:carpet_game/admin/replay_logic.dart';
import 'package:carpet_game/models/board_position.dart';
import 'package:carpet_game/models/tile_color.dart';
import 'package:flutter_test/flutter_test.dart';

const r = TileColor.red, g = TileColor.green, b = TileColor.blue;
const y = TileColor.yellow;

void main() {
  const deal = ['tile_0:rgby', 'tile_1:rrrr', 'tile_2:gbyr'];
  List<String> trayIds(ReplayState s) => s.tray.map((t) => t.id).toList();
  List<TileColor> colors(ReplayState s, String id) {
    final t = s.tray.firstWhere((t) => t.id == id, orElse: () {
      return s.board.values.firstWhere((t) => t.id == id);
    });
    return [t.top, t.right, t.bottom, t.left];
  }

  test('deal parses into the tray in order', () {
    final s = replayStateAfter(deal, const [], 0);
    expect(trayIds(s), ['tile_0', 'tile_1', 'tile_2']);
    expect(colors(s, 'tile_0'), [r, g, b, y]);
    expect(s.board, isEmpty);
    // Malformed entries are skipped.
    expect(initialReplayState(['bad', 'x:rgbq', 'a:yyyy']).tray.length, 1);
  });

  test('place moves a tray piece to the board with its orientation', () {
    final moves = [
      {'t': 100, 'k': 'place', 'id': 'tile_0', 'r': 0, 'c': 1, 'o': 'yrgb'},
    ];
    final s = replayStateAfter(deal, moves, 1);
    expect(trayIds(s), ['tile_1', 'tile_2']);
    expect(s.board[const BoardPosition(0, 1)]!.id, 'tile_0');
    expect(colors(s, 'tile_0'), [y, r, g, b]);
    // k = 0 is still the start.
    expect(replayStateAfter(deal, moves, 0).board, isEmpty);
  });

  test('rot on tray and on board', () {
    final moves = [
      {'t': 10, 'k': 'rot', 'id': 'tile_2', 'o': 'rgby'},
      {'t': 20, 'k': 'place', 'id': 'tile_0', 'r': 1, 'c': 0, 'o': 'rgby'},
      {'t': 30, 'k': 'rot', 'id': 'tile_0', 'o': 'yrgb', 'r': 1, 'c': 0},
    ];
    var s = replayStateAfter(deal, moves, 1);
    expect(colors(s, 'tile_2'), [r, g, b, y]);
    // Tray order is kept on rotation.
    expect(trayIds(s), ['tile_0', 'tile_1', 'tile_2']);
    s = replayStateAfter(deal, moves, 3);
    expect(colors(s, 'tile_0'), [y, r, g, b]);
    expect(s.board[const BoardPosition(1, 0)]!.id, 'tile_0');
  });

  test('move to an empty square and swap with an occupied one', () {
    final moves = [
      {'t': 1, 'k': 'place', 'id': 'tile_0', 'r': 0, 'c': 0, 'o': 'rgby'},
      {'t': 2, 'k': 'place', 'id': 'tile_1', 'r': 0, 'c': 1, 'o': 'rrrr'},
      {'t': 3, 'k': 'move', 'r': 0, 'c': 0, 'r2': 1, 'c2': 1},
      {'t': 4, 'k': 'move', 'r': 1, 'c': 1, 'r2': 0, 'c2': 1},
    ];
    var s = replayStateAfter(deal, moves, 3);
    expect(s.board[const BoardPosition(0, 0)], isNull);
    expect(s.board[const BoardPosition(1, 1)]!.id, 'tile_0');
    s = replayStateAfter(deal, moves, 4);
    expect(s.board[const BoardPosition(0, 1)]!.id, 'tile_0');
    expect(s.board[const BoardPosition(1, 1)]!.id, 'tile_1');
    expect(s.board.length, 2);
  });

  test('back returns a board piece to the end of the tray', () {
    final moves = [
      {'t': 1, 'k': 'place', 'id': 'tile_0', 'r': 0, 'c': 0, 'o': 'gbyr'},
      {'t': 2, 'k': 'back', 'id': 'tile_0', 'r': 0, 'c': 0},
    ];
    final s = replayStateAfter(deal, moves, 2);
    expect(s.board, isEmpty);
    expect(trayIds(s), ['tile_1', 'tile_2', 'tile_0']);
    // Keeps the orientation it had on the board.
    expect(colors(s, 'tile_0'), [g, b, y, r]);
  });

  test('place onto an occupied square sends the old piece to the tray', () {
    final moves = [
      {'t': 1, 'k': 'place', 'id': 'tile_0', 'r': 0, 'c': 0, 'o': 'rgby'},
      {
        't': 2,
        'k': 'place',
        'id': 'tile_1',
        'r': 0,
        'c': 0,
        'o': 'rrrr',
        'out': 'tile_0'
      },
    ];
    final s = replayStateAfter(deal, moves, 2);
    expect(s.board[const BoardPosition(0, 0)]!.id, 'tile_1');
    expect(trayIds(s), ['tile_2', 'tile_0']);
  });

  test('throw sends listed pieces back; check/giveup/solved change nothing',
      () {
    final moves = [
      {'t': 1, 'k': 'place', 'id': 'tile_0', 'r': 0, 'c': 0, 'o': 'rgby'},
      {'t': 2, 'k': 'place', 'id': 'tile_1', 'r': 0, 'c': 1, 'o': 'rrrr'},
      {'t': 3, 'k': 'place', 'id': 'tile_2', 'r': 1, 'c': 0, 'o': 'gbyr'},
      {'t': 4, 'k': 'check', 'ok': false},
      {
        't': 5,
        'k': 'throw',
        'ids': ['tile_1', 'tile_2']
      },
      {'t': 6, 'k': 'giveup'},
      {'t': 7, 'k': 'solved'},
    ];
    final s4 = replayStateAfter(deal, moves, 4);
    expect(s4.board.length, 3);
    final s = replayStateAfter(deal, moves, 7);
    expect(s.board.keys, [const BoardPosition(0, 0)]);
    expect(trayIds(s), ['tile_1', 'tile_2']);
    // All states list matches step-by-step replay.
    final all = replayAllStates(deal, moves);
    expect(all.length, moves.length + 1);
    expect(trayIds(all[5]), trayIds(replayStateAfter(deal, moves, 5)));
  });

  test('numbers stored as doubles (Firestore) still work', () {
    final moves = [
      {'t': 1.0, 'k': 'place', 'id': 'tile_0', 'r': 0.0, 'c': 2.0, 'o': 'rgby'},
    ];
    final s = replayStateAfter(deal, moves, 1);
    expect(s.board[const BoardPosition(0, 2)]!.id, 'tile_0');
  });

  test('touched ids, time lookup and formatting', () {
    final moves = [
      {'t': 500, 'k': 'place', 'id': 'tile_0', 'r': 0, 'c': 0, 'o': 'rgby'},
      {'t': 1500, 'k': 'move', 'r': 0, 'c': 0, 'r2': 0, 'c2': 1},
      {'t': 65000, 'k': 'solved'},
    ];
    final all = replayAllStates(deal, moves);
    expect(touchedIds(moves[1], all[1]), {'tile_0'});
    expect(touchedIds(moves[2], all[2]), isEmpty);
    expect(eventsUpTo(moves, 0), 0);
    expect(eventsUpTo(moves, 500), 1);
    expect(eventsUpTo(moves, 99999), 3);
    expect(formatReplayTime(65000), '1:05');
    expect(
        replayCaption(moves[1], hebrew: false, gridSize: 2, boards: 2),
        'Moved a piece from board 1 · row 1, col 1 '
        'to board 1 · row 1, col 2');
  });
}
