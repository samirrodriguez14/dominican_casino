import 'dart:developer' as developer;
import 'package:dominican_casino/tutorial/tutorial_casino_factory.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart' hide Action;
import 'package:flutter/services.dart';

typedef ActionGuard =
    bool Function(
      TutorialAction action, {
      String? cardId,
      String? stackId,
      List<String> selectedCardIds,
    });

typedef HandleTutorialGameState = void Function();

class GeneralGameViewModel extends ChangeNotifier {
  bool loading = true;
  bool tutorialMode;
  final GameRepo gameRepo;
  final GameEngine gameEngine;
  Player player;
  String gid;
  late GameState gameState;
  bool isAnimating = false;
  final List<CardMoveEvent> pendingFlyEvents = [];

  ActionGuard? actionGuard;
  HandleTutorialGameState? handleTutorialOpponentMove;

  GeneralGameViewModel({
    required this.gameRepo,
    required this.gameEngine,
    required this.player,
    required this.gid,
    this.tutorialMode = false,
  }) {
    gameRepo.addListener(_onGameRepoChanged);
  }

  void _onGameRepoChanged() async {
    // Prevent concurrent animations
    if (isAnimating) return;

    try {
      final nextState = gameRepo.gameState!;
      isAnimating = true;
      developer.log(
        "tM: $tutorialMode, cpid: ${gameState.currentTurnPlayerId}, oppId = $opp. $handleTutorialOpponentMove",
      );

      if ((tutorialMode &&
          handleTutorialOpponentMove != null &&
          gameState.currentTurnPlayerId == opp)|| gameState.round.roundStatus ==.completed) {
        handleTutorialOpponentMove!();
        developer.log("handling tutorial next step");
      }
      // Get new events from other players
      final newEvents = nextState.cardMoveEvents
          .where((e) => !gameRepo.lastPlayedIds.contains(e.id))
          .toList();

      if (newEvents.isNotEmpty) {
        pendingFlyEvents.addAll(newEvents);
        // Hide cards for animation
        for (final event in newEvents) {
          hiddenCardIds.add(event.card.id);
          gameRepo.lastPlayedIds.add(event.id);
        }

        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300));

        gameState = nextState;
        HapticFeedback.heavyImpact();
        if (nextState.currentTurnPlayerId == me) {
          SoundService.instance.play(GameSound.yourTurn);
        }
        selectedCard = null;
        selectedCards = [];
        selectedStacks = [];

        hiddenCardIds.clear();

        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 100));

        notifyListeners();
      } else {
        gameState = nextState;
        notifyListeners();
      }

      isAnimating = false;
    } catch (e) {
      developer.log("GameViewModel._onGameRepoChanged Error $e");
      isAnimating = false;
      notifyListeners();
    }
  }

  List<PlayingCardModel> get playingAreaCards => gameState.playingArea;
  //      PLAYING AREA STACKS
  List<PlayingAreaStackModel> get playingAreaStacks =>
      gameState.playingAreaStacks;

  //      MY CURR HAND
  //      MY COLLECTED CARDS
  String get me => player.id;

  int get myExtraPoints =>
      (gameState.extraPointsHolderId == player.id) ? gameState.extraPoints : 0;
  bool get isMyTurn => gameState.currentTurnPlayerId == me;

  List<PlayingCardModel> get myHandCards => gameState.hands[me] ?? [];
  List<PlayingCardModel> get myCollectedCards {
    return gameState.playersDeck[me] ?? [];
  }

  void sortHandCards() {
    gameState.hands[me]?.sort((a, b) => b.valueHigh.compareTo(a.valueHigh));
    notifyListeners();
  }

  //      EXTRA POINTS

  //      OPPONENTS HAND
  //      OPPONENTS COLLECTED CARDS
  String? get opp {
    return (gameState.playersInfo.length > 1)
        ? gameState.playersInfo.entries.firstWhere((p) => p.key != me).key
        : null;
  }

  List<String> get oppIds {
    return sortIds(me).sublist(1);
  }

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

  //      POSSIBLE ACTIONS:
  CurrentCardSelection get cardSelection => CurrentCardSelection(
    pid: me,
    selectedCard: selectedCard,
    selectedCards: selectedCards,
    selectedStacks: selectedStacks,
  );
  List<PlayAction> get possiblePlayActions =>
      gameEngine.getAvailableActions(gameState, cardSelection);

  Future<void> performPlayAction(PlayAction action) async {
    // Prevent concurrent animations
    if (isAnimating) return;
    isAnimating = true;

    // Hide the selected cards/stacks before the state transition so they animate out.
    hiddenCardIds.clear();

    if (cardSelection.selectedCard != null) {
      hiddenCardIds.add(cardSelection.selectedCard!.id);
    }
    hiddenCardIds.addAll(cardSelection.selectedCards.map((e) => e.id));
    for (var stack in cardSelection.selectedStacks) {
      hiddenCardIds.addAll(stack.cards.map((e) => e.id));
    }

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));

    gameState = gameEngine.performPlayAction(
      gameState,
      cardSelection,
      action,
    );
    if (!tutorialMode) {
      gameState = await gameRepo.fs.updateGame(gameState);
    }

    final actionName = action.runtimeType.toString();
    if (actionName.contains('Take')) {
      SoundService.instance.play(GameSound.capture);
    } else {
      SoundService.instance.play(GameSound.deal);
    }
    if (gameState.gameStatus == GameStatus.gameOver) {
      SoundService.instance.play(GameSound.win);
    }

    selectedCard = null;
    selectedCards = [];
    selectedStacks = [];
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 50));
    hiddenCardIds.clear();
    isAnimating = false;
    notifyListeners();
  }

  //IN GAME ACTION
  InGameAction get inGameAction => gameEngine.getInGameAction(gameState, me);

  Future<void> performInGameAction(InGameAction action) async {
    gameState = gameEngine.performInGameAction(gameState, action, me);
    if (!tutorialMode) {
      gameState = await gameRepo.fs.updateGame(gameState);
    }
    if (action == InGameAction.deal || action == InGameAction.dealSame) {
      SoundService.instance.play(GameSound.deal);
    }
    notifyListeners();
  }

  //OUT OF GAME ACTIONS
  Future<bool> loadGame() async {
    try {
      if (tutorialMode) {
        gameState = TutorialCasinoFactory.createBasicTakeTutorial(
          gid: gid,
          playerId: me,
          gameRepo: gameRepo,
        );

        loading = false;
        notifyListeners();
        return true;
      }
      gameState = await gameRepo.fs.loadGame(gid);
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
      // Never persist FCM tokens on game docs — only public profile fields.
      gameState.playersInfo[player.id] = {
        'id': player.id,
        'name': player.name,
      };
      if (gameEngine.shouldMarkReadyToStart(gameState) &&
          gameState.gameStatus == GameStatus.waitingForPlayers) {
        gameState.gameStatus = GameStatus.readyToStart;
      }
      if (!tutorialMode) {
        await gameRepo.fs.updateGame(gameState);
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
    gameState.winnerId = opp;
    gameState.gameStatus = GameStatus.gameOver;
    await gameRepo.fs.updateGame(gameState);
    notifyListeners();
  }

  ///CARD SELECTION START
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
    if (!_canPerform(TutorialAction.selectHandCard, cardId: card.id)) {
      return;
    }
    if (selectedCard == card) {
      selectedCard = null;
    } else {
      selectedCard = card;
    }
    notifyListeners();
  }

  void selectCardToTake(PlayingCardModel? card) {
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

    notifyListeners();
  }

  void selectCardToStack(PlayingCardModel card) {
    if (!_canPerform(TutorialAction.selectTableCard, cardId: card.id)) {
      return;
    }

    if (selectedCards.contains(card)) {
      selectedCards.remove(card);
    } else {
      selectedCards.add(card);
    }

    notifyListeners();
  }

  void selectStack(PlayingAreaStackModel stack) {
    if (!_canPerform(TutorialAction.selectStack, stackId: stack.id)) {
      return;
    }
    if (selectedStacks.contains(stack)) {
      selectedStacks.remove(stack);
    } else {
      selectedStacks.add(stack);
    }
    if (selectedStacks.length > 1) selectedCard = null;
    notifyListeners();
  }

  ///
  ///CARD SELECTION FINISH

  @override
  void dispose() {
    gameRepo.removeListener(_onGameRepoChanged);
    super.dispose();
  }

  bool isCardHidden(PlayingCardModel card) {
    return hiddenCardIds.contains(card.id);
  }

  bool stackContainsCardHidded(List<PlayingCardModel> cards) {
    for (var card in cards) {
      if (hiddenCardIds.contains(card.id)) {
        return true;
      }
    }
    return false;
  }

  final Map<String, GlobalKey> cardKeys = {};
  final Set<String> hiddenCardIds = {};

  GlobalKey keyForCard(String cardId) {
    return cardKeys.putIfAbsent(cardId, () => GlobalKey());
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
        return tableKey;
    }
  }
}
