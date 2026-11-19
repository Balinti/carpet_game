import 'package:carpet_game/game/game_state.dart';
import 'package:carpet_game/game/practice_save.dart';
import 'package:carpet_game/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('unfinished practice board is saved and restored', () async {
    SharedPreferences.setMockInitialValues({});
    final g = GameState.newPractice(3);
    g.rotateHandTile(g.currentPlayer.hand.first);
    g.placeTileAt(g.currentPlayer.hand.first, const BoardPosition(0, 0));
    g.placeTileAt(g.currentPlayer.hand.first, const BoardPosition(1, 2));
    await PracticeSave.save(g);

    final saved = await PracticeSave.load(3);
    expect(saved, isNotNull);
    final r = PracticeSave.restore(saved!)!;
    expect(r.board, g.board);
    expect(r.board[const BoardPosition(0, 0)]!.top,
        g.board[const BoardPosition(0, 0)]!.top);
    expect(r.currentPlayer.hand.map((t) => t.id),
        g.currentPlayer.hand.map((t) => t.id));
    expect(await PracticeSave.load(4), isNull);

    // Empty board (restart) forgets the save.
    g.restart();
    await PracticeSave.save(g);
    expect(await PracticeSave.load(3), isNull);
  });
}
