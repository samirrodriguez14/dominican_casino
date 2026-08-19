import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/game_state_fixtures.dart';

void main() {
  test('GameState.toJson/fromMap round-trips core fields', () {
    final usedCard = GameStateFixtures.card(
      id: 'used_5',
      rank: '5',
      suit: '♥',
    );
    final tableCard = GameStateFixtures.card(
      id: 'table_9',
      rank: '9',
      suit: '♣',
    );

    final state = GameStateFixtures.casinoTwoPlayerState(
      gameMode: GameMode.casino,
      gameStatus: GameStatus.inProgress,
      controllerId: GameStateFixtures.pid1,
      currentTurnPlayerId: GameStateFixtures.pid1,
      started: true,
      deck: [GameStateFixtures.card(id: 'd1', rank: '2', suit: '♠')],
      table: [tableCard],
      p1Hand: [usedCard],
      p2Hand: const [],
      scores: {GameStateFixtures.pid1: 0, GameStateFixtures.pid2: 0},
      round: Round(
        id: 3,
        roundStatus: RoundStatus.playing,
        roundScores: const {},
      ),
    );

    final json = state.toJson();
    final restored = GameState.fromMap(json);

    expect(restored.id, state.id);
    expect(restored.gameMode, state.gameMode);
    expect(restored.gameStatus, state.gameStatus);
    expect(restored.controllerId, state.controllerId);
    expect(restored.currentTurnPlayerId, state.currentTurnPlayerId);

    expect(restored.playingArea, hasLength(1));
    expect(restored.playingArea.first.id, tableCard.id);

    expect(restored.hands[GameStateFixtures.pid1], hasLength(1));
    expect(restored.hands[GameStateFixtures.pid1]!.first.id, usedCard.id);
  });
}

