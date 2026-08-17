import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
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
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/tutorial/tutorial_casino_factory.dart';
import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:flutter/cupertino.dart' hide Action;

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

class GeneralGameViewModel extends ChangeNotifier {
  bool loading = true;
  bool tutorialMode;
  final GameRepo gameRepo;
  final GameEngine gameEngine;
  Player player;
  String gid;
  late GameState gameState;
  bool isAnimating = false;
  bool _pendingRepoSync = false;
  bool _syncScheduled = false;
  bool _disposed = false;

  /// Round id whose gather-wash already played — skip a second overlay on repo echo.
  int? _shuffleOverlayRoundId;

  /// Destination slots stay laid out but invisible until flights land.
  final CardMotionController motion = CardMotionController();

  ActionGuard? actionGuard;

  GeneralGameViewModel({
    required this.gameRepo,
    required this.gameEngine,
    required this.player,
    required this.gid,
    this.tutorialMode = false,
  }) {
    gameRepo.addListener(_onGameRepoChanged);
    motion.addListener(notifyListeners);
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
        final alreadyPlayed =
            _shuffleOverlayRoundId == nextState.round.id;

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
        ? 320
        : 220;
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
      lastTookCardId: next.lastTookCardId,
      cardMoveEvents: List<CardMoveEvent>.from(next.cardMoveEvents),
      settlementEvents: List<CardMoveEvent>.from(next.settlementEvents),
      round: next.round,
      winnerId: next.winnerId,
      playersInfo: Map<String, dynamic>.from(next.playersInfo),
      isLocalBot: next.isLocalBot,
      botPlayerId: next.botPlayerId,
      tableOrder: leftovers.map((c) => TableOrder.cardKey(c.id)).toList(),
    );
  }

  Future<void> _flyCommit(
    GameState commit,
    List<CardMoveEvent> events,
    Map<String, Offset> origins,
  ) async {
    if (events.isNotEmpty) {
      motion.markInFlight(events.map((e) => e.card.id));
    }

    gameState = commit;
    notifyListeners();

    if (events.isEmpty) return;

    final flights = events.map((e) {
      final startUp = _startFaceUpFor(e);
      final endUp = _endFaceUpFor(e);
      return CardFlightRequest(
        event: e,
        fromGlobalCenter: origins[e.card.id],
        fromKey: keyForZone(e.from),
        toKey: _resolveToKey(e),
        startFaceUp: startUp,
        endFaceUp: endUp,
        flip: startUp != endUp,
        startWidth: _widthForZone(e.from),
        endWidth: _widthForZone(e.to, cardId: e.card.id),
        hapticOnLaunch: true,
      );
    }).toList();

    await motion.run(flights);
  }

  /// Match the laid-out card size at each zone so flights grow/shrink in flight.
  double _widthForZone(Zone zone, {String? cardId}) {
    switch (zone.type) {
      case ZoneType.playerHand:
        // Must match GenPlayerArea (100) / GenOpponentArea (50).
        return zone.holderId == me ? 100.0 : 50.0;
      case ZoneType.table:
      case ZoneType.gameDeck:
      case ZoneType.playerDeck:
      case ZoneType.stack:
        return 60.0;
    }
  }

  Map<String, Offset> _captureOrigins(List<CardMoveEvent> events) {
    final map = <String, Offset>{};
    for (final e in events) {
      // First origin wins — important when a card is played then settled to a
      // deck in the same batch (keep hand/table start, not a later zone center).
      if (map.containsKey(e.card.id)) continue;

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

    // Still in a hand (deal / rare).
    if ((gameState.hands[me] ?? []).any((c) => c.id == e.card.id)) {
      return keyForCard(e.card.id, CardSlot.myHand);
    }
    if (opp != null &&
        (gameState.hands[opp] ?? []).any((c) => c.id == e.card.id)) {
      return keyForCard(e.card.id, CardSlot.oppHand);
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
    if (box == null || !box.hasSize) return null;
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
        gameState.playingAreaStacks.fold<int>(
          0,
          (n, s) => n + s.cards.length,
        );
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
      ShuffleRequest(
        sources: sources,
        center: center,
        deckTarget: deckTarget,
      ),
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

  List<PlayingCardModel> get myHandCards => gameState.hands[me] ?? [];
  List<PlayingCardModel> get myCollectedCards =>
      gameState.playersDeck[me] ?? [];

  void sortHandCards() {
    gameState.hands[me]?.sort((a, b) => b.valueHigh.compareTo(a.valueHigh));
    notifyListeners();
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
    if (action is AddCardsAction ||
        action is AddCardStackAction ||
        action is AddTableCardsAction ||
        action is AddAndPairCardsAction ||
        action is AddAndTakeAction) {
      return TutorialAction.addStack;
    }
    if (action is TakeStackAction) {
      return TutorialAction.takeStack;
    }
    if (action is TakeCardAction) {
      return TutorialAction.sweepTable;
    }
    return TutorialAction.playMove;
  }

  Future<void> _commitPlay(
    PlayAction action,
    CurrentCardSelection selection,
  ) async {
    final next = gameEngine.performPlayAction(gameState, selection, action);
    final events = List<CardMoveEvent>.from(next.cardMoveEvents);
    final settlement = List<CardMoveEvent>.from(next.settlementEvents);

    if (!tutorialMode) {
      // Persist first so remote listeners get the same events; local motion
      // still runs from this client via _commitStateWithMotion below.
      // Mark event ids so the repo echo does not double-play.
      for (final e in [...events, ...settlement]) {
        gameRepo.lastPlayedIds.add(e.id);
      }
      await gameRepo.fs.updateGame(next);
    }

    await _commitStateWithMotion(
      next,
      events,
      settlementEvents: settlement,
    );
    if (next.gameStatus == GameStatus.gameOver) {
      SoundService.instance.play(GameSound.win);
    }
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
    if (gameState.currentTurnPlayerId != botId) return;
    if (gameState.round.roundStatus != RoundStatus.playing) return;

    final botHand = gameState.hands[botId] ?? [];
    if (botHand.isEmpty) {
      // Pass the turn back so the human can finish (the sweep).
      if ((gameState.hands[me] ?? []).isNotEmpty) {
        gameState.currentTurnPlayerId = me;
        notifyListeners();
      }
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (_disposed || gameState.currentTurnPlayerId != botId) return;

    final best = await CasinoPlayer.casinoBestAction(botId, gameState);
    if (_disposed || gameState.currentTurnPlayerId != botId) return;

    await _commitPlay(best.playAction, best.cardSelection);
  }

  InGameAction get inGameAction => gameEngine.getInGameAction(gameState, me);

  /// Board dim + control chrome share this — never dim while motion is running.
  /// Tutorial never surfaces shuffle/deal/start; those belong to a real match.
  bool get showInGameControl =>
      !tutorialMode &&
      !isAnimating &&
      inGameAction != InGameAction.noAction;

  Future<void> performInGameAction(InGameAction action) async {
    if (isAnimating) return;
    isAnimating = true;
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
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      developer.log("GenGameViewModel.loadGame Error: $e");
    }
    return false;
  }

  Future<bool> joinGame() async {
    try {
      gameState.playersInfo[player.id] = {'id': player.id, 'name': player.name};
      if (gameEngine.shouldMarkReadyToStart(gameState) &&
          gameState.gameStatus == GameStatus.waitingForPlayers) {
        gameState.gameStatus = GameStatus.readyToStart;
      }
      if (!tutorialMode) {
        await gameRepo.fs.updateGame(gameState);
        LocalPlayer.ensureAttached(gameRepo, gameState);
      }
      notifyListeners();
      return true;
    } catch (e) {
      developer.log("GameViewModel.joiningGame Error: $e");
    }
    return false;
  }

  Future<void> resign() async {
    if (opp == null || tutorialMode) {
      await gameRepo.fs.deleteGame(gameState.id);
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
    if (!_canPerform(TutorialAction.selectTableCard, cardId: card.id)) {
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

  @override
  void dispose() {
    _disposed = true;
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
