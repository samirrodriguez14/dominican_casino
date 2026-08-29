import 'package:dominican_casino/game_control/game_engine/bs/bs_state.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/general_handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/general_handlers/game_action_handler.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';

/// Valid claim ranks for BS (standard deck faces).
const bsClaimRanks = [
  'A',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '10',
  'J',
  'Q',
  'K',
];

class BsRulesHandler {
  static List<PlayAction> getAvailableActions(
    GameState gameState,
    CurrentCardSelection selection,
  ) {
    final bs = gameState.bsState;
    if (bs == null || bs.phase != BsPhase.turn) return const [];
    if (gameState.currentTurnPlayerId != selection.pid) return const [];

    final cards = _handSelection(selection);
    if (cards.isEmpty || cards.length > 4) return const [];

    final hand = gameState.hands[selection.pid] ?? const <PlayingCardModel>[];
    for (final c in cards) {
      if (!hand.any((h) => h.id == c.id)) return const [];
    }

    // Rank filled by the claim picker before perform.
    return [
      ClaimPlayAction(
        cards: cards,
        claimedRank: '',
        performedById: selection.pid,
      ),
    ];
  }

  static List<OutOfTurnAction> getOutOfTurnActions(
    GameState gameState,
    String pid,
  ) {
    final bs = gameState.bsState;
    if (bs == null || bs.phase != BsPhase.challenge) return const [];
    if (pid.isEmpty || pid == bs.lastClaimPid) return const [];
    if (bs.challengerPid != null) return const [];
    if (!gameState.playersInfo.containsKey(pid)) return const [];

    final deadline = bs.challengeDeadline;
    if (deadline != null && !deadline.isAfter(DateTime.now().toUtc())) {
      return [AcceptClaimAction(performedById: pid)];
    }
    return [CallBluffAction(performedById: pid)];
  }

  static ValidateResult validateClaimPlay(
    GameState gameState,
    CurrentCardSelection selection,
    ClaimPlayAction action,
  ) {
    final bs = gameState.bsState;
    if (bs == null) {
      return ValidateResult.failure('BS state missing');
    }
    if (bs.phase != BsPhase.turn) {
      return ValidateResult.failure('Not in play phase');
    }
    if (gameState.currentTurnPlayerId != action.performedById) {
      return ValidateResult.notTurn();
    }
    if (action.cards.isEmpty || action.cards.length > 4) {
      return ValidateResult.failure('Play 1–4 cards');
    }
    final rank = action.claimedRank.trim().toUpperCase();
    if (!bsClaimRanks.contains(rank)) {
      return ValidateResult.failure('Invalid claimed rank');
    }
    final hand = gameState.hands[action.performedById] ?? const [];
    for (final c in action.cards) {
      if (!hand.any((h) => h.id == c.id)) {
        return ValidateResult.failure('Card not in hand');
      }
    }
    return ValidateResult.success();
  }

  static ValidateResult validateOutOfTurn(
    GameState gameState,
    OutOfTurnAction action,
  ) {
    final bs = gameState.bsState;
    if (bs == null || bs.phase != BsPhase.challenge) {
      return ValidateResult.failure('No active challenge');
    }
    if (bs.challengerPid != null) {
      return ValidateResult.failure('Already challenged');
    }
    if (!gameState.playersInfo.containsKey(action.performedById)) {
      return ValidateResult.failure('Not seated');
    }

    if (action is CallBluffAction) {
      if (action.performedById == bs.lastClaimPid) {
        return ValidateResult.failure('Cannot call own claim');
      }
      final deadline = bs.challengeDeadline;
      if (deadline != null && !deadline.isAfter(DateTime.now().toUtc())) {
        return ValidateResult.failure('Challenge window closed');
      }
      return ValidateResult.success();
    }

    if (action is AcceptClaimAction) {
      final deadline = bs.challengeDeadline;
      if (deadline == null || deadline.isAfter(DateTime.now().toUtc())) {
        return ValidateResult.failure('Challenge still open');
      }
      return ValidateResult.success();
    }

    return ValidateResult.failure('Unknown out-of-turn action');
  }

  static List<PlayingCardModel> _handSelection(CurrentCardSelection selection) {
    if (selection.selectedCards.isNotEmpty) {
      return List<PlayingCardModel>.from(selection.selectedCards);
    }
    if (selection.selectedCard != null) {
      return [selection.selectedCard!];
    }
    return const [];
  }
}

class BsPlayActionHandler {
  static GameState handleClaimPlay(GameState state, ClaimPlayAction action) {
    final bs = state.bsState ?? BsState();
    final pid = action.performedById;
    final hand = state.hands[pid]!;
    final played = <PlayingCardModel>[];

    for (final card in action.cards) {
      final idx = hand.indexWhere((c) => c.id == card.id);
      if (idx < 0) continue;
      played.add(hand.removeAt(idx));
    }

    for (final card in played) {
      state.placeCardOnTable(card);
    }

    final rank = action.claimedRank.trim().toUpperCase();
    bs.phase = BsPhase.challenge;
    bs.lastClaimPid = pid;
    bs.lastClaimCount = played.length;
    bs.lastClaimRank = rank;
    bs.lastPlayedCardIds = played.map((c) => c.id).toList();
    bs.pileCardIds = [
      ...bs.pileCardIds,
      ...played.map((c) => c.id),
    ];
    // Clear prior resolve banner when a new claim starts.
    bs.challengerPid = null;
    bs.wasBluffing = null;
    bs.challengeDeadline =
        DateTime.now().toUtc().add(BsState.challengeWindow);
    state.bsState = bs;
    return state;
  }
}

class BsOutOfTurnHandler {
  static GameState handleCallBluff(GameState state, CallBluffAction action) {
    final bs = state.bsState!;
    final claimer = bs.lastClaimPid!;
    final claimedRank = (bs.lastClaimRank ?? '').toUpperCase();
    final lastIds = bs.lastPlayedCardIds.toSet();

    final played = state.playingArea
        .where((c) => lastIds.contains(c.id))
        .toList();

    final honest = played.isNotEmpty &&
        played.length == bs.lastClaimCount &&
        played.every((c) => c.rank.toUpperCase() == claimedRank);

    bs.challengerPid = action.performedById;
    bs.wasBluffing = !honest;
    bs.phase = BsPhase.resolve;

    final loserId = honest ? action.performedById : claimer;
    final pileCards = List<PlayingCardModel>.from(state.playingArea);

    state.cardMoveEvents = EventHandler.generatePileToHandEvents(
      cards: pileCards,
      receiverId: loserId,
      performedBy: action.performedById,
    );

    state.playingArea.clear();
    state.tableOrder.clear();
    (state.hands[loserId] ??= []).addAll(pileCards);

    final nextTurn = GameActionHandler.getNextPlayerId(state, claimer);
    bs.phase = BsPhase.turn;
    bs.pileCardIds = [];
    bs.lastPlayedCardIds = [];
    bs.challengeDeadline = null;
    bs.lastClaimCount = 0;
    bs.lastClaimRank = null;
    // Keep lastClaimPid / challengerPid / wasBluffing for result banner.
    bs.wasBluffing = !honest;
    bs.challengerPid = action.performedById;
    bs.lastClaimPid = claimer;
    state.bsState = bs;
    state.setTurn(nextTurn);

    _checkWin(state);
    return state;
  }

  static GameState handleAcceptClaim(GameState state, AcceptClaimAction action) {
    final bs = state.bsState!;
    final claimer = bs.lastClaimPid!;
    state.cardMoveEvents = [];
    state.settlementEvents = [];

    final nextTurn = GameActionHandler.getNextPlayerId(state, claimer);
    bs.phase = BsPhase.turn;
    bs.lastPlayedCardIds = [];
    bs.lastClaimPid = null;
    bs.lastClaimCount = 0;
    bs.lastClaimRank = null;
    bs.challengeDeadline = null;
    bs.challengerPid = null;
    bs.wasBluffing = null;
    bs.pileCardIds = state.playingArea.map((c) => c.id).toList();
    state.bsState = bs;
    state.setTurn(nextTurn);

    _checkWin(state);
    return state;
  }

  static void _checkWin(GameState state) {
    for (final entry in state.hands.entries) {
      if (entry.value.isEmpty && state.playersInfo.containsKey(entry.key)) {
        state.winnerId = entry.key;
        state.gameStatus = GameStatus.gameOver;
        state.round.roundStatus = RoundStatus.completed;
        state.scores[entry.key] = (state.scores[entry.key] ?? 0) + 1;
        state.setTurn('');
        return;
      }
    }
  }
}

class BsGameStateHandler {
  /// Deal the entire deck evenly; remainder cards go to earliest seats.
  static GameState dealAll(GameState gameState, String dealerPid) {
    gameState.deck = Deck.shuffle(Deck.standard());
    gameState.playingArea.clear();
    gameState.playingAreaStacks.clear();
    gameState.tableOrder.clear();
    gameState.cardMoveEvents = [];
    gameState.settlementEvents = [];

    final players = gameState.playersInfo.keys.toList()..sort();
    for (final pid in players) {
      gameState.hands[pid] = [];
      gameState.playersDeck[pid] = [];
    }

    final deck = List<PlayingCardModel>.from(gameState.deck);
    gameState.deck = [];
    var i = 0;
    while (i < deck.length) {
      for (final pid in players) {
        if (i >= deck.length) break;
        gameState.hands[pid]!.add(deck[i]);
        i++;
      }
    }

    for (final pid in players) {
      final dealt = gameState.hands[pid]!;
      gameState.cardMoveEvents.addAll(
        EventHandler.generateDealToHandEvent(dealt, pid, dealerPid),
      );
    }

    gameState.bsState = BsState();
    gameState.round.roundStatus = RoundStatus.playing;
    gameState.setTurn(
      GameActionHandler.getNextPlayerId(gameState, dealerPid),
    );
    return gameState;
  }
}
