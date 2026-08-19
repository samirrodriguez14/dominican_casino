import 'package:dominican_casino/game_control/game_engine/rummy/rummy_contract.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_requirement.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_state.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/game_state_fixtures.dart';

void main() {
  const pid1 = GameStateFixtures.pid1;
  const pid2 = GameStateFixtures.pid2;

  group('Rummy (Romir) engine', () {
    test('GameRegistry.dealCounts matches Rummy table parameters', () {
      expect(GameRegistry.dealCounts(GameMode.rummy), (7, 1, 0, 1));
    });

    test(
      'deal assigns a random contract and sets empty dotted boxes',
      () async {
        final pid = pid1;
        final deck = <PlayingCardModel>[];
        // Minimal deterministic 15-card deck (2*7 + 1).
        deck.add(GameStateFixtures.card(id: 'd1', rank: '2', suit: '♠'));
        deck.add(GameStateFixtures.card(id: 'd2', rank: '3', suit: '♠'));
        deck.add(GameStateFixtures.card(id: 'd3', rank: '4', suit: '♠'));
        deck.add(GameStateFixtures.card(id: 'd4', rank: '5', suit: '♠'));
        deck.add(GameStateFixtures.card(id: 'd5', rank: '6', suit: '♠'));
        deck.add(GameStateFixtures.card(id: 'd6', rank: '7', suit: '♥'));
        deck.add(GameStateFixtures.card(id: 'd7', rank: '8', suit: '♦'));
        deck.add(GameStateFixtures.card(id: 'd8', rank: '9', suit: '♣'));
        deck.add(GameStateFixtures.card(id: 'd9', rank: '10', suit: '♥'));
        deck.add(GameStateFixtures.card(id: 'd10', rank: 'J', suit: '♠'));
        deck.add(GameStateFixtures.card(id: 'd11', rank: 'Q', suit: '♣'));
        deck.add(GameStateFixtures.card(id: 'd12', rank: 'K', suit: '♦'));
        deck.add(GameStateFixtures.card(id: 'd13', rank: 'A', suit: '♠'));
        deck.add(GameStateFixtures.card(id: 'd14', rank: '2', suit: '♥'));
        deck.add(GameStateFixtures.card(id: 'd15', rank: '3', suit: '♦'));

        final state = GameStateFixtures.rummyTwoPlayerState(
          gameStatus: GameStatus.inProgress,
          controllerId: pid,
          currentTurnPlayerId: '',
          deck: deck, // modifiable list
          playingArea: [],
          p1Hand: [],
          p2Hand: [],
          scores: {pid1: 0, pid2: 0},
          round: Round(
            id: 0,
            roundStatus: RoundStatus.readyToDeal,
            roundScores: const {},
          ),
          rummyState: null,
        );

        final engine = RummyGameEngine();
        final next = engine.performInGameAction(state, InGameAction.deal, pid);

        expect(next.hands[pid1], hasLength(7));
        expect(next.hands[pid2], hasLength(7));
        expect(next.playingArea, hasLength(1));

        expect(next.rummyState, isNotNull);
        final contract = next.rummyState!.contract;
        expect(contract.totalCards, equals(7));
        expect(contract.requirements, hasLength(2));

        expect(next.rummyState!.boxAByPid[pid1], isEmpty);
        expect(next.rummyState!.boxBByPid[pid1], isEmpty);
      },
    );

    test('deal seats 3 and 4 players with a contract box each', () {
      List<PlayingCardModel> deckOf(int n) => [
        for (var i = 0; i < n; i++)
          GameStateFixtures.card(
            id: 'c$i',
            rank: '${(i % 9) + 2}',
            suit: const ['♠', '♥', '♦', '♣'][i % 4],
          ),
      ];

      GameState tableFor(List<String> pids) {
        return GameState(
          gameStatus: GameStatus.inProgress,
          gameMode: GameMode.rummy,
          id: 'rummy_multi',
          controllerId: pids.first,
          started: true,
          currentTurnPlayerId: '',
          deck: deckOf(pids.length * 7 + 1),
          scores: {for (final p in pids) p: 0},
          extraPoints: 0,
          extraPointsHolderId: '',
          playingArea: [],
          playingAreaStacks: const [],
          hands: {for (final p in pids) p: <PlayingCardModel>[]},
          playersDeck: {for (final p in pids) p: <PlayingCardModel>[]},
          lastTookCardId: '',
          cardMoveEvents: const [],
          round: Round(
            id: 0,
            roundStatus: RoundStatus.readyToDeal,
            roundScores: const {},
          ),
          winnerId: '',
          playersInfo: {
            for (final p in pids) p: {'name': p},
          },
        );
      }

      final engine = RummyGameEngine();
      for (final pids in [
        const ['p1', 'p2', 'p3'],
        const ['p1', 'p2', 'p3', 'p4'],
      ]) {
        final next = engine.performInGameAction(
          tableFor(pids),
          InGameAction.deal,
          pids.first,
        );
        for (final pid in pids) {
          expect(next.hands[pid], hasLength(7));
          expect(next.rummyState!.boxAByPid[pid], isEmpty);
          expect(next.rummyState!.boxBByPid[pid], isEmpty);
        }
        expect(next.playingArea, hasLength(1));
      }
    });

    test('validateAction rejects Play when hand size is not 8', () {
      final discardCard = GameStateFixtures.card(
        id: 'extra_1',
        rank: '9',
        suit: '♣',
      );

      final state = GameStateFixtures.rummyTwoPlayerState(
        gameStatus: GameStatus.inProgress,
        controllerId: pid1,
        currentTurnPlayerId: pid1,
        deck: [GameStateFixtures.card(id: 't1', rank: '2', suit: '♠')],
        playingArea: [GameStateFixtures.card(id: 'x1', rank: '3', suit: '♥')],
        p1Hand: [
          GameStateFixtures.card(id: 'c1', rank: '2', suit: '♣'),
          GameStateFixtures.card(id: 'c2', rank: '3', suit: '♣'),
          GameStateFixtures.card(id: 'c3', rank: '4', suit: '♣'),
          GameStateFixtures.card(id: 'c4', rank: '5', suit: '♣'),
          GameStateFixtures.card(id: 'c5', rank: '6', suit: '♣'),
          GameStateFixtures.card(id: 'c6', rank: '7', suit: '♣'),
          GameStateFixtures.card(id: 'c7', rank: '8', suit: '♣'),
        ], // length 7
        p2Hand: const [],
        scores: {pid1: 0, pid2: 0},
      );

      final selection = GameStateFixtures.rummyPlaySelection(
        pid: pid1,
        usedCard: discardCard,
      );

      final action = PlayCardAction(usedCard: discardCard, performedById: pid1);
      final engine = RummyGameEngine();
      final result = engine.validateAction(state, selection, action);
      expect(result.result, isFalse);
    });

    test('validateAction rejects Take when hand size is 8', () {
      final tableCard = GameStateFixtures.card(
        id: 'table_1',
        rank: '10',
        suit: '♦',
      );

      final state = GameStateFixtures.rummyTwoPlayerState(
        gameStatus: GameStatus.inProgress,
        controllerId: pid1,
        currentTurnPlayerId: pid1,
        deck: const [],
        playingArea: [tableCard],
        p1Hand: [
          GameStateFixtures.card(id: 'c1', rank: '2', suit: '♣'),
          GameStateFixtures.card(id: 'c2', rank: '3', suit: '♣'),
          GameStateFixtures.card(id: 'c3', rank: '4', suit: '♣'),
          GameStateFixtures.card(id: 'c4', rank: '5', suit: '♣'),
          GameStateFixtures.card(id: 'c5', rank: '6', suit: '♣'),
          GameStateFixtures.card(id: 'c6', rank: '7', suit: '♣'),
          GameStateFixtures.card(id: 'c7', rank: '8', suit: '♣'),
          GameStateFixtures.card(id: 'c8', rank: '9', suit: '♣'),
        ], // length 8
        p2Hand: const [],
        scores: {pid1: 0, pid2: 0},
      );

      final selection = GameStateFixtures.rummyTakeSelection(
        pid: pid1,
        usedCard: tableCard,
      );

      final action = TakeCardAction(
        usedCard: tableCard,
        targetCard: tableCard,
        performedById: pid1,
        fromZone: ZoneType.table,
      );

      final engine = RummyGameEngine();
      final result = engine.validateAction(state, selection, action);
      expect(result.result, isFalse);
    });

    test('valid boxes + discard => gameOver with winnerId', () {
      final contract = RummyContract(
        requirements: [RummyRequirement.run(5), RummyRequirement.set(2)],
      );

      // Hand after discard (7 cards): run of 5 + set of 2.
      final run5 = [
        GameStateFixtures.card(id: '2s', rank: '2', suit: '♠'),
        GameStateFixtures.card(id: '3s', rank: '3', suit: '♠'),
        GameStateFixtures.card(id: '4s', rank: '4', suit: '♠'),
        GameStateFixtures.card(id: '5s', rank: '5', suit: '♠'),
        GameStateFixtures.card(id: '6s', rank: '6', suit: '♠'),
      ];
      final set2 = [
        GameStateFixtures.card(id: '9h', rank: '9', suit: '♥'),
        GameStateFixtures.card(id: '9c', rank: '9', suit: '♣'),
      ];

      // Extra 8th card that will be discarded.
      final extra = GameStateFixtures.card(id: 'Qh', rank: 'Q', suit: '♥');

      final hand8 = [...run5, ...set2, extra];

      final state = GameStateFixtures.rummyTwoPlayerState(
        gameStatus: GameStatus.inProgress,
        controllerId: pid1,
        currentTurnPlayerId: pid1,
        deck: [GameStateFixtures.card(id: 'dX', rank: 'A', suit: '♠')],
        playingArea: [
          GameStateFixtures.card(id: 'disc1', rank: 'K', suit: '♣'),
        ],
        p1Hand: [...hand8],
        p2Hand: const [],
        scores: {pid1: 0, pid2: 0},
        round: Round(
          id: 0,
          roundStatus: RoundStatus.playing,
          roundScores: const {},
        ),
        rummyState: RummyState(
          contract: contract,
          boxAByPid: {pid1: run5.map((c) => c.id).toList(), pid2: const []},
          boxBByPid: {pid1: set2.map((c) => c.id).toList(), pid2: const []},
        ),
      );

      final selection = GameStateFixtures.rummyPlaySelection(
        pid: pid1,
        usedCard: extra,
      );
      final action = PlayCardAction(usedCard: extra, performedById: pid1);

      final engine = RummyGameEngine();
      final next = engine.performPlayAction(state, selection, action);

      expect(next.gameStatus, GameStatus.gameOver);
      expect(next.winnerId, pid1);
      expect(next.round.roundStatus, RoundStatus.completed);
      expect(next.round.id, equals(0));
      expect(next.scores[pid1], equals(1));
    });

    test('wrong boxes do not end the round', () {
      final contract = RummyContract(
        requirements: [RummyRequirement.run(5), RummyRequirement.set(2)],
      );

      final run5 = [
        GameStateFixtures.card(id: '2s', rank: '2', suit: '♠'),
        GameStateFixtures.card(id: '3s', rank: '3', suit: '♠'),
        GameStateFixtures.card(id: '4s', rank: '4', suit: '♠'),
        GameStateFixtures.card(id: '5s', rank: '5', suit: '♠'),
        GameStateFixtures.card(
          id: '6s',
          rank: '8',
          suit: '♠',
        ), // gap => not a run
      ];
      final set2 = [
        GameStateFixtures.card(id: '9h', rank: '9', suit: '♥'),
        GameStateFixtures.card(id: '9c', rank: '9', suit: '♣'),
      ];

      final extra = GameStateFixtures.card(id: 'Qh', rank: 'Q', suit: '♥');
      final hand8 = [...run5, ...set2, extra];

      final state = GameStateFixtures.rummyTwoPlayerState(
        gameStatus: GameStatus.inProgress,
        controllerId: pid1,
        currentTurnPlayerId: pid1,
        deck: const [],
        playingArea: [
          GameStateFixtures.card(id: 'disc1', rank: 'K', suit: '♣'),
        ],
        p1Hand: hand8,
        p2Hand: const [],
        scores: {pid1: 0, pid2: 0},
        rummyState: RummyState(
          contract: contract,
          // Still "box" them as if they're run+set, but the run skips a rank.
          boxAByPid: {pid1: run5.map((c) => c.id).toList(), pid2: const []},
          boxBByPid: {pid1: set2.map((c) => c.id).toList(), pid2: const []},
        ),
      );

      final selection = GameStateFixtures.rummyPlaySelection(
        pid: pid1,
        usedCard: extra,
      );
      final action = PlayCardAction(usedCard: extra, performedById: pid1);

      final engine = RummyGameEngine();
      final next = engine.performPlayAction(state, selection, action);

      expect(next.gameStatus, GameStatus.inProgress);
      expect(next.winnerId, isEmpty);
      // Turn advanced because hand returned to 7.
      expect(next.currentTurnPlayerId, pid2);
    });

    test('deck empty after take => reshuffle discard into deck', () {
      final discardCard = GameStateFixtures.card(
        id: 'discard_1',
        rank: 'K',
        suit: '♣',
      );
      final drawCard = GameStateFixtures.card(
        id: 'deck_1',
        rank: 'A',
        suit: '♠',
      );

      final state = GameStateFixtures.rummyTwoPlayerState(
        gameStatus: GameStatus.inProgress,
        controllerId: pid1,
        currentTurnPlayerId: pid1,
        deck: [drawCard], // deck will become empty after the take
        playingArea: [discardCard],
        p1Hand: [
          GameStateFixtures.card(id: 'c1', rank: '2', suit: '♣'),
          GameStateFixtures.card(id: 'c2', rank: '3', suit: '♣'),
          GameStateFixtures.card(id: 'c3', rank: '4', suit: '♣'),
          GameStateFixtures.card(id: 'c4', rank: '5', suit: '♣'),
          GameStateFixtures.card(id: 'c5', rank: '6', suit: '♣'),
          GameStateFixtures.card(id: 'c6', rank: '7', suit: '♣'),
          GameStateFixtures.card(id: 'c7', rank: '8', suit: '♣'),
        ], // length 7 => must take
        p2Hand: const [],
        scores: {pid1: 0, pid2: 0},
        rummyState: null,
      );

      final selection = GameStateFixtures.rummyTakeSelection(
        pid: pid1,
        usedCard: drawCard,
      );

      final action = TakeCardAction(
        usedCard: drawCard,
        targetCard: drawCard,
        performedById: pid1,
        fromZone: ZoneType.gameDeck,
      );

      final engine = RummyGameEngine();
      final next = engine.performPlayAction(state, selection, action);

      expect(next.hands[pid1], hasLength(8));
      // After reshuffle, discard pile should be empty and deck should now
      // contain what used to be discard.
      expect(next.playingArea, isEmpty);
      expect(next.deck, hasLength(1));
    });
  });
}
