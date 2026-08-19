import 'package:dominican_casino/game_control/game_engine/casino/casino_game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/game_state_fixtures.dart';

void main() {
  const pid1 = GameStateFixtures.pid1;
  const pid2 = GameStateFixtures.pid2;

  group('CasinoRulesHandler validateAction', () {
    test('rejects not-your-turn', () {
      final usedCard = GameStateFixtures.card(
        id: 'used_a',
        rank: 'A',
        suit: '♣',
      );
      final targetTableCard = GameStateFixtures.card(
        id: 'table_a',
        rank: 'A',
        suit: '♠',
      );

      final state = GameStateFixtures.casinoTwoPlayerState(
        gameMode: GameMode.casino,
        gameStatus: GameStatus.inProgress,
        controllerId: pid1,
        currentTurnPlayerId: pid2,
        started: true,
        deck: [],
        table: [targetTableCard],
        p1Hand: [usedCard],
        p2Hand: [],
      );

      final engine = CasinoGameEngine();
      final selection = GameStateFixtures.casinoTakeCardSelection(
        pid: pid1,
        usedCard: usedCard,
        targetTableCard: targetTableCard,
      );
      final action = TakeCardAction(
        usedCard: usedCard,
        targetCard: targetTableCard,
        performedById: pid1,
      );

      final result = engine.validateAction(state, selection, action);
      expect(result.result, isFalse);
      expect(result.reason, 'Not your turn');
    });

    test('rejects missing selected hand card', () {
      final usedCard = GameStateFixtures.card(
        id: 'used_10',
        rank: '10',
        suit: '♦',
      );
      final targetTableCard = GameStateFixtures.card(
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
        deck: [],
        table: [targetTableCard],
        p1Hand: [usedCard],
        p2Hand: [],
      );

      final engine = CasinoGameEngine();

      final selection = CurrentCardSelection(
        pid: pid1,
        selectedCard: null,
        selectedCards: [targetTableCard],
        selectedStacks: const [],
      );
      final action = TakeCardAction(
        usedCard: usedCard,
        targetCard: targetTableCard,
        performedById: pid1,
      );

      final result = engine.validateAction(state, selection, action);
      expect(result.result, isFalse);
      expect(result.reason, 'Must Have a selected Card');
    });

    test('rejects target card not on table', () {
      final usedCard = GameStateFixtures.card(
        id: 'used_10',
        rank: '10',
        suit: '♦',
      );
      final targetTableCard = GameStateFixtures.card(
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
        deck: [],
        table: const [],
        p1Hand: [usedCard],
        p2Hand: [],
      );

      final engine = CasinoGameEngine();
      final selection = GameStateFixtures.casinoTakeCardSelection(
        pid: pid1,
        usedCard: usedCard,
        targetTableCard: targetTableCard,
      );
      final action = TakeCardAction(
        usedCard: usedCard,
        targetCard: targetTableCard,
        performedById: pid1,
      );

      final result = engine.validateAction(state, selection, action);
      expect(result.result, isFalse);
      expect(result.reason, 'Must actually be on table');
    });

    test('rejects take action with != 1 table card selected', () {
      final usedCard = GameStateFixtures.card(
        id: 'used_5',
        rank: '5',
        suit: '♥',
      );
      final target1 = GameStateFixtures.card(
        id: 'table_5_1',
        rank: '5',
        suit: '♣',
      );
      final target2 = GameStateFixtures.card(
        id: 'table_5_2',
        rank: '5',
        suit: '♦',
      );

      final state = GameStateFixtures.casinoTwoPlayerState(
        gameMode: GameMode.casino,
        gameStatus: GameStatus.inProgress,
        controllerId: pid1,
        currentTurnPlayerId: pid1,
        started: true,
        deck: [],
        table: [target1, target2],
        p1Hand: [usedCard],
        p2Hand: [],
      );

      final engine = CasinoGameEngine();
      final selection = CurrentCardSelection(
        pid: pid1,
        selectedCard: usedCard,
        selectedCards: [target1, target2],
        selectedStacks: const [],
      );
      final action = TakeCardAction(
        usedCard: usedCard,
        targetCard: target1,
        performedById: pid1,
      );

      final result = engine.validateAction(state, selection, action);
      expect(result.result, isFalse);
      expect(result.reason, 'Must select exactly one table card');
    });
  });
}

