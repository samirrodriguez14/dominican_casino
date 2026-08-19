import 'package:dominican_casino/game_control/game_engine/casino/casino_game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/game_state_fixtures.dart';

void main() {
  const pid1 = GameStateFixtures.pid1;
  const pid2 = GameStateFixtures.pid2;

  test('Casino round end updates scores and round status', () {
    // Using different ids keeps EventHandler from treating it as a Tres y Dos draw.
    final usedCard = GameStateFixtures.card(
      id: 'used_10',
      rank: '10',
      suit: '♦',
    );
    final tableCard = GameStateFixtures.card(
      id: 'table_10',
      rank: '10',
      suit: '♦',
    );

    final state = GameStateFixtures.casinoTwoPlayerState(
      gameMode: GameMode.casino,
      gameStatus: GameStatus.inProgress,
      controllerId: pid1,
      currentTurnPlayerId: pid1,
      started: true,
      deck: const [],
      table: [tableCard],
      p1Hand: [usedCard],
      p2Hand: [],
      scores: {pid1: 0, pid2: 0},
      round: Round(
        id: 0,
        roundStatus: RoundStatus.playing,
        roundScores: const {},
      ),
    );

    final engine = CasinoGameEngine();
    final selection = GameStateFixtures.casinoTakeCardSelection(
      pid: pid1,
      usedCard: usedCard,
      targetTableCard: tableCard,
    );
    final action = TakeCardAction(
      usedCard: usedCard,
      targetCard: tableCard,
      performedById: pid1,
    );

    final result = engine.performPlayAction(state, selection, action);

    // Round ended because deck is empty and both hands are now empty.
    expect(result.deck, isEmpty);
    expect(result.hands[pid1], isEmpty);
    expect(result.playingArea, isEmpty);
    expect(result.settlementEvents, isEmpty);

    expect(result.round.roundStatus, RoundStatus.completed);
    expect(result.round.id, 1);

    // Turn advances to the next pid after a selected-card play.
    expect(result.currentTurnPlayerId, pid2);

    // CasinoGameStateHandler shifts controllerId when round ends.
    expect(result.controllerId, pid2);

    // Two 10♦ cards => +4 base, plus +1 "extra points" (virao) when the
    // table becomes empty after a capture.
    expect(result.scores[pid1], 5);
    final perRound = result.round.roundScores[pid1] as Map<String, dynamic>;
    expect(perRound['10♦'], 4);
    expect(perRound['virao'], 1);
    expect(perRound['total'], 5);
    expect(result.winnerId, isNull);
  });
}

