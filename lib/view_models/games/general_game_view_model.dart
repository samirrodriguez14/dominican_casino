import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:dominican_casino/game_control/casino_coin_bonuses.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/casino_rules_handler.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_reaction.dart';
import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/local_player/casino_player.dart';
import 'package:dominican_casino/local_player/local_player.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/models/table_slot.dart';
import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/tutorial/tutorial_casino_factory.dart';
import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:flutter/cupertino.dart' hide Action;
import 'package:uuid/uuid.dart';

typedef ActionGuard =
    bool Function(
      TutorialAction action, {
      String? cardId,
      String? stackId,
      List<String> selectedCardIds,
    });

/// Visual home of a card widget — scopes GlobalKeys so the same card id can
/// exist in different UI slots across a rebuild without colliding.
enum CardSlot { myHand, oppHand, table, aux, inStack }

enum JoinGameResult { ok, notEnoughCoins, failed }

class DeckCoinFlight {
  const DeckCoinFlight({required this.mine, required this.amount});

  final bool mine;
  final int amount;
}

class GeneralGameViewModel extends ChangeNotifier {
  bool loading = true;
  bool tutorialMode;
  final GameRepo gameRepo;
  final GameEngine gameEngine;
  final AppRepo appRepo;
  Player player;
  String gid;
  late GameState gameState;
  bool isAnimating = false;
  bool _pendingRepoSync = false;
  bool _syncScheduled = false;
  bool _disposed = false;

  GameReaction? outgoingReaction;
  GameReaction? incomingReaction;
  StreamSubscription<GameReaction?>? _reactionSub;
  Timer? _outgoingHideTimer;
  Timer? _incomingHideTimer;
  String? _lastSeenReactionId;
  static const _reactionVisibleFor = Duration(milliseconds: 2200);
  static const _botReactCooldown = Duration(seconds: 5);
  final Random _reactionRandom = Random();
  Timer? _botReactTimer;
  DateTime? _lastBotReactAt;

  /// Round id whose gather-wash already played — skip a second overlay on repo echo.
  int? _shuffleOverlayRoundId;

  /// Coins to fly from a collected pile into an avatar after take motion.
  DeckCoinFlight? pendingDeckCoinFlight;
  int _revealedPendingMe = 0;
  int _revealedPendingOpp = 0;

  /// Destination slots stay laid out but invisible until flights land.
  final CardMotionController motion = CardMotionController();

  ActionGuard? actionGuard;

  /// Tutorial only: true when the current scripted step wants the bot to move.
  bool Function()? tutorialAllowsOpponentPlay;

  GeneralGameViewModel({
    required this.gameRepo,
    required this.gameEngine,
    required this.appRepo,
    required this.player,
    required this.gid,
    this.tutorialMode = false,
  }) {
    gameRepo.addListener(_onGameRepoChanged);
    // Motion notifies its own listeners (FlightAwareCard / ListenableBuilder).
    // Do not forward every markInFlight to the full board.
  }

  void _onGameRepoChanged() {
    if (isAnimating) {
      _pendingRepoSync = true;
      return;
    }
    _syncFromRepo();
  }

  Future<void> _syncFromRepo() async {
    if (_syncScheduled) {
      _pendingRepoSync = true;
      return;
    }
    _syncScheduled = true;
    isAnimating = true;
    notifyListeners();

    try {
      do {
        _pendingRepoSync = false;
        final nextState = gameRepo.gameState;
        if (nextState == null) break;

        final newEvents = nextState.cardMoveEvents
            .where((e) => !gameRepo.lastPlayedIds.contains(e.id))
            .toList();
        final newSettlement = nextState.settlementEvents
            .where((e) => !gameRepo.lastPlayedIds.contains(e.id))
            .toList();

        for (final e in [...newEvents, ...newSettlement]) {
          gameRepo.lastPlayedIds.add(e.id);
        }

        final shuffledIn =
            gameState.round.roundStatus == RoundStatus.completed &&
            nextState.round.roundStatus == RoundStatus.readyToDeal;
        final startedIn =
            !gameState.started &&
            nextState.started &&
            nextState.round.roundStatus == RoundStatus.readyToDeal;
        final alreadyPlayed = _shuffleOverlayRoundId == nextState.round.id;
        final oldMe = gameState.pendingCoinsFor(me);
        final oppId = opp;
        final oldOpp = oppId == null ? 0 : gameState.pendingCoinsFor(oppId);

        if ((shuffledIn || startedIn) && !alreadyPlayed) {
          _shuffleOverlayRoundId = nextState.round.id;
          await _playShuffleMotion(
            onSquared: () async {
              await _commitStateWithMotion(
                nextState,
                newEvents,
                settlementEvents: newSettlement,
              );
              motion.setShuffling(false);
            },
          );
        } else {
          await _commitStateWithMotion(
            nextState,
            newEvents,
            settlementEvents: newSettlement,
          );
        }

        final meGain = gameState.pendingCoinsFor(me) - oldMe;
        final oppGain = oppId == null
            ? 0
            : gameState.pendingCoinsFor(oppId) - oldOpp;
        _queueDeckCoinFlight(meGain: meGain, oppGain: oppGain);

        final botId = gameState.localBotPid ?? opp;
        final botPlayed =
            botId != null &&
            newEvents.any(
              (e) =>
                  e.performedBy == botId && e.from.type == ZoneType.playerHand,
            );
        if (botPlayed) {
          final botTook = newEvents.any(
            (e) => e.performedBy == botId && e.to.type == ZoneType.playerDeck,
          );
          _maybeBotReact(took: botTook, botPlayed: true);
        }
      } while (_pendingRepoSync);
    } catch (e) {
      developer.log("GameViewModel._syncFromRepo Error $e");
    } finally {
      motion.setShuffling(false);
      isAnimating = false;
      _syncScheduled = false;
      notifyListeners();
      if (_pendingRepoSync) {
        _pendingRepoSync = false;
        _onGameRepoChanged();
      }
    }
  }

  /// 1) Capture origins from current keys
  /// 2) Mark cards in-flight + commit (dest slots invisible; overlay owns paint)
  /// 3) Fly overlays immediately from captured origins (no blank frames)
  /// 4) Reveal under overlay, then drop overlay
  /// 5) Brief settle so dealSame / round controls don't pop in early
  ///
  /// [settlementEvents] are end-of-round leftovers only (see GameState).
  /// They animate after the play/capture batch — never inferred from zones.
  Future<void> _commitStateWithMotion(
    GameState next,
    List<CardMoveEvent> events, {
    List<CardMoveEvent> settlementEvents = const [],
  }) async {
    selectedCard = null;
    selectedCards = [];
    selectedStacks = [];

    if (settlementEvents.isNotEmpty) {
      final playOrigins = _captureOrigins(events);
      final intermediate = _stateWithLeftoversOnTable(next, settlementEvents);

      await _flyCommit(intermediate, events, playOrigins);

      // Beat so everyone can read the last play before leftovers collect.
      await Future<void>.delayed(const Duration(milliseconds: 750));

      final settleOrigins = _captureOrigins(settlementEvents);
      await _flyCommit(next, settlementEvents, settleOrigins);

      await Future<void>.delayed(const Duration(milliseconds: 320));
      return;
    }

    // When a card is played onto the table and then settled to a deck in the
    // same batch (legacy / non-settlement paths), keep the final destination.
    final deduped = <String, CardMoveEvent>{};
    for (final e in events) {
      deduped[e.card.id] = e;
    }
    final orderedEvents = deduped.values.toList();

    final origins = _captureOrigins(events);
    await _flyCommit(next, orderedEvents, origins);

    if (orderedEvents.isEmpty) return;

    final settleMs = orderedEvents.any((e) => e.to.type == ZoneType.playerDeck)
        ? 280
        : 80;
    await Future<void>.delayed(Duration(milliseconds: settleMs));
  }

  /// Visual pause state: final scores/hands, but leftovers still on the table.
  GameState _stateWithLeftoversOnTable(
    GameState next,
    List<CardMoveEvent> settlementEvents,
  ) {
    final settleIds = {for (final e in settlementEvents) e.card.id};
    final receiver = settlementEvents.first.to.holderId ?? '';

    final playersDeck = <String, List<PlayingCardModel>>{
      for (final e in next.playersDeck.entries)
        e.key: List<PlayingCardModel>.from(e.value),
    };
    if (receiver.isNotEmpty) {
      playersDeck[receiver] = (playersDeck[receiver] ?? [])
          .where((c) => !settleIds.contains(c.id))
          .toList();
    }

    final leftovers = settlementEvents.map((e) => e.card).toList();

    return GameState(
      gameStatus: next.gameStatus,
      gameMode: next.gameMode,
      id: next.id,
      controllerId: next.controllerId,
      started: next.started,
      currentTurnPlayerId: next.currentTurnPlayerId,
      deck: List<PlayingCardModel>.from(next.deck),
      scores: Map<String, dynamic>.from(next.scores),
      extraPoints: next.extraPoints,
      extraPointsHolderId: next.extraPointsHolderId,
      playingArea: leftovers,
      playingAreaStacks: [],
      hands: {
        for (final e in next.hands.entries)
          e.key: List<PlayingCardModel>.from(e.value),
      },
      playersDeck: playersDeck,
      lastTakes: {
        for (final e in next.lastTakes.entries)
          e.key: List<PlayingCardModel>.from(e.value),
      },
      lastTookCardId: next.lastTookCardId,
      cardMoveEvents: List<CardMoveEvent>.from(next.cardMoveEvents),
      settlementEvents: List<CardMoveEvent>.from(next.settlementEvents),
      round: next.round,
      winnerId: next.winnerId,
      playersInfo: Map<String, dynamic>.from(next.playersInfo),
      isLocalBot: next.isLocalBot,
      botPlayerId: next.botPlayerId,
      entryCost: next.entryCost,
      entryPaidBy: List<String>.from(next.entryPaidBy),
      payoutApplied: next.payoutApplied,
      pendingCoins: Map<String, int>.from(next.pendingCoins),
      viraosCreditedRoundId: next.viraosCreditedRoundId,
      roundTakeCoins: Map<String, int>.from(next.roundTakeCoins),
      roundSpecialCoins: Map<String, int>.from(next.roundSpecialCoins),
      roundViraoCoins: Map<String, int>.from(next.roundViraoCoins),
      tableOrder: leftovers.map((c) => TableOrder.cardKey(c.id)).toList(),
    );
  }

  Future<void> _flyCommit(
    GameState commit,
    List<CardMoveEvent> events,
    Map<String, Offset> origins,
  ) async {
    final handoff = dragHandoff;
    dragHandoff = null;

    if (events.isNotEmpty) {
      motion.markInFlight(events.map((e) => e.card.id));
    }

    _preserveMyHandOrder(commit);
    gameState = commit;
    notifyListeners();

    if (events.isEmpty) {
      motion.onFlightsAttached?.call();
      return;
    }

    final flights = events.map((e) {
      final startUp = _startFaceUpFor(e);
      final endUp = _endFaceUpFor(e);
      final handedOff = handoff != null && handoff.cardIds.contains(e.card.id);
      return CardFlightRequest(
        event: e,
        fromGlobalCenter: origins[e.card.id],
        fromKey: keyForZone(e.from),
        toKey: _resolveToKey(e),
        startFaceUp: startUp,
        endFaceUp: endUp,
        flip: startUp != endUp,
        startWidth: handedOff ? handoff.width : _widthForZone(e.from),
        endWidth: _widthForZone(e.to, cardId: e.card.id),
        hapticOnLaunch: !handedOff,
      );
    }).toList();

    await motion.run(flights);
  }

  /// Match the laid-out card size at each zone so flights grow/shrink in flight.
  double _widthForZone(Zone zone, {String? cardId}) {
    switch (zone.type) {
      case ZoneType.playerHand:
        if (zone.holderId == me) return isCasinoFamily ? 110.0 : 100.0;
        return isCasinoFamily ? 54.0 : 50.0;
      case ZoneType.table:
      case ZoneType.stack:
        return isCasinoFamily ? 72.0 : 60.0;
      case ZoneType.gameDeck:
      case ZoneType.playerDeck:
        return isCasinoFamily ? 52.0 : 60.0;
    }
  }

  Map<String, Offset> _captureOrigins(List<CardMoveEvent> events) {
    final map = <String, Offset>{};
    final handoff = dragHandoff;
    // Consume once so later settlement flights use normal GlobalKeys.
    // Width is still read in [_flyCommit] from this same instance.

    for (final e in events) {
      // First origin wins — important when a card is played then settled to a
      // deck in the same batch (keep hand/table start, not a later zone center).
      if (map.containsKey(e.card.id)) continue;

      if (handoff != null && handoff.cardIds.contains(e.card.id)) {
        map[e.card.id] = handoff.globalCenter;
        continue;
      }

      final fromSlot = _slotKeyForEventOrigin(e);
      final fromCard = _centerOf(fromSlot);
      if (fromCard != null) {
        map[e.card.id] = fromCard;
        continue;
      }
      final stackCard = _centerOf(keyForCard(e.card.id, CardSlot.inStack));
      if (stackCard != null) {
        map[e.card.id] = stackCard;
        continue;
      }
      final stackKey = _stackKeyContaining(e.card.id);
      final fromStack = _centerOf(stackKey);
      if (fromStack != null) {
        map[e.card.id] = fromStack;
        continue;
      }
      final fromZone = _centerOf(keyForZone(e.from));
      if (fromZone != null) map[e.card.id] = fromZone;
    }
    return map;
  }

  GlobalKey? _slotKeyForEventOrigin(CardMoveEvent e) {
    switch (e.from.type) {
      case ZoneType.playerHand:
        return e.from.holderId == me
            ? keyForCard(e.card.id, CardSlot.myHand)
            : keyForCard(e.card.id, CardSlot.oppHand);
      case ZoneType.table:
        // Loose table card, or already inside a stack.
        final loose = keyForCard(e.card.id, CardSlot.table);
        if (loose.currentContext != null) return loose;
        return keyForCard(e.card.id, CardSlot.inStack);
      case ZoneType.gameDeck:
        final top = keyForCard(e.card.id, CardSlot.aux);
        if (top.currentContext != null) return top;
        return deckKey;
      default:
        return null;
    }
  }

  GlobalKey? _resolveToKey(CardMoveEvent e) {
    // Loose table card — key attaches after this rebuild.
    if (gameState.playingArea.any((c) => c.id == e.card.id)) {
      return keyForCard(e.card.id, CardSlot.table);
    }

    // Inside a stack — fly to that card's fanned slot, not stack center.
    if (_cardIsInAnyStack(e.card.id)) {
      return keyForCard(e.card.id, CardSlot.inStack);
    }

    // Still in a hand (deal / draw).
    for (final pid in gameState.hands.keys) {
      if ((gameState.hands[pid] ?? []).any((c) => c.id == e.card.id)) {
        return keyForCard(
          e.card.id,
          pid == me ? CardSlot.myHand : CardSlot.oppHand,
        );
      }
    }

    // Collected decks / fallback zones.
    return keyForZone(e.to);
  }

  bool _cardIsInAnyStack(String cardId) {
    return gameState.playingAreaStacks.any(
      (s) => s.cards.any((c) => c.id == cardId),
    );
  }

  GlobalKey? _stackKeyContaining(String cardId) {
    for (final s in gameState.playingAreaStacks) {
      if (s.cards.any((c) => c.id == cardId)) {
        return keyForStack(s.id);
      }
    }
    return null;
  }

  Offset? _centerOf(GlobalKey? key) {
    if (key == null) return null;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  /// Gather visible piles to the table, wash, square on the shoe — then commit.
  Future<void> _playShuffleMotion({
    Future<void> Function()? onHidden,
    Future<void> Function()? onSquared,
  }) async {
    final sources = <ShuffleSource>[];

    void addSource(GlobalKey key, int count) {
      if (count <= 0) return;
      final origin = _centerOf(key);
      if (origin == null) return;
      sources.add(ShuffleSource(origin: origin, count: count));
    }

    addSource(deckKey, gameState.deck.length);
    addSource(myDeckKey, myCollectedCards.length);
    addSource(oppDeckKey, oppCollectedCards.length);
    final tableCount =
        gameState.playingArea.length +
        gameState.playingAreaStacks.fold<int>(0, (n, s) => n + s.cards.length);
    addSource(tableKey, tableCount);

    final center = _centerOf(tableKey);
    final deckTarget = _centerOf(deckKey) ?? center;
    if (sources.isEmpty || center == null || deckTarget == null) {
      await onHidden?.call();
      await onSquared?.call();
      return;
    }

    motion.setShuffling(true);
    await onHidden?.call();
    await motion.runShuffle(
      ShuffleRequest(sources: sources, center: center, deckTarget: deckTarget),
      onSquared: onSquared,
    );
  }

  bool _startFaceUpFor(CardMoveEvent e) {
    if (e.from.type == ZoneType.gameDeck) return false;
    if (e.from.type == ZoneType.playerHand && e.from.holderId != me) {
      return false;
    }
    return true;
  }

  bool _endFaceUpFor(CardMoveEvent e) {
    if (e.to.type == ZoneType.playerHand && e.to.holderId != me) {
      return false;
    }
    if (e.to.type == ZoneType.gameDeck) return false;
    return true;
  }

  List<PlayingCardModel> get playingAreaCards => gameState.playingArea;
  List<PlayingAreaStackModel> get playingAreaStacks =>
      gameState.playingAreaStacks;

  String get me => player.id;

  int get myExtraPoints =>
      (gameState.extraPointsHolderId == player.id) ? gameState.extraPoints : 0;
  bool get isMyTurn => gameState.currentTurnPlayerId == me;

  /// Turn is yours and motion has finished — safe to highlight and act.
  bool get canPlayTurn => isMyTurn && !isAnimating;

  /// A player is actually taking a turn — not dealing, shuffling, or waiting.
  bool get isLiveTurn =>
      !isAnimating &&
      inGameAction == InGameAction.noAction &&
      gameState.round.roundStatus == RoundStatus.playing;

  List<PlayingCardModel> get myHandCards => gameState.hands[me] ?? [];
  List<PlayingCardModel> get myCollectedCards =>
      gameState.playersDeck[me] ?? [];
  List<PlayingCardModel> get myLastTake => lastTakeFor(me);

  List<PlayingCardModel> lastTakeFor(String? pid) {
    if (pid == null || pid.isEmpty) return const [];
    return gameState.lastTakes[pid] ?? const [];
  }

  /// Sort high→low, or flip to low→high when already ranked that way.
  void sortHandCards() {
    final hand = gameState.hands[me];
    if (hand == null || hand.length < 2) return;

    final highToLow = _handIsRanked(hand, descending: true);
    if (highToLow) {
      hand.sort((a, b) => a.valueHigh.compareTo(b.valueHigh));
    } else {
      hand.sort((a, b) => b.valueHigh.compareTo(a.valueHigh));
    }
    notifyListeners();
  }

  bool _handIsRanked(List<PlayingCardModel> hand, {required bool descending}) {
    for (var i = 1; i < hand.length; i++) {
      final cmp = hand[i].valueHigh.compareTo(hand[i - 1].valueHigh);
      if (descending ? cmp > 0 : cmp < 0) return false;
    }
    return true;
  }

  /// Re-apply this player's fan order onto [incoming].
  ///
  /// Hand order is local-only and is not written during the opponent's turn,
  /// so a remote state replace would otherwise snap the fan back.
  void _preserveMyHandOrder(GameState incoming) {
    final previous = gameState.hands[me];
    final incomingHand = incoming.hands[me];
    if (previous == null || incomingHand == null) return;
    if (previous.isEmpty || incomingHand.isEmpty) return;

    final byId = <String, PlayingCardModel>{
      for (final c in incomingHand) c.id: c,
    };
    final ordered = <PlayingCardModel>[];
    for (final card in previous) {
      final next = byId.remove(card.id);
      if (next != null) ordered.add(next);
    }
    // Brand-new hand (deal) — keep the incoming sequence.
    if (ordered.isEmpty) return;
    ordered.addAll(byId.values);
    if (_sameHandIds(incomingHand, ordered)) return;
    incomingHand
      ..clear()
      ..addAll(ordered);
  }

  bool _sameHandIds(List<PlayingCardModel> a, List<PlayingCardModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  /// Local-only fan order (same persistence rules as [sortHandCards]).
  void reorderHand(int from, int to) {
    final hand = gameState.hands[me];
    if (hand == null || from == to) return;
    if (from < 0 || from >= hand.length) return;
    var insert = to.clamp(0, hand.length);
    final card = hand.removeAt(from);
    if (insert > from) insert -= 1;
    insert = insert.clamp(0, hand.length);
    hand.insert(insert, card);
    notifyListeners();
  }

  /// Move a hand card to [toIndex] (final index after the move).
  void moveHandCardTo(int from, int toIndex) {
    final hand = gameState.hands[me];
    if (hand == null || from < 0 || from >= hand.length) return;
    final target = toIndex.clamp(0, hand.length - 1);
    if (from == target) return;
    final card = hand.removeAt(from);
    hand.insert(target, card);
    notifyListeners();
  }

  // ── Board drag / drop (Casino) ───────────────────────────────────────────

  BoardDragSource? draggingSource;
  DropHover? dropHover;
  DropPending? dropPending;
  DragHandoff? dragHandoff;

  bool get isBoardDragging => draggingSource != null;
  bool get hasDropPending => dropPending != null;

  /// Legacy alias used by older UI.
  PlayingCardModel? get draggingHandCard =>
      draggingSource?.kind == BoardDragKind.handCard
      ? draggingSource!.card
      : null;

  bool get isCasinoFamily =>
      gameState.gameMode == GameMode.casino ||
      gameState.gameMode == GameMode.casinoSpeed;

  void beginBoardDrag(BoardDragSource source) {
    if (isAnimating || dropPending != null) return;
    draggingSource = source;
    dropHover = null;
    notifyListeners();
  }

  /// @deprecated Use [beginBoardDrag].
  void beginHandDrag(PlayingCardModel card) =>
      beginBoardDrag(BoardDragSource.hand(card));

  /// Snapshot of the live drag overlay so the flight can start from the
  /// same card, at the same size, instead of spawning a new one.
  void beginDragHandoff(
    BoardDragSource source,
    Offset globalCenter,
    double width,
  ) {
    final ids = <String>{};
    switch (source.kind) {
      case BoardDragKind.handCard:
      case BoardDragKind.tableCard:
        ids.add(source.card!.id);
      case BoardDragKind.tableStack:
        ids.addAll(source.stack!.cards.map((c) => c.id));
    }
    dragHandoff = DragHandoff(
      cardIds: ids,
      globalCenter: globalCenter,
      width: width,
    );
  }

  void clearDragHandoff() {
    dragHandoff = null;
  }

  void endBoardDrag() {
    if (draggingSource == null && dropHover == null) return;
    draggingSource = null;
    dropHover = null;
    notifyListeners();
  }

  void endHandDrag() => endBoardDrag();

  bool _boxContains(GlobalKey? key, Offset global) {
    if (key == null) return false;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) return false;
    final topLeft = box.localToGlobal(Offset.zero);
    return (topLeft & box.size).contains(global);
  }

  /// Resolve which table slot (or empty felt) is under [global].
  DropTarget? hitTestDropTarget(Offset global, {BoardDragSource? source}) {
    final src = source ?? draggingSource;
    final skipId = src?.id;

    for (final card in gameState.playingArea) {
      if (card.id == skipId) continue;
      if (_boxContains(keyForCard(card.id, CardSlot.table), global)) {
        return DropTarget.tableCard(card);
      }
    }
    for (final stack in gameState.playingAreaStacks) {
      if (stack.id == skipId) continue;
      if (_boxContains(keyForStack(stack.id), global)) {
        return DropTarget.tableStack(stack);
      }
    }
    if (_boxContains(tableKey, global)) {
      return const DropTarget.emptyTable();
    }
    return null;
  }

  CurrentCardSelection selectionForDrop(
    BoardDragSource source,
    DropTarget target,
  ) {
    PlayingCardModel? hand;
    final tableCards = <PlayingCardModel>[];
    final stacks = <PlayingAreaStackModel>[];

    switch (source.kind) {
      case BoardDragKind.handCard:
        hand = source.card;
      case BoardDragKind.tableCard:
        tableCards.add(source.card!);
      case BoardDragKind.tableStack:
        stacks.add(source.stack!);
    }

    switch (target.kind) {
      case DropTargetKind.emptyTable:
        break;
      case DropTargetKind.tableCard:
        if (!tableCards.any((c) => c.id == target.card!.id)) {
          tableCards.add(target.card!);
        }
      case DropTargetKind.tableStack:
        if (!stacks.any((s) => s.id == target.stack!.id)) {
          stacks.add(target.stack!);
        }
    }

    return CurrentCardSelection(
      pid: me,
      selectedCard: hand,
      selectedCards: tableCards,
      selectedStacks: stacks,
    );
  }

  List<PlayAction> actionsForDrop(BoardDragSource source, DropTarget target) {
    if (!canPlayTurn) return const [];
    // Tres y Dos: keep Play-only empty-table drop; no table-slot DnD.
    if (!isCasinoFamily) {
      if (source.kind != BoardDragKind.handCard ||
          target.kind != DropTargetKind.emptyTable) {
        return const [];
      }
      final selection = selectionForDrop(source, target);
      return gameEngine
          .getAvailableActions(gameState, selection)
          .whereType<PlayCardAction>()
          .toList();
    }
    // Empty table only accepts Play from hand.
    if (target.kind == DropTargetKind.emptyTable) {
      if (source.kind != BoardDragKind.handCard) return const [];
      final selection = selectionForDrop(source, target);
      return gameEngine
          .getAvailableActions(gameState, selection)
          .whereType<PlayCardAction>()
          .toList();
    }
    final selection = selectionForDrop(source, target);
    return gameEngine.getAvailableActions(gameState, selection);
  }

  List<PlayingCardModel> _mergedPreviewCards(CurrentCardSelection selection) {
    final cards = <PlayingCardModel>[
      ...selection.selectedCards,
      for (final s in selection.selectedStacks) ...s.cards,
    ];
    if (selection.selectedCard != null) {
      cards.add(selection.selectedCard!);
    }
    return cards;
  }

  BuildPreview? _buildPreviewFor(
    CurrentCardSelection selection,
    List<PlayAction> actions, {
    bool forceMerge = false,
  }) {
    if (actions.isEmpty) return null;

    final isAdd = actions.any(
      (a) =>
          a is AddCardsAction ||
          a is AddCardStackAction ||
          a is AddTableCardsAction ||
          a is AddAndPairCardsAction,
    );

    final previewCards = _mergedPreviewCards(selection);
    if (previewCards.isEmpty) return null;

    if (isAdd) {
      final totals = CasinoRulesHandler.possibleBuildTotals(
        selectedCard: selection.selectedCard,
        selectedCards: selection.selectedCards,
        selectedStacks: selection.selectedStacks,
      ).where((t) => t > 0).toSet();
      if (totals.isNotEmpty) {
        final usedId = selection.selectedCard?.id;
        int? chosen;
        for (final t in totals.toList()..sort()) {
          final matchesFinisher = myHandCards.any(
            (c) =>
                c.id != usedId &&
                CasinoRulesHandler.possibleCardValues(c).contains(t),
          );
          if (matchesFinisher) chosen = t;
        }
        chosen ??= totals.reduce((a, b) => a > b ? a : b);

        final parts = <String>[
          for (final c in selection.selectedCards) c.rank,
          for (final s in selection.selectedStacks) '${s.stackValue}',
          if (selection.selectedCard != null) selection.selectedCard!.rank,
        ];

        return BuildPreview(
          label: '${parts.join('+')}→$chosen',
          total: chosen,
          previewCards: previewCards,
        );
      }
    }

    // Multi-action pending (or forced): keep cards visually merged without
    // an a+b→c badge.
    if (forceMerge || actions.length > 1) {
      return BuildPreview(
        label: actions.length > 1
            ? 'Choose'
            : actionLabel(actions.first),
        total: selection.selectedStacks.isNotEmpty
            ? selection.selectedStacks.first.stackValue
            : (previewCards.isNotEmpty
                  ? CasinoRulesHandler.possibleCardValues(
                      previewCards.last,
                    ).first
                  : 0),
        previewCards: previewCards,
      );
    }
    return null;
  }

  void updateDropHover(Offset global) {
    final source = draggingSource;
    if (source == null) return;
    final target = hitTestDropTarget(global, source: source);
    if (target == null) {
      if (dropHover != null) {
        dropHover = null;
        notifyListeners();
      }
      return;
    }
    final actions = actionsForDrop(source, target);
    if (actions.isEmpty) {
      if (dropHover != null) {
        dropHover = null;
        notifyListeners();
      }
      return;
    }
    final selection = selectionForDrop(source, target);
    final preview = target.kind == DropTargetKind.emptyTable
        ? null
        : _buildPreviewFor(selection, actions);
    dropHover = DropHover(
      target: target,
      actions: actions,
      buildPreview: preview,
    );
    notifyListeners();
  }

  /// Apply drop. Returns whether the drag was consumed (commit or pending).
  Future<bool> finishBoardDrop(Offset globalCenter) async {
    final source = draggingSource;
    if (source == null) return false;

    final target = hitTestDropTarget(globalCenter, source: source);
    draggingSource = null;

    if (target == null || !canPlayTurn) {
      dropHover = null;
      dragHandoff = null;
      notifyListeners();
      return false;
    }

    final actions = actionsForDrop(source, target);
    if (actions.isEmpty) {
      dropHover = null;
      dragHandoff = null;
      notifyListeners();
      return false;
    }

    final selection = selectionForDrop(source, target);
    final preview = target.kind == DropTargetKind.emptyTable
        ? null
        : _buildPreviewFor(selection, actions, forceMerge: true);

    if (actions.length == 1) {
      // Keep the last painted merge preview until [_flyCommit] rebuilds.
      dropHover = null;
      await _commitDropAction(actions.first, selection, globalCenter);
      return true;
    }

    // Multi-action: keep selection + pending UI.
    dropHover = null;
    dragHandoff = null;
    selectedCard = selection.selectedCard;
    selectedCards = List<PlayingCardModel>.from(selection.selectedCards);
    selectedStacks = List<PlayingAreaStackModel>.from(selection.selectedStacks);
    dropPending = DropPending(
      source: source,
      target: target,
      actions: actions,
      buildPreview: preview,
    );
    notifyListeners();
    return true;
  }

  Future<void> commitDropPending(PlayAction action) async {
    final pending = dropPending;
    if (pending == null) return;
    final selection = selectionForDrop(pending.source, pending.target);
    dropPending = null;
    await _commitDropAction(action, selection, null);
  }

  void cancelDropPending() {
    if (dropPending == null) return;
    dropPending = null;
    selectedCard = null;
    selectedCards = [];
    selectedStacks = [];
    notifyListeners();
  }

  Future<void> _commitDropAction(
    PlayAction action,
    CurrentCardSelection selection,
    Offset? globalCenter,
  ) async {
    selectedCard = selection.selectedCard;
    selectedCards = List<PlayingCardModel>.from(selection.selectedCards);
    selectedStacks = List<PlayingAreaStackModel>.from(selection.selectedStacks);

    if (dragHandoff == null && globalCenter != null) {
      final sourceCard = action is PlayCardAction
          ? action.usedCard
          : selection.selectedCard;
      if (sourceCard != null) {
        beginDragHandoff(
          BoardDragSource.hand(sourceCard),
          globalCenter,
          _widthForZone(const Zone(type: ZoneType.table)),
        );
      }
    }

    await performPlayAction(action);
  }

  /// True when dropping this hand card on empty table should Play.
  bool canDropPlay(PlayingCardModel card) {
    if (!canPlayTurn) return false;
    return actionsForDrop(
      BoardDragSource.hand(card),
      const DropTarget.emptyTable(),
    ).any((a) => a is PlayCardAction);
  }

  Future<void> playCardViaDrop(
    PlayingCardModel card,
    Offset globalCenter,
  ) async {
    beginBoardDrag(BoardDragSource.hand(card));
    // Synthesize empty-table drop under finger if over table.
    final target = hitTestDropTarget(globalCenter) ?? const DropTarget.emptyTable();
    draggingSource = BoardDragSource.hand(card);
    if (target.kind != DropTargetKind.emptyTable) {
      await finishBoardDrop(globalCenter);
      return;
    }
    final actions = actionsForDrop(
      BoardDragSource.hand(card),
      const DropTarget.emptyTable(),
    );
    draggingSource = null;
    dropHover = null;
    if (actions.length == 1) {
      await _commitDropAction(
        actions.first,
        selectionForDrop(
          BoardDragSource.hand(card),
          const DropTarget.emptyTable(),
        ),
        globalCenter,
      );
    } else {
      notifyListeners();
    }
  }

  /// Whether [id] should be hidden because it is the drag source or merged
  /// into a hover/pending preview target.
  bool isDragHidden(String id) {
    if (draggingSource?.id == id) return true;
    if (dragHandoff?.cardIds.contains(id) == true) return true;
    final pending = dropPending;
    if (pending != null && pending.source.id == id) return true;
    return false;
  }

  /// Provisional cards to paint on a hover/pending target slot.
  BuildPreview? previewForTarget({String? cardId, String? stackId}) {
    final hover = dropHover;
    if (hover?.buildPreview != null) {
      final t = hover!.target;
      if (cardId != null && t.card?.id == cardId) return hover.buildPreview;
      if (stackId != null && t.stack?.id == stackId) return hover.buildPreview;
    }
    final pending = dropPending;
    if (pending?.buildPreview != null) {
      final t = pending!.target;
      if (cardId != null && t.card?.id == cardId) return pending.buildPreview;
      if (stackId != null && t.stack?.id == stackId) return pending.buildPreview;
    }
    return null;
  }

  String? get opp {
    return (gameState.playersInfo.length > 1)
        ? gameState.playersInfo.entries.firstWhere((p) => p.key != me).key
        : null;
  }

  List<String> get oppIds => sortIds(me).sublist(1);

  List<String> sortIds(String pid) {
    final players = gameState.playersInfo.keys.toList();
    final List<String> sortedPlayers = [];
    players.sort((a, b) => a.compareTo(b));
    final myIndex = players.indexOf(me);
    if (myIndex != -1) {
      players.add(players[myIndex]);
    }
    final rightSide = players.sublist(myIndex, players.length - 1);
    players.removeRange(myIndex, players.length - 1);
    sortedPlayers.addAll(rightSide);

    final leftSide = players.sublist(0, myIndex);
    players.removeRange(0, myIndex);
    sortedPlayers.addAll(leftSide);

    return sortedPlayers;
  }

  int get oppExtraPoints =>
      opp == gameState.extraPointsHolderId ? gameState.extraPoints : 0;

  List<PlayingCardModel> get oppHandCard => gameState.hands[opp] ?? [];
  List<PlayingCardModel> get oppCollectedCards =>
      gameState.playersDeck[opp] ?? [];
  List<PlayingCardModel> get oppLastTake => lastTakeFor(opp);

  CurrentCardSelection get cardSelection => CurrentCardSelection(
    pid: me,
    selectedCard: selectedCard,
    selectedCards: selectedCards,
    selectedStacks: selectedStacks,
  );

  List<PlayAction> get possiblePlayActions =>
      gameEngine.getAvailableActions(gameState, cardSelection);

  Future<void> performPlayAction(PlayAction action) async {
    if (isAnimating || _disposed) return;
    if (!_guardHumanPlay(action)) return;
    isAnimating = true;

    try {
      await _commitPlay(action, cardSelection);
      if (_disposed) return;
      _maybeBotReact(took: _isTakeAction(action), botPlayed: false);
      try {
        await _playTutorialOpponentIfNeeded();
      } catch (e) {
        developer.log("tutorial opponent Error $e");
      }
    } catch (e) {
      developer.log("performPlayAction Error $e");
      SoundService.instance.play(GameSound.illegal);
    } finally {
      if (!_disposed) {
        isAnimating = false;
        notifyListeners();
        _drainPendingRepoSync();
      }
    }
  }

  bool _guardHumanPlay(PlayAction action) {
    if (!tutorialMode || actionGuard == null) return true;
    if (action.performedById != me) return true;
    return _canPerform(_tutorialActionFor(action));
  }

  TutorialAction _tutorialActionFor(PlayAction action) {
    if (action is AddAndTakeAction || action is TakeCardAction) {
      return TutorialAction.sweepTable;
    }
    if (action is AddCardsAction ||
        action is AddCardStackAction ||
        action is AddTableCardsAction ||
        action is AddAndPairCardsAction) {
      return TutorialAction.addStack;
    }
    if (action is TakeStackAction) {
      return TutorialAction.takeStack;
    }
    return TutorialAction.playMove;
  }

  Future<void> _commitPlay(
    PlayAction action,
    CurrentCardSelection selection,
  ) async {
    final beforeMe = gameState.pendingCoinsFor(me);
    final oppId = opp;
    final beforeOpp = oppId == null ? 0 : gameState.pendingCoinsFor(oppId);
    final next = gameEngine.performPlayAction(gameState, selection, action);
    final events = List<CardMoveEvent>.from(next.cardMoveEvents);
    final settlement = List<CardMoveEvent>.from(next.settlementEvents);

    if (!tutorialMode) {
      CasinoCoinBonuses.accrueAfterPlay(next, action);
      for (final e in [...events, ...settlement]) {
        gameRepo.lastPlayedIds.add(e.id);
      }
      await Future.wait([
        gameRepo.fs.updateGame(next),
        _commitStateWithMotion(next, events, settlementEvents: settlement),
      ]);
      _queueDeckCoinFlight(
        meGain: next.pendingCoinsFor(me) - beforeMe,
        oppGain: oppId == null ? 0 : next.pendingCoinsFor(oppId) - beforeOpp,
      );
    } else {
      await _commitStateWithMotion(next, events, settlementEvents: settlement);
      _queueDeckCoinFlight(
        meGain: next.pendingCoinsFor(me) - beforeMe,
        oppGain: oppId == null ? 0 : next.pendingCoinsFor(oppId) - beforeOpp,
      );
    }
    if (next.gameStatus == GameStatus.gameOver) {
      SoundService.instance.play(GameSound.win);
    }
  }

  void _queueDeckCoinFlight({required int meGain, required int oppGain}) {
    if (tutorialMode) {
      _syncRevealedPending();
      return;
    }
    if (meGain > 0) {
      pendingDeckCoinFlight = DeckCoinFlight(mine: true, amount: meGain);
      return;
    }
    if (oppGain > 0) {
      pendingDeckCoinFlight = DeckCoinFlight(mine: false, amount: oppGain);
      return;
    }
    _syncRevealedPending();
  }

  DeckCoinFlight? takeDeckCoinFlight() {
    final flight = pendingDeckCoinFlight;
    pendingDeckCoinFlight = null;
    return flight;
  }

  int revealedPendingFor(String pid) {
    if (pid == me) return _revealedPendingMe;
    return _revealedPendingOpp;
  }

  void revealPendingCoins() {
    final nextMe = gameState.pendingCoinsFor(me);
    final nextOpp = opp == null ? 0 : gameState.pendingCoinsFor(opp!);
    if (nextMe == _revealedPendingMe && nextOpp == _revealedPendingOpp) return;
    _revealedPendingMe = nextMe;
    _revealedPendingOpp = nextOpp;
    notifyListeners();
  }

  void _syncRevealedPending() {
    _revealedPendingMe = gameState.pendingCoinsFor(me);
    _revealedPendingOpp = opp == null ? 0 : gameState.pendingCoinsFor(opp!);
  }

  /// Tutorial games never hit Firestore, so the on-device AI never wakes up.
  /// Play the bot locally after the human move (and if Skip leaves it their turn).
  Future<void> playTutorialOpponentIfNeeded() async {
    if (!tutorialMode || isAnimating || _disposed) return;
    isAnimating = true;
    try {
      await _playTutorialOpponentIfNeeded();
    } catch (e) {
      developer.log("playTutorialOpponentIfNeeded Error $e");
    } finally {
      if (!_disposed) {
        isAnimating = false;
        notifyListeners();
      }
    }
  }

  Future<void> _playTutorialOpponentIfNeeded() async {
    if (!tutorialMode || _disposed) return;
    final botId = opp;
    if (botId == null) return;
    if (gameState.round.roundStatus != RoundStatus.playing) return;

    final botHand = gameState.hands[botId] ?? [];
    final allowBot = tutorialAllowsOpponentPlay?.call() ?? false;

    if (botHand.isEmpty) {
      if ((gameState.hands[me] ?? []).isNotEmpty &&
          gameState.currentTurnPlayerId == botId) {
        gameState.currentTurnPlayerId = me;
        notifyListeners();
      }
      return;
    }

    if (!allowBot) {
      if (gameState.currentTurnPlayerId == botId &&
          (gameState.hands[me] ?? []).isNotEmpty) {
        gameState.currentTurnPlayerId = me;
        notifyListeners();
      }
      return;
    }

    if (gameState.currentTurnPlayerId != botId) {
      gameState.currentTurnPlayerId = botId;
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (_disposed || gameState.currentTurnPlayerId != botId) return;

    final best = await CasinoPlayer.casinoBestAction(botId, gameState);
    if (_disposed || gameState.currentTurnPlayerId != botId) return;

    await _commitPlay(best.playAction, best.cardSelection);
    _maybeBotReact(took: _isTakeAction(best.playAction), botPlayed: true);
  }

  InGameAction get inGameAction => gameEngine.getInGameAction(gameState, me);

  /// Board dim + control chrome share this — never dim while motion is running.
  /// Tutorial never surfaces shuffle/deal/start; those belong to a real match.
  bool get showInGameControl =>
      !tutorialMode &&
      !isAnimating &&
      !motion.isShuffling &&
      inGameAction != InGameAction.noAction;

  Future<void> performInGameAction(InGameAction action) async {
    if (isAnimating) return;
    isAnimating = true;
    notifyListeners();
    try {
      final shuffleVisual =
          action == InGameAction.shuffle || action == InGameAction.start;

      if (shuffleVisual) {
        _shuffleOverlayRoundId = gameState.round.id;
        // Capture piles first — the engine shuffle clears them in place.
        await _playShuffleMotion(
          onHidden: () async {
            final next = gameEngine.performInGameAction(gameState, action, me);
            final events = List<CardMoveEvent>.from(next.cardMoveEvents);
            if (!tutorialMode) {
              for (final e in events) {
                gameRepo.lastPlayedIds.add(e.id);
              }
              await gameRepo.fs.updateGame(next);
            }
            await _commitStateWithMotion(next, events);
          },
          onSquared: () async {
            motion.setShuffling(false);
          },
        );
        return;
      }

      final next = gameEngine.performInGameAction(gameState, action, me);
      final events = List<CardMoveEvent>.from(next.cardMoveEvents);

      if (!tutorialMode) {
        for (final e in events) {
          gameRepo.lastPlayedIds.add(e.id);
        }
        await gameRepo.fs.updateGame(next);
      }

      await _commitStateWithMotion(next, events);
    } catch (e) {
      developer.log("performInGameAction Error $e");
    } finally {
      motion.setShuffling(false);
      isAnimating = false;
      notifyListeners();
      _drainPendingRepoSync();
    }
  }

  void _drainPendingRepoSync() {
    if (!_pendingRepoSync) return;
    _pendingRepoSync = false;
    _onGameRepoChanged();
  }

  Future<bool> loadGame() async {
    try {
      if (tutorialMode) {
        gameState = TutorialCasinoFactory.createBasicTakeTutorial(
          gid: gid,
          playerId: me,
        );
      } else {
        gameState = await gameRepo.fs.loadGame(gid);
        gameState.ensureBotMetadata();
      }
      _syncRevealedPending();
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      developer.log("GenGameViewModel.loadGame Error: $e");
    }
    return false;
  }

  Future<JoinGameResult> joinGame() async {
    var charged = 0;
    try {
      if (!tutorialMode &&
          !gameState.isLocalBot &&
          !gameState.entryPaidBy.contains(player.id)) {
        final cost = gameState.entryCost;
        if (appRepo.wallet.coins < cost) {
          return JoinGameResult.notEnoughCoins;
        }
        final spent = await appRepo.trySpendCoins(cost);
        if (!spent) return JoinGameResult.notEnoughCoins;
        charged = cost;
        gameState.entryPaidBy.add(player.id);
      }

      gameState.playersInfo[player.id] = player.toGameSeat();
      if (gameEngine.shouldMarkReadyToStart(gameState) &&
          gameState.gameStatus == GameStatus.waitingForPlayers) {
        gameState.gameStatus = GameStatus.readyToStart;
      }
      if (!tutorialMode) {
        await gameRepo.fs.updateGame(gameState);
        LocalPlayer.ensureAttached(gameRepo, gameState);
      }
      notifyListeners();
      return JoinGameResult.ok;
    } catch (e) {
      developer.log("GameViewModel.joiningGame Error: $e");
      if (charged > 0) {
        await appRepo.grantCoins(charged);
        gameState.entryPaidBy.remove(player.id);
      }
    }
    return JoinGameResult.failed;
  }

  Future<void> resign() async {
    if (opp == null || tutorialMode) {
      await appRepo.deleteGame(gameState.id);
      notifyListeners();
      return;
    }

    gameState.cardMoveEvents = [];
    gameState.settlementEvents = [];
    gameState.winnerId = opp;
    gameState.gameStatus = GameStatus.gameOver;
    await gameRepo.fs.updateGame(gameState);
    notifyListeners();
  }

  /// After round/game status sheet — acknowledge so the dealer (or bot) can proceed.
  Future<void> continueAfterRound() async {
    if (gameState.gameStatus == GameStatus.gameOver) {
      notifyListeners();
      return;
    }
    if (gameState.round.roundStatus != RoundStatus.completed) return;

    gameState.round.nextAcknowledged = true;

    if (gameState.controllerId == me) {
      await performInGameAction(InGameAction.shuffle);
      return;
    }

    final botDealer =
        gameState.isLocalBot && gameState.controllerId == gameState.localBotPid;

    if (!botDealer) {
      // Remote human dealer — ack only; shuffle motion arrives via `_syncFromRepo`.
      if (!tutorialMode) {
        await gameRepo.fs.updateGame(gameState);
      }
      notifyListeners();
      return;
    }

    // Local bot dealer: play the gather-wash now, while collected piles
    // still exist. The bot mutates this same GameState in place, so
    // `_syncFromRepo` never sees completed → readyToDeal.
    if (isAnimating) return;
    isAnimating = true;
    notifyListeners();
    _shuffleOverlayRoundId = gameState.round.id;
    try {
      await _playShuffleMotion(
        onHidden: () async {
          if (!tutorialMode) {
            await gameRepo.fs.updateGame(gameState);
          }
        },
        onSquared: () async {
          final latest = gameRepo.gameState;
          if (latest != null) {
            await _commitStateWithMotion(latest, const []);
          }
          motion.setShuffling(false);
        },
      );
    } catch (e) {
      developer.log("continueAfterRound shuffle Error $e");
    } finally {
      motion.setShuffling(false);
      isAnimating = false;
      notifyListeners();
      _drainPendingRepoSync();
    }
  }

  PlayingCardModel? selectedCard;
  List<PlayingCardModel> selectedCards = [];
  List<PlayingAreaStackModel> selectedStacks = [];
  bool get anySelected =>
      selectedCard != null ||
      selectedCards.isNotEmpty ||
      selectedStacks.isNotEmpty;

  void cancelSelection() {
    selectedCards = [];
    selectedCard = null;
    selectedStacks = [];
    notifyListeners();
  }

  bool _canPerform(
    TutorialAction action, {
    String? cardId,
    String? stackId,
    List<String> selectedCardIds = const [],
  }) {
    return actionGuard?.call(
          action,
          cardId: cardId,
          stackId: stackId,
          selectedCardIds: selectedCardIds,
        ) ??
        true;
  }

  void selectCard(PlayingCardModel card) {
    if (isAnimating || !isMyTurn) return;
    if (!_canPerform(TutorialAction.selectHandCard, cardId: card.id)) {
      return;
    }
    if (selectedCard == card) {
      selectedCard = null;
    } else {
      selectedCard = card;
    }
    SoundService.instance.play(GameSound.softCard);
    notifyListeners();
  }

  void selectCardToTake(PlayingCardModel? card) {
    if (isAnimating || !isMyTurn) return;
    if (selectedCards.contains(card)) {
      selectedCards = [];
    } else {
      if (selectedCards.isNotEmpty) {
        selectedCards = [];
      }

      if (card != null) selectedCards.add(card);
    }

    final ok =
        actionGuard?.call(
          TutorialAction.selectTableCard,
          cardId: card?.id,
          selectedCardIds: selectedCards.map((c) => c.id).toList(),
        ) ??
        true;

    if (!ok) {
      if (card != null) {
        selectedCards.remove(card);
      }
      return;
    }

    SoundService.instance.play(GameSound.softCard);
    notifyListeners();
  }

  void selectCardToStack(PlayingCardModel card) {
    if (isAnimating || !isMyTurn) return;
    final nextIds = selectedCards.contains(card)
        ? selectedCards.where((c) => c.id != card.id).map((c) => c.id).toList()
        : [...selectedCards.map((c) => c.id), card.id];
    if (!_canPerform(
      TutorialAction.selectTableCard,
      cardId: card.id,
      selectedCardIds: nextIds,
    )) {
      return;
    }

    if (selectedCards.contains(card)) {
      selectedCards.remove(card);
    } else {
      selectedCards.add(card);
    }

    SoundService.instance.play(GameSound.softCard);
    notifyListeners();
  }

  void selectStack(PlayingAreaStackModel stack) {
    if (isAnimating || !isMyTurn) return;
    if (!_canPerform(TutorialAction.selectStack, stackId: stack.id)) {
      return;
    }
    if (selectedStacks.contains(stack)) {
      selectedStacks.remove(stack);
    } else {
      selectedStacks.add(stack);
    }
    if (selectedStacks.length > 1) selectedCard = null;
    SoundService.instance.play(GameSound.softCard);
    notifyListeners();
  }

  void listenToReactions() {
    _reactionSub?.cancel();
    _reactionSub = gameRepo.fs
        .streamReaction(gid)
        .listen(
          _onRemoteReaction,
          onError: (e, st) {
            developer.log('listenToReactions Error: $e');
          },
        );
  }

  void _onRemoteReaction(GameReaction? reaction) {
    if (_disposed || reaction == null) return;
    if (reaction.id.isEmpty || reaction.emoji.isEmpty) return;
    if (reaction.id == _lastSeenReactionId) return;
    if (DateTime.now().difference(reaction.sentAt).inSeconds > 8) {
      _lastSeenReactionId = reaction.id;
      return;
    }
    _lastSeenReactionId = reaction.id;
    if (reaction.fromPid == me) return;
    _showIncomingReaction(reaction);
  }

  void _showIncomingReaction(GameReaction reaction) {
    incomingReaction = reaction;
    _lastSeenReactionId = reaction.id;
    _incomingHideTimer?.cancel();
    _incomingHideTimer = Timer(_reactionVisibleFor, () {
      if (_disposed) return;
      incomingReaction = null;
      notifyListeners();
    });
    notifyListeners();
    AppHaptics.lightImpact();
  }

  bool _isTakeAction(PlayAction action) {
    return action is TakeCardAction ||
        action is TakeStackAction ||
        action is AddAndTakeAction ||
        action is PairAndTakeCardsAction;
  }

  Future<void> claimMatchCoins() async {
    if (tutorialMode) return;
    await appRepo.claimMatchCoins(gameState, me);
  }

  Future<void> queueHomeCoinClaim() async {
    if (tutorialMode) return;
    await appRepo.queueHomeCoinClaim(gameState, me);
  }

  /// Occasional local-bot emoji after a play/take. Never writes game state.
  void _maybeBotReact({required bool took, required bool botPlayed}) {
    if (_disposed) return;
    if (!gameState.isLocalBot && !tutorialMode) return;
    if (gameState.round.roundStatus != RoundStatus.playing) return;
    if (gameState.gameStatus == GameStatus.gameOver) return;
    final botId = gameState.localBotPid ?? opp;
    if (botId == null || botId.isEmpty) return;

    final now = DateTime.now();
    if (_lastBotReactAt != null &&
        now.difference(_lastBotReactAt!) < _botReactCooldown) {
      return;
    }

    final chance = took
        ? 0.48
        : botPlayed
        ? 0.36
        : 0.28;
    if (_reactionRandom.nextDouble() > chance) return;

    final pool = took
        ? (botPlayed
              ? const ['🔥', '👏', '👍']
              : const ['😮', '😂', '👏', '🔥'])
        : GameReaction.options;
    final delayMs = 380 + _reactionRandom.nextInt(720);
    _botReactTimer?.cancel();
    _botReactTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_disposed) return;
      if (gameState.round.roundStatus != RoundStatus.playing) return;
      _lastBotReactAt = DateTime.now();
      _showIncomingReaction(
        GameReaction(
          id: const Uuid().v4().substring(0, 8),
          emoji: pool[_reactionRandom.nextInt(pool.length)],
          fromPid: botId,
          sentAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> sendReaction(String emoji) async {
    final reaction = GameReaction(
      id: const Uuid().v4().substring(0, 8),
      emoji: emoji,
      fromPid: me,
      sentAt: DateTime.now(),
    );
    outgoingReaction = reaction;
    _lastSeenReactionId = reaction.id;
    _outgoingHideTimer?.cancel();
    _outgoingHideTimer = Timer(_reactionVisibleFor, () {
      if (_disposed) return;
      outgoingReaction = null;
      notifyListeners();
    });
    notifyListeners();
    if (tutorialMode) return;
    try {
      await gameRepo.fs.sendReaction(gid: gid, reaction: reaction);
    } catch (e) {
      developer.log('sendReaction Error $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reactionSub?.cancel();
    _outgoingHideTimer?.cancel();
    _incomingHideTimer?.cancel();
    _botReactTimer?.cancel();
    gameRepo.removeListener(_onGameRepoChanged);
    motion.removeListener(notifyListeners);
    motion.dispose();
    super.dispose();
  }

  /// Prefer [motion.isInFlight] — kept for call sites during migration.
  bool isCardHidden(PlayingCardModel card) => motion.isInFlight(card.id);

  bool stackContainsCardHidded(List<PlayingCardModel> cards) =>
      motion.anyInFlight(cards);

  final Map<String, GlobalKey> cardKeys = {};
  final Map<String, GlobalKey> stackKeys = {};

  /// One GlobalKey per (cardId, visual slot). Never reuse across hand/table
  /// or the tree will assert "Multiple widgets used the same GlobalKey".
  GlobalKey keyForCard(String cardId, CardSlot slot) {
    final k = '${slot.name}:$cardId';
    return cardKeys.putIfAbsent(k, () => GlobalKey(debugLabel: k));
  }

  GlobalKey keyForStack(String stackId) {
    return stackKeys.putIfAbsent(
      stackId,
      () => GlobalKey(debugLabel: 'stack_$stackId'),
    );
  }

  final GlobalKey deckKey = GlobalKey();
  final GlobalKey tableKey = GlobalKey();
  final GlobalKey myDeckKey = GlobalKey();
  final GlobalKey oppDeckKey = GlobalKey();
  final GlobalKey myHandKey = GlobalKey();
  final GlobalKey oppHandKey = GlobalKey();
  final GlobalKey playButtonKey = GlobalKey();
  final GlobalKey addButtonKey = GlobalKey();
  final GlobalKey takeStackButtonKey = GlobalKey();
  final GlobalKey scoreKey = GlobalKey();
  final GlobalKey oppScoreKey = GlobalKey();

  GlobalKey? keyForZone(Zone zone) {
    final myPid = me;
    switch (zone.type) {
      case ZoneType.gameDeck:
        return deckKey;
      case ZoneType.table:
        return tableKey;
      case ZoneType.playerDeck:
        return zone.holderId == myPid ? myDeckKey : oppDeckKey;
      case ZoneType.playerHand:
        return zone.holderId == myPid ? myHandKey : oppHandKey;
      case ZoneType.stack:
        final sid = zone.holderId;
        if (sid != null && sid.isNotEmpty) return keyForStack(sid);
        return tableKey;
    }
  }
}
