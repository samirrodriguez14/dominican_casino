import 'package:dominican_casino/game_control/game_engine/casino/handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/game_state_handler.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/services/game_service.dart';

class CasinoGameActionHandler {
  static Future<void> handleGameAction(
    GameService gameService,
    GameState gameState,
    InGameAction inGameAction,
    String pid,
  ) async {
    //Clean cardMove events to send in new Update
    gameState.cardMoveEvents = [];
    switch (inGameAction) {
      case InGameAction.start:
        gameState.started = true;
        gameState.gameStatus = GameStatus.inProgress;
        gameState.round.roundStatus = RoundStatus.dealing;
        await gameService.updateGame(gameState);

      case InGameAction.share:
      case InGameAction.deal:
        //INITIAL DEAL
        final newGameState = _dealCardsAction(gameState, pid);
        newGameState.round.roundStatus = RoundStatus.playing;
        newGameState.currentTurnPlayerId = GameStateHandler.getNextPlayerId(
          gameState,
          pid,
        );
        await gameService.updateGame(newGameState);
        break;
      case InGameAction.dealSame:
        final newGameState = _dealSameAction(gameState, pid);
        newGameState.round.roundStatus = RoundStatus.playing;
        await gameService.updateGame(newGameState);
        break;
      default:
        return;
    }
  }

  static GameState _dealSameAction(GameState gameState, String pid) {
    final playerCount = gameState.playersInfo?.length ?? 0;
    final neededCards = (playerCount * 4);
    if (gameState.deck.length < neededCards) {
      throw Exception('Not enough cards in deck to deal.');
    }
    for (final entry in gameState.playersInfo!.entries) {
      final dealtCards = gameState.deck.sublist(0, 4);
      gameState.deck.removeRange(0, 4);
      gameState.hands[entry.key] = List.of(dealtCards);

      gameState.cardMoveEvents.addAll(
        EventHandler.generateDealToHandEvent(dealtCards, entry.key, pid),
      );
    }
    return gameState;
  }

  static GameState _dealCardsAction(GameState gameState, String pid) {
    final playerCount = gameState.playersInfo?.length ?? 0;
    final neededCards = (playerCount * 4) + 4;

    if (gameState.deck.length < neededCards) {
      throw Exception('Not enough cards in deck to deal.');
    }

    for (final entry in gameState.playersInfo!.entries) {
      final dealtCards = gameState.deck.sublist(0, 4);
      gameState.deck.removeRange(0, 4);
      gameState.hands[entry.key] = List.of(dealtCards);

      gameState.cardMoveEvents.addAll(
        EventHandler.generateDealToHandEvent(dealtCards, entry.key, pid),
      );
    }

    final tableCards = gameState.deck.sublist(0, 4);
    gameState.deck.removeRange(0, 4);
    gameState.playingArea.addAll(tableCards);

    gameState.cardMoveEvents.addAll(
      EventHandler.generateDealToTableEvent(tableCards, pid),
    );
    return gameState;
  }

  static InGameAction getInGameAction(GameState gameState, String pid) {
    switch (gameState.gameStatus) {
      case GameStatus.waitingForPlayers:
        return InGameAction.share; //For now... I'll change it to waiting...

      case GameStatus.readyToStart:
        if (gameState.controllerId == pid) {
          return InGameAction.start;
        } else {
          return InGameAction.waiting;
        }

      case GameStatus.inProgress:
        //While game is running
        switch (gameState.round.roundStatus) {
          //If in the middle of the round...
          case RoundStatus.dealing:
            if (gameState.controllerId == pid) {
              return InGameAction.dealSame;
            } else {
              return InGameAction.waiting;
            }
          //If playing.. no action
          case RoundStatus.playing:
            return InGameAction.noAction;
          //If completed.. new deal
          case RoundStatus.completed:
            if (gameState.controllerId == pid) {
              return InGameAction.deal;
            } else {
              return InGameAction.waiting;
            }
        }
      case GameStatus.gameOver:
        return InGameAction.noAction;
      // case GameStatus.error:
      //   return InGameAction.noAction;
      //handled by default...
      default:
        return InGameAction.noAction;
    }
  }
}
