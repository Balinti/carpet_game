import 'package:carpet_game/game/game_state.dart';
import 'package:carpet_game/models/board_position.dart';
import 'package:carpet_game/widgets/game_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Shemer's bug: in Hebrew (RTL) the board's columns were mirrored on
// screen, so a board that looked right was judged wrong.
void main() {
  testWidgets('board column 0 is on the left even in RTL', (tester) async {
    final state = GameState.newPractice(2);
    final hand = state.currentPlayer.hand;
    state.placeTileAt(hand[0], const BoardPosition(0, 0));
    state.placeTileAt(state.currentPlayer.hand[0], const BoardPosition(0, 1));
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SizedBox(
              width: 400, height: 400, child: GameBoard(gameState: state)),
        ),
      ),
    ));
    await tester.pump();
    final ids = [
      state.board[const BoardPosition(0, 0)]!.id,
      state.board[const BoardPosition(0, 1)]!.id,
    ];
    double x(String id) => tester
        .getCenter(find.byWidgetPredicate((w) =>
            w.key == ValueKey('board_tile_$id')))
        .dx;
    expect(x(ids[0]) < x(ids[1]), isTrue);
  });
}
