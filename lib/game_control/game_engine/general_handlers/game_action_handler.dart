import 'package:dominican_casino/game_control/game_engine/general_handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/casino_game_state_handler.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';

class GameActionHandler {
  /// Pure mutation — callers persist the returned state.
  static GameState handleGameAction(
    GameState gameState,
    InGameAction inGameAction,
    int cardsPerPlayer,
    int cardsInPlayingArea,
    int cardsPerPlayerRedeal,
    int cardsInPlayingAreaRedeal,
    String pid,
  ) {
    gameState.cardMoveEvents = [];
    gameState.settlementEvents = [];

    switch (inGameAction) {
      case InGameAction.start:
        gameState.started = true;
        gameState.gameStatus = GameStatus.inProgress;
        gameState.round.roundStatus = RoundStatus.readyToDeal;
        gameState.deck = Deck.shuffle(Deck.standard());
        return gameState;

      case InGameAction.shuffle:
        return shuffleAction(gameState, pid);

      case InGameAction.share:
      case InGameAction.deal:
        final newGameState = _dealCardsAction(
          gameState,
          pid,
          cardsPerPlayer,
          cardsInPlayingArea,
        );
        newGameState.round.roundStatus = RoundStatus.playing;
        newGameState.currentTurnPlayerId = getNextPlayerId(newGameState, pid);
        return newGameState;

      case InGameAction.dealSame:
        final newGameState = dealSameAction(
          gameState,
          pid,
          cardsPerPlayerRedeal,
          cardsInPlayingAreaRedeal,
        );
        newGameState.round.roundStatus = RoundStatus.playing;
        newGameState.currentTurnPlayerId = getNextPlayerId(newGameState, pid);
        return newGameState;

      default:
        return gameState;
    }
  }

  static GameState dealSameAction(
    GameState gameState,
    String pid,
    int cardsPerPlayer,
    int cardsInPlayingArea,
  ) {
    final playerCount = gameState.playersInfo.length;
    final neededCards = (playerCount * cardsPerPlayer);
    if (gameState.deck.length < neededCards) {
      throw Exception('Not enough cards in deck to deal.');
    }
    for (final entry in gameState.playersInfo.entries) {
      final dealtCards = gameState.deck.sublist(0, cardsPerPlayer);
      gameState.deck.removeRange(0, cardsPerPlayer);
      gameState.hands[entry.key] = List.of(dealtCards);

      gameState.cardMoveEvents.addAll(
        EventHandler.generateDealToHandEvent(dealtCards, entry.key, pid),
      );
    }
    final cardsToTable = gameState.deck.sublist(0, cardsInPlayingArea);
    gameState.deck.removeRange(0, cardsInPlayingArea);
    for (final c in cardsToTable) {
      gameState.placeCardOnTable(c);
    }

    gameState.cardMoveEvents.addAll(
      EventHandler.generateDealToTableEvent(cardsToTable, pid),
    );

    return gameState;
  }

  static GameState _dealCardsAction(
    GameState gameState,
    String pid,
    int cardsPerPlayer,
    int cardsInPlayingArea,
  ) {
    final playerCount = gameState.playersInfo.length;
    final neededCards = (playerCount * cardsPerPlayer) + cardsInPlayingArea;

    if (gameState.deck.length < neededCards) {
      throw Exception('Not enough cards in deck to deal.');
    }

    for (final entry in gameState.playersInfo.entries) {
      final dealtCards = gameState.deck.sublist(0, cardsPerPlayer);
      gameState.deck.removeRange(0, cardsPerPlayer);
      gameState.hands[entry.key] = List.of(dealtCards);

      gameState.cardMoveEvents.addAll(
        EventHandler.generateDealToHandEvent(dealtCards, entry.key, pid),
      );
    }

    final tableCards = gameState.deck.sublist(0, cardsInPlayingArea);
    gameState.deck.removeRange(0, cardsInPlayingArea);
    for (final c in tableCards) {
      gameState.placeCardOnTable(c);
    }

    gameState.cardMoveEvents.addAll(
      EventHandler.generateDealToTableEvent(tableCards, pid),
    );
    return gameState;
  }

  static InGameAction getInGameAction(GameState gameState, String pid) {
    switch (gameState.gameStatus) {
      case GameStatus.waitingForPlayers:
        return InGameAction.share;

      case GameStatus.readyToStart:
        return gameState.controllerId == pid
            ? InGameAction.start
            : InGameAction.waiting;

      case GameStatus.inProgress:
        switch (gameState.round.roundStatus) {
          case RoundStatus.completed:
            return gameState.controllerId == pid
                ? InGameAction.shuffle
                : InGameAction.waiting;

          // case RoundStatus.dealing:
          //   return gameState.controllerId == pid
          //       ? InGameAction.deal
          //       : InGameAction.waiting;

          case RoundStatus.readyToDeal:
            return gameState.controllerId == pid
                ? InGameAction.deal
                : InGameAction.waiting;

          case RoundStatus.playing:
            // dealSame is Casino-only; Tres y Dos reshuffles via its state handler.
            if (GameRegistry.isCasinoFamily(gameState.gameMode) &&
                CasinoGameStateHandler.shouldDealSameRound(gameState)) {
              return gameState.controllerId == pid
                  ? InGameAction.dealSame
                  : InGameAction.waiting;
            }
            return InGameAction.noAction;
        }

      case GameStatus.gameOver:
        return InGameAction.exit;
      default:
        return InGameAction.noAction;
    }
  }

  static GameState shuffleAction(
    GameState gameState,
    String pid, {
    List<PlayingCardModel>? cards,
  }) {
    if (cards != null) {
      gameState.deck = Deck.shuffle(cards);
    } else {
      gameState.deck = Deck.shuffle(Deck.standard());
    }

    gameState.playingArea.clear();
    gameState.playingAreaStacks.clear();
    gameState.tableOrder.clear();

    gameState.hands.clear();

    for (final playerId in gameState.playersInfo.keys) {
      gameState.hands[playerId] = [];
      gameState.playersDeck[playerId] = [];
    }

    gameState.extraPoints = 0;
    gameState.extraPointsHolderId = '';
    gameState.lastTookCardId = '';
    gameState.lastTakes.clear();
    gameState.cardMoveEvents = [];
    gameState.settlementEvents = [];
    gameState.clearRoundCoinAccrual();

    gameState.currentTurnPlayerId = '';
    gameState.controllerId = pid;

    gameState.round.roundStatus = RoundStatus.readyToDeal;
    gameState.round.nextAcknowledged = false;

    return gameState;
  }

  static String getNextPlayerId(GameState gameState, String pid) {
    final players = gameState.playersInfo.keys.toList();

    players.sort((a, b) => a.compareTo(b));

    if (players.isEmpty) return "";

    final index = players.indexOf(pid);
    if (index == -1) return players.first;

    final nextIndex = (index + 1) % players.length;
    return players[nextIndex];
  }

  static String getNextControllerId(GameState gameState) {
    final players = (gameState.playersInfo.keys).toList();

    if (players.isEmpty) return '';

    final currentIndex = players.indexOf(gameState.controllerId);

    if (currentIndex == -1) {
      return players.first;
    }

    final nextIndex = (currentIndex + 1) % players.length;
    return players[nextIndex];
  }
}
