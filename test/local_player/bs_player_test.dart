import 'package:dominican_casino/game_control/game_engine/bs/bs_game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/bs/bs_state.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/local_player/bs_player.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(BsPlayer.clearMemory);

  group('callBluffProbability', () {
    test('impossible claim always calls', () {
      // 3 claimed, I hold 2 → only 2 left in the wild → impossible
      expect(
        BsPlayer.callBluffProbability(
          claimCount: 3,
          myRankCount: 2,
          seats: 6,
        ),
        1.0,
      );
    });

    test('single card is almost never called', () {
      final p = BsPlayer.callBluffProbability(
        claimCount: 1,
        myRankCount: 0,
        seats: 4,
      );
      expect(p, lessThanOrEqualTo(0.05));
    });

    test('tight 2-of-2 is moderate and rises with seats', () {
      final p3 = BsPlayer.callBluffProbability(
        claimCount: 2,
        myRankCount: 2,
        seats: 3,
      );
      final p6 = BsPlayer.callBluffProbability(
        claimCount: 2,
        myRankCount: 2,
        seats: 6,
      );
      expect(p3, greaterThan(0.05));
      expect(p3, lessThan(0.45));
      expect(p6, greaterThan(p3));
    });

    test('loose multi-card claim stays low', () {
      final p = BsPlayer.callBluffProbability(
        claimCount: 2,
        myRankCount: 0,
        seats: 4,
      );
      expect(p, lessThan(0.25));
    });
  });

  group('reveal memory', () {
    test('skips Call BS when claimer re-plays known gifted cards', () {
      BsPlayer.debugSetKnown(
        gameId: 'g1',
        holderId: 'p2',
        rank: 'K',
        count: 4,
      );
      expect(
        BsPlayer.shouldSkipCallFromMemory(
          gameId: 'g1',
          claimerId: 'p2',
          rank: 'K',
          claimCount: 4,
        ),
        isTrue,
      );
      expect(
        BsPlayer.shouldSkipCallFromMemory(
          gameId: 'g1',
          claimerId: 'p2',
          rank: 'K',
          claimCount: 3,
        ),
        isTrue,
      );
      // More than we saw them take → still decide normally.
      expect(
        BsPlayer.shouldSkipCallFromMemory(
          gameId: 'g1',
          claimerId: 'p2',
          rank: 'K',
          claimCount: 5,
        ),
        isFalse,
      );
    });

    test('failed Call BS records cards on the challenger', () {
      final engine = BsGameEngine();
      var state = _baseState();
      final claim = state.hands['p1']!.where((c) => c.rank == 'K').take(2).toList();
      expect(claim.length, 2);

      state = engine.performPlayAction(
        state,
        CurrentCardSelection(
          pid: 'p1',
          selectedCard: null,
          selectedCards: claim,
          selectedStacks: const [],
        ),
        ClaimPlayAction(
          cards: claim,
          claimedRank: 'K',
          performedById: 'p1',
        ),
      );

      state = engine.performOutOfTurnAction(
        state,
        CallBluffAction(performedById: 'p2'),
      );
      expect(state.bsState?.wasBluffing, isFalse);

      BsPlayer.syncMemory(state);
      expect(BsPlayer.knownRankCount(state.id, 'p2', 'K'), 2);
      expect(BsPlayer.knownRankCount(state.id, 'p1', 'K'), 0);
    });

    test('maybeCallBluff returns null for known re-play', () {
      const gameId = 'mem-game';
      BsPlayer.debugSetKnown(
        gameId: gameId,
        holderId: 'p2',
        rank: 'Q',
        count: 3,
      );
      final state = _challengeState(
        gameId: gameId,
        claimer: 'p2',
        rank: 'Q',
        count: 3,
      );
      expect(BsPlayer.maybeCallBluff('p1', state), isNull);
      expect(BsPlayer.maybeCallBluff('p3', state), isNull);
    });
  });
}

GameState _baseState() {
  const p1 = 'p1';
  const p2 = 'p2';
  const p3 = 'p3';
  return GameState(
    gameStatus: GameStatus.inProgress,
    gameMode: GameMode.bs,
    id: 'bs-mem',
    controllerId: p1,
    started: true,
    currentTurnPlayerId: p1,
    deck: [],
    scores: {p1: 0, p2: 0, p3: 0},
    extraPoints: 0,
    extraPointsHolderId: '',
    playingArea: [],
    playingAreaStacks: [],
    hands: {
      p1: [
        Deck.card(id: 'k1', rank: 'K', suit: '♠'),
        Deck.card(id: 'k2', rank: 'K', suit: '♥'),
        Deck.card(id: 'a3', rank: '4', suit: '♦'),
      ],
      p2: [
        Deck.card(id: 'b1', rank: '2', suit: '♠'),
        Deck.card(id: 'b2', rank: '3', suit: '♥'),
      ],
      p3: [
        Deck.card(id: 'c1', rank: 'A', suit: '♣'),
        Deck.card(id: 'c2', rank: '7', suit: '♠'),
      ],
    },
    playersDeck: {p1: [], p2: [], p3: []},
    lastTookCardId: '',
    cardMoveEvents: [],
    round: Round(id: 0, roundStatus: RoundStatus.playing, roundScores: {}),
    winnerId: null,
    playersInfo: {
      p1: {'name': 'P1'},
      p2: {'name': 'P2'},
      p3: {'name': 'P3'},
    },
    bsState: BsState(),
    botPlayerIds: const [p2, p3],
    isLocalBot: true,
  );
}

GameState _challengeState({
  required String gameId,
  required String claimer,
  required String rank,
  required int count,
}) {
  return GameState(
    gameStatus: GameStatus.inProgress,
    gameMode: GameMode.bs,
    id: gameId,
    controllerId: 'p1',
    started: true,
    currentTurnPlayerId: claimer,
    deck: [],
    scores: const {'p1': 0, 'p2': 0, 'p3': 0},
    extraPoints: 0,
    extraPointsHolderId: '',
    playingArea: List.generate(
      count,
      (i) => Deck.card(id: 'c$i', rank: rank, suit: '♠'),
    ),
    playingAreaStacks: [],
    hands: {
      'p1': <PlayingCardModel>[],
      'p2': <PlayingCardModel>[],
      'p3': <PlayingCardModel>[],
    },
    playersDeck: const {'p1': [], 'p2': [], 'p3': []},
    lastTookCardId: '',
    cardMoveEvents: [],
    round: Round(id: 0, roundStatus: RoundStatus.playing, roundScores: {}),
    winnerId: null,
    playersInfo: const {
      'p1': {'name': 'P1'},
      'p2': {'name': 'P2'},
      'p3': {'name': 'P3'},
    },
    bsState: BsState(
      phase: BsPhase.challenge,
      lastClaimPid: claimer,
      lastClaimRank: rank,
      lastClaimCount: count,
      lastPlayedCardIds: List.generate(count, (i) => 'c$i'),
      challengeDeadline: DateTime.now().toUtc().add(const Duration(seconds: 5)),
    ),
    botPlayerIds: const ['p1', 'p3'],
    isLocalBot: true,
  );
}
