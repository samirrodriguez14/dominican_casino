import 'package:dominican_casino/game_control/game_engine/bs/bs_game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/bs/bs_state.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const p1 = 'p1';
  const p2 = 'p2';
  const p3 = 'p3';

  GameState baseState() {
    return GameState(
      gameStatus: GameStatus.inProgress,
      gameMode: GameMode.bs,
      id: 'g1',
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
          Deck.card(id: 'a1', rank: '10', suit: '♠'),
          Deck.card(id: 'a2', rank: '10', suit: '♥'),
          Deck.card(id: 'a3', rank: '4', suit: '♦'),
        ],
        p2: [
          Deck.card(id: 'b1', rank: 'K', suit: '♠'),
          Deck.card(id: 'b2', rank: '2', suit: '♥'),
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
    );
  }

  CurrentCardSelection sel(String pid, List<PlayingCardModel> cards) {
    return CurrentCardSelection(
      pid: pid,
      selectedCard: null,
      selectedCards: cards,
      selectedStacks: const [],
    );
  }

  test('dealAll distributes every card', () {
    final engine = BsGameEngine();
    var state = GameState.create('g', p1, GameMode.bs);
    state.playersInfo[p1] = {'name': 'P1'};
    state.playersInfo[p2] = {'name': 'P2'};
    state.playersInfo[p3] = {'name': 'P3'};
    state.hands[p1] = [];
    state.hands[p2] = [];
    state.hands[p3] = [];
    state.gameStatus = GameStatus.inProgress;
    state.round.roundStatus = RoundStatus.readyToDeal;

    state = engine.performInGameAction(state, InGameAction.deal, p1);

    final total =
        state.hands.values.fold<int>(0, (n, h) => n + h.length);
    expect(total, 52);
    expect(state.deck, isEmpty);
    expect(state.bsState?.phase, BsPhase.turn);
    expect(state.round.roundStatus, RoundStatus.playing);
  });

  test('honest claim: challenger takes the pile', () {
    final engine = BsGameEngine();
    var state = baseState();
    final hand = state.hands[p1]!;
    final tens = hand.where((c) => c.rank == '10').toList();

    state = engine.performPlayAction(
      state,
      sel(p1, tens),
      ClaimPlayAction(cards: tens, claimedRank: '10', performedById: p1),
    );
    expect(state.bsState?.phase, BsPhase.challenge);
    expect(state.playingArea.length, 2);

    state = engine.performOutOfTurnAction(
      state,
      CallBluffAction(performedById: p2),
    );

    expect(state.bsState?.phase, BsPhase.turn);
    expect(state.playingArea, isEmpty);
    expect(state.hands[p2]!.length, 4); // 2 + pile
    expect(state.currentTurnPlayerId, p2); // next after p1
  });

  test('bluff claim: claimer takes the pile', () {
    final engine = BsGameEngine();
    var state = baseState();
    final bluff = [state.hands[p1]!.first]; // a 10 claimed as K

    state = engine.performPlayAction(
      state,
      sel(p1, bluff),
      ClaimPlayAction(cards: bluff, claimedRank: 'K', performedById: p1),
    );

    state = engine.performOutOfTurnAction(
      state,
      CallBluffAction(performedById: p3),
    );

    expect(state.playingArea, isEmpty);
    expect(state.hands[p1]!.any((c) => c.id == bluff.first.id), isTrue);
    expect(state.currentTurnPlayerId, p2);
  });

  test('accept claim after deadline keeps pile and advances turn', () {
    final engine = BsGameEngine();
    var state = baseState();
    final card = [state.hands[p1]!.first];

    state = engine.performPlayAction(
      state,
      sel(p1, card),
      ClaimPlayAction(cards: card, claimedRank: '10', performedById: p1),
    );
    state.bsState!.challengeDeadline =
        DateTime.now().toUtc().subtract(const Duration(seconds: 1));

    state = engine.performOutOfTurnAction(
      state,
      AcceptClaimAction(performedById: p2),
    );

    expect(state.playingArea.length, 1);
    expect(state.bsState?.phase, BsPhase.turn);
    expect(state.currentTurnPlayerId, p2);
  });

  test('empty hand after accepted claim wins', () {
    final engine = BsGameEngine();
    var state = baseState();
    state.hands[p1] = [
      Deck.card(id: 'last', rank: '5', suit: '♠'),
    ];

    state = engine.performPlayAction(
      state,
      sel(p1, state.hands[p1]!),
      ClaimPlayAction(
        cards: List.from(state.hands[p1]!),
        claimedRank: '5',
        performedById: p1,
      ),
    );
    state.bsState!.challengeDeadline =
        DateTime.now().toUtc().subtract(const Duration(seconds: 1));

    state = engine.performOutOfTurnAction(
      state,
      AcceptClaimAction(performedById: p2),
    );

    expect(state.gameStatus, GameStatus.gameOver);
    expect(state.winnerId, p1);
  });
}
