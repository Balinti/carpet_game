import 'package:carpet_game/assessment/assessment.dart';
import 'package:carpet_game/models/models.dart';
import 'package:carpet_game/screens/assessment_screen.dart';
import 'package:carpet_game/screens/game_screen.dart';
import 'package:carpet_game/game/game_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements AssessmentStore {
  final saved = <AssessmentResult>[];
  @override
  Future<void> save(AssessmentResult r) async => saved.add(r);
  @override
  Future<List<AssessmentResult>> all() async => saved;
}

void main() {
  testWidgets('rounds advance after solving and results are saved',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = _MemoryStore();
    AssessmentResult? completed;
    await tester.pumpWidget(MaterialApp(
      home: AssessmentScreen(
        rounds: const [1, 1],
        store: store,
        onComplete: (r) => completed = r,
      ),
    ));

    // Instructions first; the play button starts round 1.
    expect(find.byType(GameScreen), findsNothing);
    expect(find.byKey(const ValueKey('intro_example_good')), findsOneWidget);
    expect(find.byKey(const ValueKey('intro_example_bad')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('intro_start')));
    await tester.pump();

    Future<void> solveRound() async {
      final screen = tester.widget<GameScreen>(find.byType(GameScreen));
      final GameState gs = screen.gameState!;
      for (var c = 0; c < gs.gridCols; c++) {
        if (gs.isGapCol(c)) continue;
        gs.placeTileAt(gs.currentPlayer.hand.first, BoardPosition(0, c));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump();
    }

    await solveRound();
    expect(find.byType(GameScreen), findsOneWidget);
    await solveRound();
    await tester.pumpAndSettle();

    expect(find.byType(AssessmentResultsView), findsOneWidget);
    expect(store.saved, hasLength(1));
    expect(completed?.rounds, hasLength(2));
    expect(completed!.rounds.every((r) => r.solved), isTrue);
    expect(completed!.rounds.map((r) => r.boards), [1, 2]);
  });
}
