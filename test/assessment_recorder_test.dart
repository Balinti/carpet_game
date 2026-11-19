import 'dart:convert';

import 'package:carpet_game/assessment/assessment.dart';
import 'package:carpet_game/game/game_state.dart';
import 'package:carpet_game/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeClock clock;
  late AssessmentRecorder rec;

  setUp(() {
    clock = FakeClock(DateTime.utc(2025, 3, 1, 10));
    rec = AssessmentRecorder(clock: clock);
    rec.startRound(2);
  });

  group('AssessmentRecorder', () {
    test('counts rotations split cw / ccw', () {
      rec.onRotate();
      rec.onRotate();
      rec.onRotate(counterClockwise: true);
      final m = rec.completeRound();
      expect(m.rotationsCw, 2);
      expect(m.rotationsCcw, 1);
      expect(m.rotations, 3);
    });

    test('placement timestamps and intervals', () {
      clock.advanceMs(1000);
      rec.onPlace('a');
      clock.advanceMs(2500);
      rec.onPlace('b');
      clock.advanceMs(400);
      rec.onPlace('c');
      final m = rec.completeRound();
      expect(m.placementTimestampsMs, [1000, 3500, 3900]);
      expect(m.placementIntervalsMs, [2500, 400]);
      expect(m.firstInteractionMs, 1000);
    });

    test('pick-to-place keeps earliest pick of same piece', () {
      clock.advanceMs(500);
      rec.onPick('a'); // tap select at 500
      clock.advanceMs(300);
      rec.onPick('a'); // drag start of same piece: ignored
      clock.advanceMs(700);
      rec.onPlace('a'); // 1500
      final m = rec.completeRound();
      expect(m.pickToPlaceMs, [1000]);
    });

    test('pick-to-place resets when another piece is picked', () {
      rec.onPick('a');
      clock.advanceMs(1000);
      rec.onPick('b');
      clock.advanceMs(200);
      rec.onPlace('b');
      // Placement without a pick of that piece adds no pick time.
      clock.advanceMs(100);
      rec.onPlace('c');
      final m = rec.completeRound();
      expect(m.pickToPlaceMs, [200]);
    });

    test('cancelled pick is not counted', () {
      rec.onPick('a');
      clock.advanceMs(1000);
      rec.onPickCancelled('a');
      clock.advanceMs(1000);
      rec.onPlace('a');
      expect(rec.completeRound().pickToPlaceMs, isEmpty);
    });

    test('back to Builder timestamps, help, moves, replacements', () {
      clock.advanceMs(1200);
      rec.onBackToBuilder();
      clock.advanceMs(800);
      rec.onBackToBuilder();
      rec.onHelpOpened();
      rec.onBoardMove();
      rec.onBoardMove();
      rec.onPlace('x', replacement: true);
      final m = rec.completeRound();
      expect(m.backToBuilderTimestampsMs, [1200, 2000]);
      expect(m.backToBuilder, 2);
      expect(m.helpOpens, 1);
      expect(m.boardMoves, 2);
      expect(m.replacements, 1);
    });

    test('duration and first-full mismatches keep the first value', () {
      clock.advanceMs(100);
      rec.onRotate();
      clock.advanceMs(4900);
      rec.onGridFull(3);
      rec.onGridFull(0);
      clock.advanceMs(1000);
      rec.onSolved();
      clock.advanceMs(1000);
      rec.onSolved();
      rec.onRotate(); // after solved: ignored
      final m = rec.completeRound();
      expect(m.mismatchesWhenFirstFull, 3);
      expect(m.durationMs, 6000);
      expect(m.activeDurationMs, 5900);
      expect(m.rotations, 1);
    });

    test('multiple rounds and JSON round-trip', () {
      rec.onRotate(counterClockwise: true);
      rec.onPick('a');
      clock.advanceMs(300);
      rec.onPlace('a');
      rec.onGridFull(1);
      clock.advanceMs(700);
      rec.onSolved();
      rec.completeRound();
      rec.startRound(3);
      clock.advanceMs(2000);
      rec.onHelpOpened();
      rec.completeRound();

      final result = rec.buildResult(userId: 'u1');
      expect(result.rounds.map((r) => r.gridSize), [2, 3]);
      expect(result.rounds[1].solved, isFalse);

      final decoded = AssessmentResult.fromJson(
          jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>);
      expect(decoded.toJson(), result.toJson());
      expect(decoded.userId, 'u1');
      expect(decoded.startedAt, result.startedAt);
      expect(decoded.rounds[0].pickToPlaceMs, [300]);
      expect(decoded.rounds[0].durationMs, 1000);
      expect(decoded.rounds[0].mismatchesWhenFirstFull, 1);
      expect(decoded.rounds[1].helpOpens, 1);
    });
  });

  group('GameState hooks', () {
    test('records picks, places, rotations, back-to-Builder and solved', () {
      final gs = GameState.newPractice(1)..recorder = rec;
      rec.startRound(1);
      final tile = gs.currentPlayer.hand.first;
      clock.advanceMs(400);
      gs.selectTile(tile);
      clock.advanceMs(600);
      gs.placeTile(const BoardPosition(0, 0));
      expect(gs.isSolved, isTrue);
      // Not judged until "I finished".
      expect(gs.awaitingFinishCheck, isTrue);
      expect(gs.confirmedSolved, isFalse);
      expect(rec.currentRound!.durationMs, isNull);
      clock.advanceMs(500);
      gs.confirmFinished();
      expect(gs.confirmedSolved, isTrue);
      final m = rec.currentRound!;
      expect(m.placementTimestampsMs, [1000]);
      expect(m.pickToPlaceMs, [600]);
      expect(m.durationMs, 1500);
      expect(m.mismatchesWhenFirstFull, 0);
      expect(m.minRotations, 0);
      expect(m.wrongFinishChecks, 0);
    });

    test('placed piece is selected; fewest rotations; change un-checks', () {
      final gs = GameState.newPractice(1)..recorder = rec;
      rec.startRound(1);
      final tile = gs.currentPlayer.hand.first;
      gs.rotateHandTile(tile);
      gs.rotateHandTile(gs.currentPlayer.hand.first);
      gs.rotateHandTile(gs.currentPlayer.hand.first);
      gs.placeTileAt(
          gs.currentPlayer.hand.first, const BoardPosition(0, 0));
      // The piece just placed is the one the rotate buttons act on.
      expect(gs.selectedBoardPosition, const BoardPosition(0, 0));
      gs.confirmFinished();
      expect(gs.confirmedSolved, isTrue);
      final m = rec.currentRound!;
      expect(m.rotations, 3);
      // 3 clockwise turns = 1 counter-clockwise turn, unless symmetric.
      expect(m.minRotations, lessThanOrEqualTo(1));
    });

    test('wrong "I finished" is counted and a change needs a new check', () {
      final gs = GameState.newPractice(2)..recorder = rec;
      rec.startRound(2);
      // Fill with pieces until some edge mismatches.
      for (final p in const [
        BoardPosition(0, 0),
        BoardPosition(0, 1),
        BoardPosition(1, 0),
        BoardPosition(1, 1),
      ]) {
        gs.placeTileAt(gs.currentPlayer.hand.first, p);
      }
      if (gs.isSolved) return; // random deal happened to match
      gs.confirmFinished();
      expect(gs.showResult, isTrue);
      expect(gs.confirmedSolved, isFalse);
      expect(rec.currentRound!.wrongFinishChecks, 1);
      // The wrong pieces go back to the Builder; what stays all matches.
      final wrong = gs.rejectedIds;
      expect(wrong, isNotEmpty);
      gs.throwBackRejected();
      expect(gs.board.length, 4 - wrong.length);
      expect(gs.mismatchCount, 0);
      expect(gs.currentPlayer.hand.map((t) => t.id), containsAll(wrong));
      expect(gs.showResult, isFalse);
    });

    test('rotations, swaps and returns in a 2×2', () {
      final gs = GameState.newPractice(2)..recorder = rec;
      final hand = gs.currentPlayer.hand;
      gs.pickUpTile(hand[0]);
      clock.advanceMs(250);
      gs.placeTileAt(hand[0], const BoardPosition(0, 0));
      gs.placeTileAt(hand[0], const BoardPosition(0, 1));
      gs.rotatePlacedTile(const BoardPosition(0, 0));
      gs.rotatePlacedTile(const BoardPosition(0, 0), counterClockwise: true);
      gs.swapTiles(const BoardPosition(0, 0), const BoardPosition(1, 1));
      gs.returnTileToHand(const BoardPosition(0, 1));
      gs.recordHelpOpened();
      final m = rec.currentRound!;
      expect(m.placements, 2);
      expect(m.pickToPlaceMs, [250]);
      expect(m.rotationsCw, 1);
      expect(m.rotationsCcw, 1);
      expect(m.boardMoves, 1);
      expect(m.backToBuilder, 1);
      expect(m.helpOpens, 1);
      expect(m.mismatchesWhenFirstFull, isNull);
    });
  });

  group('LocalAssessmentStore', () {
    test('saves and reads back results', () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalAssessmentStore();
      rec.onRotate();
      rec.completeRound();
      final r = rec.buildResult();
      await store.save(r);
      await store.save(r.copyWith(userId: 'later')); // same id: replaced
      final all = await store.all();
      expect(all, hasLength(1));
      expect(all.first.userId, 'later');
      expect(all.first.rounds.first.rotationsCw, 1);
    });
  });
}
