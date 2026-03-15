import 'package:dominican_casino/game_control/game_engine/casino/handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/game_state_handler.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
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
        gameService.updateGame(gameState);

      case InGameAction.share:
      case InGameAction.deal:
        //INITIAL DEAL
        final newGameState = _dealCardsAction(gameState, pid);
        newGameState.currentTurnPlayerId = GameStateHandler.getNextPlayerId(
          gameState,
          pid,
        );
        await gameService.updateGame(newGameState);
        break;
      case InGameAction.dealSame:
        final newGameState = _dealSameAction(gameState, pid);
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
    // bool allReady = false;
    // for (var entry in gameState.roundReady.entries) {
    //   allReady = entry.value;
    // }
    int maxPlayers = 2;
    List<bool> handsEmptyVals = [];
    for (var entry in gameState.hands.entries) {
      handsEmptyVals.add(entry.value.isEmpty);
    }
    bool handsEmpty = handsEmptyVals.every((v) => v);

    List<bool> allJoinedVals = [];
    if (gameState.playersInfo != null) {
      for (var entry in gameState.playersInfo!.entries) {
        allJoinedVals.add(entry.key != "");
      }
    }
    bool allJoined =
        allJoinedVals.length >= maxPlayers && allJoinedVals.every((v) => v);
    if (!gameState.started) {
      if (allJoined && gameState.controllerId == pid) {
        return InGameAction.start;
      }
      if (allJoined) {
        return InGameAction.waiting;
      }
      if (!allJoined) {
        return InGameAction.share;
      }
    }
    if (gameState.started) {
      if (handsEmpty) {
        if (gameState.controllerId == pid) {
          if (gameState.deck.length == 12) {
            //DEAL NEW HAND
            return InGameAction.deal;
          }
          if (gameState.deck.length < 12 && gameState.deck.isNotEmpty) {
            //DEAl SAME HAND
            return InGameAction.dealSame;
          }
        }
        if (gameState.roundReady[pid] != null && !gameState.roundReady[pid]!) {
          //SET STATUS READY
          return InGameAction.setReady;
        }
        return InGameAction.waiting;
      }
      if (!handsEmpty) {
        return InGameAction.noAction;
      }
    }
    return InGameAction.noAction;
  }
}
