import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:dominican_casino/game_control/casino_coin_bonuses.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/casino_rules_handler.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/tresydos/handlers/tres_dos_game_state_handler.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_reaction.dart';
import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/local_player/casino_player.dart';
import 'package:dominican_casino/local_player/local_player.dart';
import 'package:dominican_casino/models/daily_challenge.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/wallet_config.dart';
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
import 'package:dominican_casino/view_models/games/hand_order.dart';
import 'package:dominican_casino/view_models/games/rummy_box_layout.dart';
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
enum CardSlot { myHand, oppHand, table, aux, inStack, rummyBox }

enum JoinGameResult { ok, notEnoughCoins, notEnoughEnergy, failed }

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

  /// Shared action clock: ticks locally, deadline lives on [GameState].
  Timer? _turnTimer;
  bool _turnAutoplayInFlight = false;
  bool _armingTurnClock = false;

  /// Round id whose gather-wash already played — skip a second overlay on repo echo.
  int? _shuffleOverlayRoundId;

  /// Tres y Dos: hold the winning 3+2 before status boards.
  static const _winCelebrationFor = Duration(seconds: 5);
  Timer? _winCelebrationTimer;
  DateTime? _winCelebrationDeadline;
  String? _winCelebrationKey;
  bool _winCelebrationSkipped = false;
  int _winCelebrationSecondsLeft = 0;

  /// Coins to fly from a collected pile into an avatar after take motion.
  DeckCoinFlight? pendingDeckCoinFlight;
  int _revealedPendingMe = 0;
  int _revealedPendingOpp = 0;

  /// Destination slots stay laid out but invisible until flights land.
  final CardMotionController motion = CardMotionController();

  /// Local fan order for [me]. Survives remote state replaces after flights.
  List<String> _myHandOrderIds = [];

  ActionGuard? actionGuard;

  /// Tutorial only: true when the current scripted step wants the bot to move.
  bool Function()? tutorialAllowsOpponentPlay;

  /// Tutorial only: whether this card/stack may be dragged on the current step.
  bool Function({String? cardId, String? stackId})? tutorialAllowsDrag;

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
    if (_disposed) return;
    // If the board is mid-flight, repo echo updates must not paint interim
    // card states (it causes the "deal flash" in other game modes).
    if (isAnimating || motion.hasFlights) {
      _pendingRepoSync = true;
      return;
    }
    _syncFromRepo();
  }

  Future<void> _syncFromRepo() async {
    if (_disposed) return;
    if (_syncScheduled) {
      _pendingRepoSync = true;
      return;
    }
    _syncScheduled = true;
    isAnimating = true;
    notifyListeners();

    try {
      do {
        if (_disposed) return;
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
              if (_disposed) return;
              await _commitStateWithMotion(
                nextState,
                newEvents,
                settlementEvents: newSettlement,
              );
              if (_disposed) return;
              motion.setShuffling(false);
              motion.clearInFlight();
            },
          );
        } else if (newEvents.isEmpty && newSettlement.isEmpty) {
          _adoptIncomingState(nextState);
        } else {
          await _commitStateWithMotion(
            nextState,
            newEvents,
            settlementEvents: newSettlement,
          );
        }
        if (_disposed) return;

        final meGain = gameState.pendingCoinsFor(me) - oldMe;
        final oppGain = oppId == null
            ? 0
            : gameState.pendingCoinsFor(oppId) - oldOpp;
        _queueDeckCoinFlight(meGain: meGain, oppGain: oppGain);

        final botIds = gameState.localBotPids;
        CardMoveEvent? botEvent;
        for (final e in newEvents) {
          if (botIds.contains(e.performedBy)) {
            botEvent = e;
            break;
          }
        }
        if (botEvent != null) {
          final actor = botEvent.performedBy;
          final botTook = newEvents.any(
            (e) => e.performedBy == actor && e.to.type == ZoneType.playerDeck,
          );
          final botPlayed = newEvents.any(
            (e) => e.performedBy == actor && e.from.type == ZoneType.playerHand,
          );
          _maybeBotReact(took: botTook, botPlayed: botPlayed, fromPid: actor);
        }
      } while (_pendingRepoSync && !_disposed);
    } catch (e) {
      developer.log("GameViewModel._syncFromRepo Error $e");
    } finally {
      if (_disposed) return;
      motion.setShuffling(false);
      isAnimating = false;
      _syncScheduled = false;
      _syncTurnClock();
      _syncWinCelebration();
      notifyListeners();
      if (_pendingRepoSync) {
        _pendingRepoSync = false;
        _onGameRepoChanged();
      }
    }
  }

  void _cancelTurnClock() {
    _turnTimer?.cancel();
    _turnTimer = null;
    _turnAutoplayInFlight = false;
  }

  void _syncTurnClock() {
    if (_disposed) return;
    if (!_sharedTurnClockLive) {
      _cancelTurnClock();
      return;
    }

    if (!isAnimating) {
      _maybePersistTurnClock();
    }

    _turnTimer ??= Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _onTurnTick(),
    );
  }

  Future<void> _maybePersistTurnClock() async {
    if (tutorialMode || _disposed || _armingTurnClock || isAnimating) return;
    if (!gameState.ensureTurnClock()) return;
    notifyListeners();
    _armingTurnClock = true;
    try {
      await gameRepo.fs.updateGame(gameState);
    } catch (e) {
      developer.log('persist turn clock Error $e');
    } finally {
      _armingTurnClock = false;
    }
  }

  void _onTurnTick() {
    if (_disposed) return;
    if (!_sharedTurnClockLive) {
      _cancelTurnClock();
      notifyListeners();
      return;
    }

    final deadline = gameState.turnDeadline;
    if (deadline == null) {
      _maybePersistTurnClock();
      return;
    }

    if (!deadline.isAfter(DateTime.now()) &&
        canPlayTurn &&
        !_turnAutoplayInFlight) {
      _turnAutoplayInFlight = true;
      _maybeAutoPlayOnTurnTimeout().whenComplete(() {
        if (!_disposed) _turnAutoplayInFlight = false;
      });
    }
  }

  Future<void> _maybeAutoPlayOnTurnTimeout() async {
    if (tutorialMode) return;
    if (!canPlayTurn) return;
    if (gameState.gameStatus == GameStatus.gameOver) return;

    cancelSelection();
    cancelDropPending();
    endBoardDrag();
    clearDragHandoff();

    if (gameState.gameMode == GameMode.tresydos) {
      await _timeoutTresDosAction();
      return;
    }

    final hand = gameState.hands[me] ?? const <PlayingCardModel>[];
    if (hand.isEmpty) return;

    final chosen = hand[_reactionRandom.nextInt(hand.length)];
    selectedCard = chosen;
    selectedCards = const [];
    selectedStacks = const [];
    notifyListeners();

    await performPlayAction(
      PlayCardAction(usedCard: chosen, performedById: me),
    );
  }

  Future<void> _timeoutTresDosAction() async {
    final hand = gameState.hands[me] ?? const <PlayingCardModel>[];
    if (hand.isEmpty) return;

    if (hand.length != 6) {
      final tableCard = gameState.playingArea.isNotEmpty
          ? gameState.playingArea.last
          : null;
      final deckCard = gameState.deck.isNotEmpty ? gameState.deck.last : null;
      final take = deckCard ?? tableCard;
      if (take == null) return;
      selectedCard = null;
      selectedCards = [take];
      selectedStacks = const [];
      notifyListeners();
      await performPlayAction(
        TakeCardAction(
          usedCard: take,
          targetCard: take,
          performedById: me,
          fromZone: deckCard != null ? ZoneType.gameDeck : ZoneType.table,
        ),
      );
      return;
    }

    final chosen = hand[_reactionRandom.nextInt(hand.length)];
    selectedCard = chosen;
    selectedCards = const [];
    selectedStacks = const [];
    notifyListeners();
    await performPlayAction(
      PlayCardAction(usedCard: chosen, performedById: me),
    );
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
    DailyChallengeGameSnap? progressFrom,
  }) async {
    if (_disposed) return;
    selectedCard = null;
    selectedCards = [];
    selectedStacks = [];

    if (events.isEmpty && settlementEvents.isEmpty) {
      _adoptIncomingState(next);
      return;
    }

    if (!tutorialMode) {
      unawaited(
        appRepo.noteDailyChallengeProgress(
          prev: progressFrom ?? DailyChallengeGameSnap.of(gameState, me),
          next: next,
          pid: me,
        ),
      );
    }

    if (settlementEvents.isNotEmpty) {
      final playOrigins = _captureOrigins(events);
      final intermediate = _stateWithLeftoversOnTable(next, settlementEvents);

      await _flyCommit(intermediate, events, playOrigins);
      if (_disposed) return;

      // Beat so everyone can read the last play before leftovers collect.
      await Future<void>.delayed(const Duration(milliseconds: 750));
      if (_disposed) return;

      final settleOrigins = _captureOrigins(settlementEvents);
      await _flyCommit(next, settlementEvents, settleOrigins);
      if (_disposed) return;

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
    if (_disposed) return;

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
      botPlayerIds: List<String>.from(next.botPlayerIds),
      entryCost: next.entryCost,
      entryPaidBy: List<String>.from(next.entryPaidBy),
      payoutClaimedBy: List<String>.from(next.payoutClaimedBy),
      pendingCoins: Map<String, int>.from(next.pendingCoins),
      viraosCreditedRoundId: next.viraosCreditedRoundId,
      roundTakeCoins: Map<String, int>.from(next.roundTakeCoins),
      roundSpecialCoins: Map<String, int>.from(next.roundSpecialCoins),
      roundViraoCoins: Map<String, int>.from(next.roundViraoCoins),
      tableOrder: leftovers.map((c) => TableOrder.cardKey(c.id)).toList(),
      turnDeadline: next.turnDeadline,
      turnDurationSeconds: next.turnDurationSeconds,
    );
  }

  Future<void> _flyCommit(
    GameState commit,
    List<CardMoveEvent> events,
    Map<String, Offset> origins,
  ) async {
    if (_disposed) return;
    final handoff = dragHandoff;
    dragHandoff = null;

    if (events.isNotEmpty) {
      motion.markInFlight(events.map((e) => e.card.id));
    }

    _adoptIncomingState(commit);
    if (_disposed) return;
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
        if (zone.holderId == me) {
          if (gameState.gameMode == GameMode.rummy &&
              cardId != null &&
              isRummyBoxed(cardId)) {
            return rummyBoxLayoutForCard(cardId).cardWidth;
          }
          return rummyHandCardWidth;
        }
        final ids = oppIds;
        final topOpp = ids.length <= 1
            ? (ids.isEmpty ? null : ids.first)
            : (ids.length > 1 ? ids[1] : null);
        if (topOpp == null || zone.holderId == topOpp) return 54.0;
        return 30.0;
      case ZoneType.table:
      case ZoneType.stack:
        return 72.0;
      case ZoneType.gameDeck:
        return isCasinoFamily ? 52.0 : 72.0;
      case ZoneType.playerDeck:
        return 52.0;
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
            ? (isRummyBoxed(e.card.id)
                  ? keyForCard(e.card.id, CardSlot.rummyBox)
                  : keyForCard(e.card.id, CardSlot.myHand))
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
        if (pid == me && isRummyBoxed(e.card.id)) {
          return keyForCard(e.card.id, CardSlot.rummyBox);
        }
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

  /// Gather visible cards to the table, wash, square on the shoe — then commit.
  Future<void> _playShuffleMotion({
    Future<void> Function()? onHidden,
    Future<void> Function()? onSquared,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    if (_disposed) return;

    final cards = _collectShuffleCardSources();
    final center = _centerOf(tableKey);
    final deckTarget = _centerOf(deckKey) ?? center;
    if (cards.isEmpty || center == null || deckTarget == null) {
      motion.setShuffling(true);
      await onHidden?.call();
      if (_disposed) return;
      await onSquared?.call();
      if (_disposed) return;
      motion.setShuffling(false);
      motion.clearInFlight();
      return;
    }

    final hideIds = cards.map((c) => c.hideId).whereType<String>().toList();

    await motion.runShuffle(
      ShuffleRequest(
        cards: cards,
        center: center,
        deckTarget: deckTarget,
        targetCardWidth: isCasinoFamily ? 52.0 : 60.0,
      ),
      onFlyersAttached: () async {
        if (_disposed) return;
        if (hideIds.isNotEmpty) motion.markInFlight(hideIds);
        motion.setShuffling(true);
        notifyListeners();
      },
      onHidden: onHidden,
      onSquared: () async {
        if (_disposed) return;
        motion.clearInFlight();
        await onSquared?.call();
      },
    );
  }

  List<ShuffleCardSource> _collectShuffleCardSources() {
    final sources = <ShuffleCardSource>[];

    void addCard({
      required GlobalKey? key,
      required String? hideId,
      required double width,
      required bool faceUp,
      PlayingCardModel? card,
    }) {
      final origin = _centerOf(key);
      if (origin == null) return;
      sources.add(
        ShuffleCardSource(
          origin: origin,
          width: width,
          faceUp: faceUp,
          card: card,
          hideId: hideId,
        ),
      );
    }

    void addPileBacks({
      required GlobalKey pileKey,
      required int count,
      required double width,
    }) {
      final origin = _centerOf(pileKey);
      if (origin == null || count <= 0) return;
      // Match CardDeck's visual thickness instead of one flyer per card.
      // A full 52-card shoe used to stack ~50 backs 2px apart (~100px tall).
      final n = ShuffleRequest.pileBackCount(count);
      for (var i = 0; i < n; i++) {
        sources.add(
          ShuffleCardSource(
            origin: origin + Offset(0, -i * ShuffleRequest.pileBackStep),
            width: width,
            faceUp: false,
            hideId: null,
          ),
        );
      }
    }

    final deckWidth = isCasinoFamily ? 52.0 : 72.0;
    if (gameState.deck.isNotEmpty) {
      final top = gameState.deck.last;
      final topKey = keyForCard(top.id, CardSlot.aux);
      if (topKey.currentContext != null) {
        addCard(key: topKey, hideId: top.id, width: deckWidth, faceUp: false);
        if (gameState.deck.length > 1) {
          addPileBacks(
            pileKey: deckKey,
            count: gameState.deck.length - 1,
            width: deckWidth,
          );
        }
      } else {
        addPileBacks(
          pileKey: deckKey,
          count: gameState.deck.length,
          width: deckWidth,
        );
      }
    }

    for (final card in gameState.playingArea) {
      addCard(
        key: keyForCard(card.id, CardSlot.table),
        hideId: card.id,
        width: 72.0,
        faceUp: true,
        card: card,
      );
    }

    for (final stack in gameState.playingAreaStacks) {
      for (final card in stack.cards) {
        addCard(
          key: keyForCard(card.id, CardSlot.inStack),
          hideId: card.id,
          width: 72.0,
          faceUp: true,
          card: card,
        );
      }
    }

    for (final pid in gameState.playersInfo.keys) {
      final hand = gameState.hands[pid] ?? [];
      if (hand.isEmpty) continue;
      final slot = pid == me ? CardSlot.myHand : CardSlot.oppHand;
      final faceUp =
          pid == me || gameState.round.roundStatus == RoundStatus.completed;
      for (final card in hand) {
        addCard(
          key: keyForCard(card.id, slot),
          hideId: card.id,
          width: _widthForZone(Zone(type: ZoneType.playerHand, holderId: pid)),
          faceUp: faceUp,
          card: faceUp ? card : null,
        );
      }
    }

    addPileBacks(
      pileKey: myDeckKey,
      count: myCollectedCards.length,
      width: 52.0,
    );
    addPileBacks(
      pileKey: oppDeckKey,
      count: oppCollectedCards.length,
      width: 52.0,
    );

    return sources;
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
      inGameAction == InGameAction.noAction &&
      gameState.round.roundStatus == RoundStatus.playing;

  bool isSeatTurn(String pid) =>
      pid.isNotEmpty && isLiveTurn && gameState.currentTurnPlayerId == pid;

  /// Tres y Dos: still need to draw or take before playing a card back.
  bool get needsTakeHint =>
      canPlayTurn &&
      isLiveTurn &&
      GameRegistry.isDrawDiscardFamily(gameState.gameMode) &&
      myHandCards.length != _playHandSizeFor(gameState.gameMode);

  int _playHandSizeFor(GameMode mode) => switch (mode) {
    GameMode.tresydos => 6,
    GameMode.rummy => 8,
    _ => 0,
  };

  Duration get turnTotal => gameState.turnDuration;

  DateTime? turnDeadlineFor(String pid) {
    if (tutorialMode || pid.isEmpty) return null;
    if (!_sharedTurnClockLive) return null;
    if (gameState.currentTurnPlayerId != pid) return null;
    return gameState.turnDeadline;
  }

  bool get _sharedTurnClockLive =>
      !tutorialMode &&
      gameState.gameMode == GameMode.casinoSpeed &&
      gameState.gameStatus == GameStatus.inProgress &&
      inGameAction == InGameAction.noAction &&
      gameState.round.roundStatus == RoundStatus.playing &&
      (gameState.currentTurnPlayerId ?? '').isNotEmpty &&
      !gameState.isLocalBotPid(gameState.currentTurnPlayerId);

  List<PlayingCardModel> get myHandCards => gameState.hands[me] ?? [];

  /// Cards shown in the bottom hand fan (excludes Rummy box overlays).
  List<PlayingCardModel> get myHandFanCards => myUnboxedHandCards;

  /// Rummy: cards that are currently *not* assigned to dotted boxes.
  ///
  /// We keep [myHandCards] as the full hand (engine hand-size rules depend
  /// on it). UI only shows [myUnboxedHandCards] so discarding happens via
  /// unboxed cards.
  List<PlayingCardModel> get myUnboxedHandCards {
    if (gameState.gameMode != GameMode.rummy) return myHandCards;
    final rummy = gameState.rummyState;
    if (rummy == null) return myHandCards;

    final boxed = <String>{};
    boxed.addAll(rummy.boxAByPid[me] ?? const []);
    boxed.addAll(rummy.boxBByPid[me] ?? const []);
    if (boxed.isEmpty) return myHandCards;

    return myHandCards.where((c) => !boxed.contains(c.id)).toList();
  }

  /// Laid-out width for cards sitting in a Rummy requirement box.
  static const double rummyBoxMaxCardWidth = RummyBoxLayout.maxCardWidth;
  static const double rummyHandCardWidth = 110.0;
  static const double rummyTableCardWidth = 72.0;

  /// @deprecated Use [rummyBoxMaxCardWidth] or [rummyBoxLayoutForCount].
  static const double rummyBoxCardWidth = rummyBoxMaxCardWidth;

  int rummyBoxCount({required int boxIndex, String? addingCardId}) {
    final rummy = gameState.rummyState;
    if (rummy == null) return addingCardId == null ? 0 : 1;
    final list = boxIndex == 0 ? rummy.boxAByPid[me] : rummy.boxBByPid[me];
    var count = list?.length ?? 0;
    if (addingCardId != null && !(list?.contains(addingCardId) ?? false)) {
      count += 1;
    }
    return count;
  }

  int rummyBoxCountForCard(String cardId) {
    final rummy = gameState.rummyState;
    if (rummy == null) return 1;
    final pid = me;
    final a = rummy.boxAByPid[pid];
    if (a?.contains(cardId) ?? false) return a!.length;
    final b = rummy.boxBByPid[pid];
    if (b?.contains(cardId) ?? false) return b!.length;
    return 1;
  }

  RummyBoxLayout rummyBoxLayoutForCount(int count) =>
      RummyBoxLayout.forCount(count);

  RummyBoxLayout rummyBoxLayoutForCard(String cardId) =>
      RummyBoxLayout.forCount(rummyBoxCountForCard(cardId));

  bool isRummyBoxed(String cardId) {
    if (gameState.gameMode != GameMode.rummy) return false;
    final rummy = gameState.rummyState;
    if (rummy == null) return false;
    final pid = me;
    return (rummy.boxAByPid[pid]?.contains(cardId) ?? false) ||
        (rummy.boxBByPid[pid]?.contains(cardId) ?? false);
  }

  bool get hasRummyBoxedCards {
    if (gameState.gameMode != GameMode.rummy) return false;
    final rummy = gameState.rummyState;
    if (rummy == null) return false;
    return (rummy.boxAByPid[me]?.isNotEmpty ?? false) ||
        (rummy.boxBByPid[me]?.isNotEmpty ?? false);
  }

  /// Local overlay only: cards stay in the engine hand, they just leave
  /// the dotted boxes and return to the fan.
  void returnAllRummyBoxesToHand() {
    if (gameState.gameMode != GameMode.rummy) return;
    if (isAnimating || hasDropPending) return;
    final rummy = gameState.rummyState;
    if (rummy == null) return;
    final a = rummy.boxAByPid[me];
    final b = rummy.boxBByPid[me];
    if ((a == null || a.isEmpty) && (b == null || b.isEmpty)) return;
    a?.clear();
    b?.clear();
    notifyListeners();
  }

  /// Drag ghost width while hovering a drop target in Rummy.
  double rummyDragTargetWidth(
    DropTarget? target, {
    double handCardWidth = rummyHandCardWidth,
    String? cardId,
  }) {
    if (target == null) return handCardWidth;
    switch (target.kind) {
      case DropTargetKind.rummyBoxA:
        return rummyBoxLayoutForCount(
          rummyBoxCount(boxIndex: 0, addingCardId: cardId).clamp(1, 7),
        ).cardWidth;
      case DropTargetKind.rummyBoxB:
        return rummyBoxLayoutForCount(
          rummyBoxCount(boxIndex: 1, addingCardId: cardId).clamp(1, 7),
        ).cardWidth;
      case DropTargetKind.playerHand:
        return handCardWidth;
      case DropTargetKind.emptyTable:
      case DropTargetKind.tableCard:
      case DropTargetKind.tableStack:
        return rummyTableCardWidth;
    }
  }

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
    _rememberMyHandOrder();
    notifyListeners();
  }

  bool _handIsRanked(List<PlayingCardModel> hand, {required bool descending}) {
    for (var i = 1; i < hand.length; i++) {
      final cmp = hand[i].valueHigh.compareTo(hand[i - 1].valueHigh);
      if (descending ? cmp > 0 : cmp < 0) return false;
    }
    return true;
  }

  void _rememberMyHandOrder() {
    _myHandOrderIds = handOrderIds(gameState.hands[me] ?? const []);
  }

  void _adoptIncomingState(GameState incoming) {
    _preserveMyHandOrder(incoming);
    gameState = incoming;
    _rememberMyHandOrder();
  }

  /// Re-apply this player's fan order onto [incoming].
  void _preserveMyHandOrder(GameState incoming) {
    final incomingHand = incoming.hands[me];
    if (incomingHand == null) return;
    applyPreferredHandOrder(incomingHand, _myHandOrderIds);
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
    _rememberMyHandOrder();
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
    _rememberMyHandOrder();
    notifyListeners();
  }

  /// Reorder a card within a Rummy requirement box overlay.
  void moveRummyBoxCardTo(int boxIndex, int from, int toIndex) {
    final rummy = gameState.rummyState;
    if (rummy == null) return;
    final pid = me;
    final map = boxIndex == 0 ? rummy.boxAByPid : rummy.boxBByPid;
    final list = map[pid];
    if (list == null || from < 0 || from >= list.length) return;
    final target = toIndex.clamp(0, list.length - 1);
    if (from == target) return;
    final id = list.removeAt(from);
    list.insert(target, id);
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

  bool beginBoardDrag(BoardDragSource source) {
    if (isAnimating || dropPending != null) return false;
    if (tutorialMode &&
        !(tutorialAllowsDrag?.call(
              cardId: source.card?.id,
              stackId: source.stack?.id,
            ) ??
            true)) {
      return false;
    }
    draggingSource = source;
    dropHover = null;
    notifyListeners();
    return true;
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
      case BoardDragKind.deckCard:
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
    if (dragHandoff == null) return;
    dragHandoff = null;
    notifyListeners();
  }

  Future<void> _flyRummyOrganizerMove({
    required PlayingCardModel card,
    required double startWidth,
    required double endWidth,
    Offset? fromGlobalCenter,
    required CardSlot toSlot,
  }) async {
    motion.markInFlight([card.id]);
    notifyListeners();

    final zone = Zone(type: ZoneType.playerHand, holderId: me);
    final flight = CardFlightRequest(
      event: CardMoveEvent(
        id: 'rummy-org-${card.id}-${DateTime.now().microsecondsSinceEpoch}',
        from: zone,
        to: zone,
        card: card,
        performedBy: me,
      ),
      fromGlobalCenter: fromGlobalCenter,
      toKey: keyForCard(card.id, toSlot),
      startWidth: startWidth,
      endWidth: endWidth,
      hapticOnLaunch: false,
    );

    try {
      await WidgetsBinding.instance.endOfFrame;
      await motion.run([flight]);
    } finally {
      motion.clearInFlight([card.id]);
    }
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
    // Tres y Dos: playing from the hand lands on the pile as the table,
    // not as a take of the face-up discard.
    final ignoreTableSlots =
        !isCasinoFamily && src?.kind == BoardDragKind.handCard;

    if (gameState.gameMode == GameMode.rummy) {
      if (_boxContains(rummyBoxAKey, global)) {
        return const DropTarget.rummyBoxA();
      }
      if (_boxContains(rummyBoxBKey, global)) {
        return const DropTarget.rummyBoxB();
      }
    }

    if (!ignoreTableSlots) {
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
    }
    if (_boxContains(tableKey, global)) {
      return const DropTarget.emptyTable();
    }
    // Tres y Dos: drag a pile card onto/toward the hand to take it.
    // Skip when the source is already a hand card so fan-reorder still works.
    // Rummy: only boxed cards unbox when dropped on the hand area.
    // Unboxed cards must not register playerHand here — that would block fan reorder.
    if (gameState.gameMode == GameMode.rummy &&
        !isCasinoFamily &&
        src?.kind == BoardDragKind.handCard &&
        skipId != null &&
        isRummyBoxed(skipId)) {
      if (_boxContains(myHandKey, global)) {
        return const DropTarget.playerHand();
      }
      final tableBox =
          tableKey.currentContext?.findRenderObject() as RenderBox?;
      if (tableBox != null && tableBox.hasSize) {
        final tableBottom = tableBox
            .localToGlobal(Offset(0, tableBox.size.height))
            .dy;
        if (global.dy >= tableBottom) {
          return const DropTarget.playerHand();
        }
      }
    } else if (!isCasinoFamily && src?.kind != BoardDragKind.handCard) {
      if (_boxContains(myHandKey, global)) {
        return const DropTarget.playerHand();
      }
      final tableBox =
          tableKey.currentContext?.findRenderObject() as RenderBox?;
      if (tableBox != null && tableBox.hasSize) {
        final tableBottom = tableBox
            .localToGlobal(Offset(0, tableBox.size.height))
            .dy;
        if (global.dy >= tableBottom) {
          return const DropTarget.playerHand();
        }
      }
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
      case BoardDragKind.deckCard:
        tableCards.add(source.card!);
      case BoardDragKind.tableStack:
        stacks.add(source.stack!);
    }

    switch (target.kind) {
      case DropTargetKind.emptyTable:
      case DropTargetKind.playerHand:
      case DropTargetKind.rummyBoxA:
      case DropTargetKind.rummyBoxB:
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
    // Tres y Dos: play a hand card onto the discard, or drag a pile card
    // into the hand to take it.
    if (!isCasinoFamily) {
      if (source.kind == BoardDragKind.handCard &&
          (target.kind == DropTargetKind.emptyTable ||
              target.kind == DropTargetKind.tableCard)) {
        final selection = CurrentCardSelection(
          pid: me,
          selectedCard: source.card,
          selectedCards: const [],
          selectedStacks: const [],
        );
        return gameEngine
            .getAvailableActions(gameState, selection)
            .whereType<PlayCardAction>()
            .toList();
      }
      if ((source.kind == BoardDragKind.tableCard ||
              source.kind == BoardDragKind.deckCard) &&
          target.kind == DropTargetKind.playerHand) {
        final selection = selectionForDrop(source, target);
        return gameEngine
            .getAvailableActions(gameState, selection)
            .whereType<TakeCardAction>()
            .toList();
      }
      return const [];
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
        label: actions.length > 1 ? 'Choose' : actionLabel(actions.first),
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
    final preview =
        target.kind == DropTargetKind.emptyTable ||
            target.kind == DropTargetKind.playerHand
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

    // Rummy: dotted boxes are grouping UI, not engine actions.
    if (gameState.gameMode == GameMode.rummy &&
        gameState.rummyState != null &&
        source.kind == BoardDragKind.handCard &&
        source.card != null) {
      final pid = me;
      final rummy = gameState.rummyState!;
      final cardId = source.card!.id;

      final boxedA = rummy.boxAByPid[pid]?.contains(cardId) ?? false;
      final boxedB = rummy.boxBByPid[pid]?.contains(cardId) ?? false;
      final isBoxed = boxedA || boxedB;

      if (target.kind == DropTargetKind.rummyBoxA ||
          target.kind == DropTargetKind.rummyBoxB) {
        final boxIndex = target.kind == DropTargetKind.rummyBoxA ? 0 : 1;
        final targetMap = boxIndex == 0 ? rummy.boxAByPid : rummy.boxBByPid;
        final alreadyInTarget = targetMap[pid]?.contains(cardId) ?? false;

        // If the card is already in this box, do NOT remove+append it.
        // That would overwrite the reorder done via onHandReorder while
        // dragging inside the same dotted box.
        if (!alreadyInTarget) {
          rummy.boxAByPid[pid]?.removeWhere((id) => id == cardId);
          rummy.boxBByPid[pid]?.removeWhere((id) => id == cardId);

          targetMap.putIfAbsent(pid, () => []);
          if (!targetMap[pid]!.contains(cardId)) {
            targetMap[pid]!.add(cardId);
          }

          final handoff = dragHandoff;
          dropHover = null;
          clearDragHandoff();
          final endLayout = rummyBoxLayoutForCount(
            rummyBoxCount(boxIndex: boxIndex),
          );
          notifyListeners();
          await _flyRummyOrganizerMove(
            card: source.card!,
            startWidth: handoff?.width ?? rummyHandCardWidth,
            endWidth: endLayout.cardWidth,
            fromGlobalCenter: handoff?.globalCenter ?? globalCenter,
            toSlot: CardSlot.rummyBox,
          );
          return true;
        }

        dropHover = null;
        clearDragHandoff();
        notifyListeners();
        return true;
      }

      // Unbox only when the card is already boxed.
      if (target.kind == DropTargetKind.playerHand && isBoxed) {
        final boxedStartWidth = rummyBoxLayoutForCard(cardId).cardWidth;
        rummy.boxAByPid[pid]?.removeWhere((id) => id == cardId);
        rummy.boxBByPid[pid]?.removeWhere((id) => id == cardId);

        final handoff = dragHandoff;
        dropHover = null;
        clearDragHandoff();
        notifyListeners();
        await _flyRummyOrganizerMove(
          card: source.card!,
          startWidth: handoff?.width ?? boxedStartWidth,
          endWidth: rummyHandCardWidth,
          fromGlobalCenter: handoff?.globalCenter ?? globalCenter,
          toSlot: CardSlot.myHand,
        );
        return true;
      }
    }

    final actions = actionsForDrop(source, target);
    if (actions.isEmpty) {
      dropHover = null;
      dragHandoff = null;
      notifyListeners();
      return false;
    }

    final selection = selectionForDrop(source, target);
    final preview =
        target.kind == DropTargetKind.emptyTable ||
            target.kind == DropTargetKind.playerHand
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
          : action is TakeCardAction
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

  Future<void> playSelectedToTable() async {
    final card = selectedCard;
    if (card == null || !canDropPlay(card)) return;
    await performPlayAction(PlayCardAction(usedCard: card, performedById: me));
  }

  Future<void> playCardViaDrop(
    PlayingCardModel card,
    Offset globalCenter,
  ) async {
    beginBoardDrag(BoardDragSource.hand(card));
    // Synthesize empty-table drop under finger if over table.
    final target =
        hitTestDropTarget(globalCenter) ?? const DropTarget.emptyTable();
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
      if (stackId != null && t.stack?.id == stackId) {
        return pending.buildPreview;
      }
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
        _syncTurnClock();
        _syncWinCelebration();
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
    final progressFrom = DailyChallengeGameSnap.of(gameState, me);
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
        _commitStateWithMotion(
          next,
          events,
          settlementEvents: settlement,
          progressFrom: progressFrom,
        ),
      ]);
      _queueDeckCoinFlight(
        meGain: next.pendingCoinsFor(me) - beforeMe,
        oppGain: oppId == null ? 0 : next.pendingCoinsFor(oppId) - beforeOpp,
      );
    } else {
      await _commitStateWithMotion(
        next,
        events,
        settlementEvents: settlement,
        progressFrom: progressFrom,
      );
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

  /// Empty friend seats stay on the felt until Start; bots fill every chair.
  bool get showOpenSeats {
    if (tutorialMode || gameState.isLocalBot || gameState.started) {
      return false;
    }
    final status = gameState.gameStatus;
    return status == GameStatus.waitingForPlayers ||
        status == GameStatus.readyToStart;
  }

  /// Board dim + control chrome share this — never dim while motion is running.
  /// Tutorial never surfaces shuffle/deal/start; those belong to a real match.
  /// Hide shuffle/waiting until Continue on the status boards — the winning
  /// hand should stay fully visible in that beat.
  bool get showInGameControl {
    if (tutorialMode || isAnimating || motion.isShuffling) return false;
    if (gameState.gameStatus == GameStatus.gameOver) return false;
    if (gameState.gameStatus == GameStatus.inProgress &&
        gameState.round.roundStatus == RoundStatus.completed &&
        !gameState.round.nextAcknowledged) {
      return false;
    }
    return inGameAction != InGameAction.noAction;
  }

  /// Player whose winning layout is highlighted (3+2 in Tres y Dos, contract in Rummy).
  String? get celebratingHandPid {
    if (motion.isShuffling) return null;
    final inMatch = gameState.gameStatus == GameStatus.inProgress;
    final gameOver = gameState.gameStatus == GameStatus.gameOver;
    final roundDone = gameState.round.roundStatus == RoundStatus.completed;
    if (!gameOver && !(inMatch && roundDone)) return null;

    if (gameState.gameMode == GameMode.tresydos) {
      for (final pid in gameState.playersInfo.keys) {
        if (TresDosGameStateHandler.roundEnded(gameState, pid)) return pid;
      }
      final winner = gameState.winnerId;
      if (winner != null && winner.isNotEmpty) return winner;
      return null;
    }

    if (gameState.gameMode == GameMode.rummy) {
      final winner = gameState.winnerId;
      if (winner != null && winner.isNotEmpty) return winner;
      return null;
    }

    return null;
  }

  bool isCelebratingHand(String pid) =>
      pid.isNotEmpty && celebratingHandPid == pid;

  /// Player id whose avatar should receive the win celebration confetti.
  String? get winCelebrationPid {
    if (gameState.gameMode == GameMode.tresydos ||
        gameState.gameMode == GameMode.rummy) {
      return celebratingHandPid ?? gameState.winnerId;
    }
    return gameState.winnerId;
  }

  String? get _liveWinCelebrationKey {
    if (motion.isShuffling) return null;
    final inMatch = gameState.gameStatus == GameStatus.inProgress;
    final gameOver = gameState.gameStatus == GameStatus.gameOver;
    final roundDone = gameState.round.roundStatus == RoundStatus.completed;
    if (!gameOver && !(inMatch && roundDone)) return null;
    if (gameState.gameMode != GameMode.tresydos &&
        gameState.gameMode != GameMode.rummy &&
        !isCasinoFamily) {
      return null;
    }
    if (gameOver) return 'over_${gameState.round.id}_${gameState.winnerId}';
    return 'round_${gameState.round.id}';
  }

  Duration get _winCelebrationDuration =>
      gameState.gameMode == GameMode.tresydos ||
          gameState.gameMode == GameMode.rummy
      ? _winCelebrationFor
      : const Duration(seconds: 3);

  bool get showWinCelebration =>
      _liveWinCelebrationKey != null && winCelebrationSecondsLeft > 0;

  String? get activeWinCelebrationKey => _winCelebrationKey;

  void _syncWinCelebration() {
    final key = _liveWinCelebrationKey;
    if (key == null) {
      _stopWinCelebration();
      return;
    }
    if (_winCelebrationKey == key) return;
    _winCelebrationKey = key;
    _winCelebrationSkipped = false;
    final duration = _winCelebrationDuration;
    _winCelebrationDeadline = DateTime.now().add(duration);
    _winCelebrationSecondsLeft = duration.inSeconds;
    if (key.startsWith('round_') ||
        (gameState.gameMode == GameMode.rummy && key.startsWith('over_'))) {
      SoundService.instance.play(GameSound.win);
    }
    _winCelebrationTimer?.cancel();
    _winCelebrationTimer = Timer.periodic(const Duration(milliseconds: 200), (
      _,
    ) {
      if (_disposed) return;
      final next = winCelebrationSecondsLeft;
      if (next != _winCelebrationSecondsLeft) {
        _winCelebrationSecondsLeft = next;
        notifyListeners();
      }
      if (next <= 0) {
        _winCelebrationTimer?.cancel();
        _winCelebrationTimer = null;
      }
    });
  }

  void _stopWinCelebration() {
    _winCelebrationTimer?.cancel();
    _winCelebrationTimer = null;
    _winCelebrationDeadline = null;
    _winCelebrationKey = null;
    _winCelebrationSkipped = false;
    _winCelebrationSecondsLeft = 0;
  }

  int get winCelebrationSecondsLeft {
    if (_winCelebrationSkipped) return 0;
    final deadline = _winCelebrationDeadline;
    if (deadline == null) return 0;
    final ms = deadline.difference(DateTime.now()).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / 1000).ceil();
  }

  Future<void> performInGameAction(InGameAction action) =>
      _performInGameAction(action, me);

  Future<void> _performInGameAction(InGameAction action, String pid) async {
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
            final progressFrom = DailyChallengeGameSnap.of(gameState, me);
            final next = gameEngine.performInGameAction(gameState, action, pid);
            final events = List<CardMoveEvent>.from(next.cardMoveEvents);
            if (!tutorialMode) {
              for (final e in events) {
                gameRepo.lastPlayedIds.add(e.id);
              }
              await gameRepo.fs.updateGame(next);
            }
            await _commitStateWithMotion(
              next,
              events,
              progressFrom: progressFrom,
            );
          },
          onSquared: () async {
            motion.setShuffling(false);
            motion.clearInFlight();
          },
        );
        return;
      }

      final progressFrom = DailyChallengeGameSnap.of(gameState, me);
      final next = gameEngine.performInGameAction(gameState, action, pid);
      final events = List<CardMoveEvent>.from(next.cardMoveEvents);

      if (!tutorialMode) {
        for (final e in events) {
          gameRepo.lastPlayedIds.add(e.id);
        }
        await gameRepo.fs.updateGame(next);
      }

      await _commitStateWithMotion(next, events, progressFrom: progressFrom);
    } catch (e) {
      developer.log("performInGameAction Error $e");
    } finally {
      motion.setShuffling(false);
      isAnimating = false;
      _syncTurnClock();
      _syncWinCelebration();
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
      _rememberMyHandOrder();
      _syncRevealedPending();
      _syncWinCelebration();
      _syncTurnClock();
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      developer.log("GenGameViewModel.loadGame Error: $e");
    }
    return false;
  }

  Future<JoinGameResult> joinGame() async {
    var chargedCoins = 0;
    var chargedEnergy = 0;
    try {
      final alreadySeated = gameState.playersInfo.containsKey(player.id);
      if (!alreadySeated) {
        if (gameState.started ||
            gameState.gameStatus == GameStatus.inProgress ||
            gameState.gameStatus == GameStatus.gameOver) {
          return JoinGameResult.failed;
        }
        if (gameState.playersInfo.length >= gameState.maxSeats) {
          return JoinGameResult.failed;
        }
      }

      if (!alreadySeated &&
          !tutorialMode &&
          !gameState.isLocalBot &&
          !gameState.entryPaidBy.contains(player.id)) {
        final cost = gameState.entryCost;
        final energyCost = WalletConfig.energyCostFor(gameState.gameMode.name);
        if (appRepo.wallet.energy < energyCost) {
          return JoinGameResult.notEnoughEnergy;
        }
        if (appRepo.wallet.coins < cost) {
          return JoinGameResult.notEnoughCoins;
        }
        final spentEnergy = await appRepo.trySpendEnergy(energyCost);
        if (!spentEnergy) return JoinGameResult.notEnoughEnergy;
        chargedEnergy = energyCost;
        final spent = await appRepo.trySpendCoins(cost);
        if (!spent) {
          await appRepo.grantEnergy(chargedEnergy);
          chargedEnergy = 0;
          return JoinGameResult.notEnoughCoins;
        }
        chargedCoins = cost;
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
      if (chargedCoins > 0) {
        await appRepo.grantCoins(chargedCoins);
        gameState.entryPaidBy.remove(player.id);
      }
      if (chargedEnergy > 0) {
        await appRepo.grantEnergy(chargedEnergy);
      }
    }
    return JoinGameResult.failed;
  }

  Future<void> resign() async {
    final remaining = gameState.playersInfo.keys
        .where((id) => id != me)
        .toList();
    if (remaining.isEmpty || tutorialMode) {
      await appRepo.deleteGame(gameState.id);
      notifyListeners();
      return;
    }

    gameState.cardMoveEvents = [];
    gameState.settlementEvents = [];
    // Resign should pay the match winner: the best remaining seat.
    // (Heads-up collapses to "the opponent"; multi-seat ranks by score.)
    final paidRemaining = remaining
        .where((pid) => gameState.entryPaidBy.contains(pid))
        .toList();
    final candidates = paidRemaining.isNotEmpty ? paidRemaining : remaining;
    String best = candidates.first;
    for (final pid in candidates.skip(1)) {
      final cur = gameState.scoreOf(pid);
      final bestScore = gameState.scoreOf(best);
      if (cur > bestScore || (cur == bestScore && pid.compareTo(best) < 0)) {
        best = pid;
      }
    }
    gameState.winnerId = best;
    gameState.gameStatus = GameStatus.gameOver;
    await gameRepo.fs.updateGame(gameState);
    notifyListeners();
  }

  /// After round/game status sheet — show shuffle/waiting; dealer taps Shuffle.
  Future<void> continueAfterRound() async {
    if (gameState.gameStatus == GameStatus.gameOver) {
      notifyListeners();
      return;
    }
    if (gameState.round.roundStatus != RoundStatus.completed) return;

    gameState.round.nextAcknowledged = true;
    notifyListeners();

    // Bot dealer: play the gather-wash here. The on-device AI mutates the
    // shared GameState in place, which skips the repo-echo overlay.
    if (gameState.isLocalBotPid(gameState.controllerId)) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (_disposed) return;
      if (gameState.round.roundStatus != RoundStatus.completed) return;
      if (!isAnimating) {
        await _performInGameAction(
          InGameAction.shuffle,
          gameState.controllerId,
        );
        return;
      }
    }

    if (!tutorialMode) {
      await gameRepo.fs.updateGame(gameState);
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
    AppHaptics.heavyImpact();
    SoundService.instance.playLayered(GameSound.softCard, volume: 0.55);
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

  Future<void> queueHomeDailyChallengeEnergyClaims() async {
    if (tutorialMode) return;
    await appRepo.queueHomeDailyChallengeEnergyClaims(gameState);
  }

  Future<void> queueHomeXpClaim() async {
    if (tutorialMode) return;
    await appRepo.queueHomeXpClaim(gameState, me);
  }

  /// Occasional local-bot emoji after a play/take. Never writes game state.
  void _maybeBotReact({
    required bool took,
    required bool botPlayed,
    String? fromPid,
  }) {
    if (_disposed) return;
    if (!gameState.isLocalBot && !tutorialMode) return;
    if (gameState.round.roundStatus != RoundStatus.playing) return;
    if (gameState.gameStatus == GameStatus.gameOver) return;
    final botId = fromPid ?? gameState.localBotPid ?? opp;
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
    _turnTimer?.cancel();
    _winCelebrationTimer?.cancel();
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
  final GlobalKey tableContentKey = GlobalKey();
  final GlobalKey myDeckKey = GlobalKey();
  final GlobalKey oppDeckKey = GlobalKey();
  final GlobalKey myHandKey = GlobalKey();
  final GlobalKey oppHandKey = GlobalKey();
  final GlobalKey rummyBoxAKey = GlobalKey();
  final GlobalKey rummyBoxBKey = GlobalKey();
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

  final Map<String, GlobalKey> _celebrationAvatarKeys = {};

  /// GlobalKey for the winner's avatar UI.
  /// Uses shared keys for me/opp in 1v1, and per-pid keys for multi-seat games.
  GlobalKey celebrationAvatarKeyForPid(String pid) {
    if (pid == me) return scoreKey;
    if (opp != null && pid == opp) return oppScoreKey;
    return _celebrationAvatarKeys.putIfAbsent(
      pid,
      () => GlobalKey(debugLabel: 'celebrate_$pid'),
    );
  }
}
