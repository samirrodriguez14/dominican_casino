import 'package:dominican_casino/game_control/game_engine/tresydos/tres_dos_game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/game_state_fixtures.dart';

void main() {
  const pid1 = GameStateFixtures.pid1;
  const pid2 = GameStateFixtures.pid2;

  group('Tres y Dos engine', () {
    test('GameRegistry.dealCounts matches Tres y Dos table parameters', () {
      expect(GameRegistry.dealCounts(GameMode.tresydos), (5, 1, 0, 1));
    });

    test('validateAction rejects Play when hand size is not 6', () {
      final usedCard = GameStateFixtures.card(
        id: 'play_9',
        rank: '9',
        suit: '♣',
      );

      final state = GameStateFixtures.tresDosTwoPlayerState(
        gameStatus: GameStatus.inProgress,
        controllerId: pid1,
        currentTurnPlayerId: pid1,
        deck: [GameStateFixtures.card(id: 'd1', rank: '7', suit: '♥')],
        playingArea: [],
        p1Hand: [
          GameStateFixtures.card(id: 'c1', rank: '3', suit: '♠'),
          GameStateFixtures.card(id: 'c2', rank: '3', suit: '♥'),
          GameStateFixtures.card(id: 'c3', rank: '2', suit: '♦'),
          GameStateFixtures.card(id: 'c4', rank: '2', suit: '♣'),
          GameStateFixtures.card(id: 'c5', rank: '4', suit: '♣'),
        ], // length 5
        p2Hand: const [],
        scores: {pid1: 0, pid2: 0},
        round: Round(
          id: 0,
          roundStatus: RoundStatus.playing,
          roundScores: const {},
        ),
      );

      final engine = TresDosGameEngine();
      final selection = GameStateFixtures.tresDosPlaySelection(
        pid: pid1,
        usedCard: usedCard,
      );
      final action = PlayCardAction(usedCard: usedCard, performedById: pid1);

      final result = engine.validateAction(state, selection, action);
      expect(result.result, isFalse);
    });

    test('3+2 round end increments score, sets winner, and ends the match', () {
      final playCard = GameStateFixtures.card(
        id: 'play_9',
        rank: '9',
        suit: '♣',
      );

      // Before the play: 6 cards.
      // After playing 9: remaining 5 cards are 3x3 + 2x2 => 3+2.
      final p1Hand = [
        GameStateFixtures.card(id: 'p1_3a', rank: '3', suit: '♠'),
        GameStateFixtures.card(id: 'p1_3b', rank: '3', suit: '♥'),
        GameStateFixtures.card(id: 'p1_3c', rank: '3', suit: '♦'),
        GameStateFixtures.card(id: 'p1_2a', rank: '2', suit: '♣'),
        GameStateFixtures.card(id: 'p1_2b', rank: '2', suit: '♦'),
        playCard,
      ];

      final state = GameStateFixtures.tresDosTwoPlayerState(
        gameStatus: GameStatus.inProgress,
        controllerId: pid1,
        currentTurnPlayerId: pid1,
        deck: [GameStateFixtures.card(id: 'deck_1', rank: 'A', suit: '♠')],
        playingArea: [],
        p1Hand: p1Hand,
        p2Hand: const [],
        scores: {pid1: 0, pid2: 0},
        round: Round(
          id: 0,
          roundStatus: RoundStatus.playing,
          roundScores: const {},
        ),
      );

      final engine = TresDosGameEngine();
      final selection = GameStateFixtures.tresDosPlaySelection(
        pid: pid1,
        usedCard: playCard,
      );
      final action = PlayCardAction(usedCard: playCard, performedById: pid1);

      final result = engine.performPlayAction(state, selection, action);

      // After a play, the acting seat drops back to 5 cards.
      expect(result.hands[pid1], hasLength(5));

      // Turn advanced after hand size returns to 5.
      expect(result.currentTurnPlayerId, pid2);

      // Round ended + score advanced + match over (first round wins).
      expect(result.round.roundStatus, RoundStatus.completed);
      expect(result.round.id, 0);
      expect(result.scores[pid1], 1);
      expect(result.winnerId, pid1);
      expect(result.gameStatus, GameStatus.gameOver);

      // The played card is on the table.
      expect(result.playingArea, contains(playCard));

      // Single play action => one move event.
      expect(result.cardMoveEvents, hasLength(1));
      expect(result.cardMoveEvents.single.card.id, playCard.id);

      // Verify 3+2 shape in remaining hand by valueLow counts.
      final remaining = result.hands[pid1]!;
      final counts = <int, int>{};
      for (final c in remaining) {
        counts[c.valueLow] = (counts[c.valueLow] ?? 0) + 1;
      }
      expect(counts.length, 2);
      expect(counts.values.toSet(), equals({2, 3}));
    });
  });
}

