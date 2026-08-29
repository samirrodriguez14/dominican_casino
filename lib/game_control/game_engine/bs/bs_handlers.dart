import 'package:dominican_casino/game_control/game_engine/bs/bs_state.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/general_handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/general_handlers/game_action_handler.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/models/table_slot.dart';

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
    // Stay in resolve so UI can reveal/collect before the next seat acts.
    bs.phase = BsPhase.resolve;
    bs.challengeDeadline = null;
    // Keep lastPlayedCardIds / lastClaimPid for the reveal banner.

    final loserId = honest ? action.performedById : claimer;
    final pileCards = List<PlayingCardModel>.from(state.playingArea);

    // Collect animates as settlement after the reveal beat (not instant flight).
    state.cardMoveEvents = [];
    state.settlementEvents = EventHandler.generatePileToHandEvents(
      cards: pileCards,
      receiverId: loserId,
      performedBy: action.performedById,
    );

    state.playingArea.clear();
    state.tableOrder.clear();
    (state.hands[loserId] ??= []).addAll(pileCards);

    bs.pileCardIds = [];
    bs.lastClaimCount = 0;
    bs.lastClaimRank = null;
    // lastPlayedCardIds kept for reveal UI; cleared on the next claim.
    // Turn stays on the claimer until [completeResolve] after collect motion.
    state.bsState = bs;

    _checkWin(state);
    return state;
  }

  /// After reveal + pile collect animations: open the next seat's turn.
  static GameState completeResolve(GameState state) {
    final bs = state.bsState;
    if (bs == null) return state;
    state.settlementEvents = [];
    if (state.gameStatus == GameStatus.gameOver) {
      bs.phase = BsPhase.turn;
      state.bsState = bs;
      return state;
    }
    if (bs.phase != BsPhase.resolve) return state;

    final claimer = bs.lastClaimPid;
    if (claimer != null && claimer.isNotEmpty) {
      state.setTurn(GameActionHandler.getNextPlayerId(state, claimer));
    }
    bs.phase = BsPhase.turn;
    state.bsState = bs;
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
        // Winner 0; others −(sum of leftover ranks). Less negative = higher place.
        state.applyLeftoverRankFinishScores(entry.key);
        state.setTurn('');
        return;
      }
    }
  }
}

class BsGameStateHandler {
  /// Move the shuffled [GameState.deck] onto the center pile (discard shoe).
  static void stageShoeOnTable(GameState gameState) {
    if (gameState.deck.isEmpty) return;
    gameState.playingArea
      ..clear()
      ..addAll(gameState.deck);
    gameState.deck = [];
    gameState.playingAreaStacks.clear();
    gameState.tableOrder = [
      for (final c in gameState.playingArea) TableOrder.cardKey(c.id),
    ];
  }

  /// Deal the entire center shoe evenly; remainder cards go to earliest seats.
  static GameState dealAll(GameState gameState, String dealerPid) {
    // Prefer the staged center shoe (post-shuffle); fall back to a fresh deck.
    var shoe = List<PlayingCardModel>.from(
      gameState.playingArea.isNotEmpty ? gameState.playingArea : gameState.deck,
    );
    if (shoe.isEmpty) {
      shoe = Deck.shuffle(Deck.standard());
    }

    gameState.deck = [];
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

    // Round-robin deal order → interleaved flight events (one seat at a time).
    final dealSequence = <({String pid, PlayingCardModel card})>[];
    var i = 0;
    while (i < shoe.length) {
      for (final pid in players) {
        if (i >= shoe.length) break;
        final card = shoe[i];
        gameState.hands[pid]!.add(card);
        dealSequence.add((pid: pid, card: card));
        i++;
      }
    }

    for (final step in dealSequence) {
      gameState.cardMoveEvents.addAll(
        EventHandler.generateDealToHandEvent(
          [step.card],
          step.pid,
          dealerPid,
        ),
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
