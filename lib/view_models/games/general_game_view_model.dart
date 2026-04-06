import 'dart:developer' as developer;
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:flutter/cupertino.dart' hide Action;
import 'package:flutter/services.dart';

class GeneralGameViewModel extends ChangeNotifier {
  bool loading = true;
  final GameRepo gameRepo;
  final GameEngine gameEngine;
  Player player;
  String gid;
  late GameState gameState;
  GeneralGameViewModel({
    required this.gameRepo,
    required this.gameEngine,
    required this.player,
    required this.gid,
  }) {
    gameRepo.addListener(_onGameRepoChanged);
  }

  void _onGameRepoChanged() {
    try {
      final nextState = gameRepo.gameState!;
      // final incomingEvents = nextState.cardMoveEvents
      //     .where((e) => !gameRepo.lastPlayedIds.contains(e.id))
      //     .toList();

      // for (final event in incomingEvents) {
      //   hiddenCardIds.add(event.card.id);
      // }

      gameState = nextState;
      HapticFeedback.heavyImpact();

      selectedCards = [];
      selectedCard = null;
      selectedStacks = [];

      notifyListeners();
    } catch (e) {
      developer.log("GameViewModel._onGameRepoChanged Error $e");
      notifyListeners();
    }
  }

  ///START VAR DECLARATIONS
  ///
  ///END GETTERS

  //GAME VIEW MODEL UPDATES UI... THAT'S IT!
  //GAME ENGINE +GAME RULES IS SOURCE OF TRUTH
  //WHAT THINGS MUST THE UI KNOW FOR UPDATE

  //  CURR GAME STATE...

  //      GAME STATUS: waiting, playing, roundComplete, gameOver
  //      CARD MOVE EVENTS
  //
  //      CURR SCORE
  //      LAST ROUND SCORE

  //      CURR PLAYER TURN
  //      LAST TO TAKE CARD

  //      PLAYING AREA CARDS
  List<PlayingCardModel> get playingAreaCards => gameState.playingArea;
  //      PLAYING AREA STACKS
  List<PlayingAreaStackModel> get playingAreaStacks =>
      gameState.playingAreaStacks;

  //      MY CURR HAND
  //      MY COLLECTED CARDS
  String get me => player.id;
  // String get joinedAsPlayer {
  //   return (me == gameState.player1) ? 'player1' : 'player2';
  // }

  int get myExtraPoints =>
      (gameState.extraPointsHolderId == player.id) ? gameState.extraPoints : 0;
  bool get isMyTurn => gameState.currentTurnPlayerId == me;

  List<PlayingCardModel> get myHandCards => gameState.hands[me] ?? [];
  List<PlayingCardModel> get myCollectedCards =>
      gameState.playersDeck[me] ?? [];

  //      EXTRA POINTS

  //      OPPONENTS HAND
  //      OPPONENTS COLLECTED CARDS
  String? get opp {
    return (gameState.playersInfo.length > 1)
        ? gameState.playersInfo.entries.firstWhere((p) => p.key != me).key
        : null;
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

  void performPlayAction(PlayAction action) {
    gameEngine.performPlayAction(gameState, cardSelection, action);
  }

  //IN GAME ACTION
  InGameAction get inGameAction => gameEngine.getInGameAction(gameState, me);

  void performInGameAction(InGameAction action) {
    gameEngine.performInGameAction(gameState, action, me);
  }

  //OUT OF GAME ACTIONS
  Future<bool> loadGame() async {
    try {
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
      gameState.playersInfo[player.id] = player.toJson();
      await gameRepo.fs.updateGame(gameState);
      notifyListeners();
      return true;
    } catch (e) {
      developer.log("GameViewModel.joiningGame Error: $e");
    }
    return false;
  }

  Future<void> leaveGame() async {
    gameState.cardMoveEvents = [];
    gameState.gameStatus = GameStatus.gameOver;
    await gameRepo.fs.updateGame(gameState);
    notifyListeners();
  }

  ///CARD SELECTION START
  ///
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

  void selectCard(PlayingCardModel card) {
    if (selectedCard == card) {
      selectedCard = null;
    } else {
      selectedCard = card;
    }
    notifyListeners();
  }

  void selectCardToStack(PlayingCardModel card) {
    if (selectedCards.contains(card)) {
      selectedCards.remove(card);
    } else {
      selectedCards.add(card);
    }

    notifyListeners();
  }

  void selectStack(PlayingAreaStackModel stack) {
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
