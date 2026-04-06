import 'package:dominican_casino/game_control/game_engine/general_handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/game_state_handler.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/services/game_service.dart';

class GameActionHandler {
  static Future<void> handleGameAction(
    GameService gameService,
    GameState gameState,
    InGameAction inGameAction,
    String pid,
  ) async {
    gameState.cardMoveEvents = [];

    switch (inGameAction) {
      case InGameAction.start:
        gameState.started = true;
        gameState.gameStatus = GameStatus.inProgress;
        gameState.round.roundStatus = RoundStatus.readyToDeal;
        await gameService.updateGame(gameState);
        return;

      case InGameAction.shuffle:
        final newGameState = CasinoGameStateHandler.shuffleAction(gameState, pid);
        await gameService.updateGame(newGameState);
        return;

      case InGameAction.share:
      case InGameAction.deal:
        final newGameState = _dealCardsAction(gameState, pid);
        newGameState.round.roundStatus = RoundStatus.playing;
        newGameState.currentTurnPlayerId = CasinoGameStateHandler.getNextPlayerId(
          newGameState,
          pid,
        );
        await gameService.updateGame(newGameState);
        return;

      case InGameAction.dealSame:
        final newGameState = dealSameAction(gameState, pid);
        newGameState.round.roundStatus = RoundStatus.playing;
        newGameState.currentTurnPlayerId = CasinoGameStateHandler.getNextPlayerId(
          newGameState,
          pid,
        );
        await gameService.updateGame(newGameState);
        return;

      default:
        return;
    }
  }

  static GameState dealSameAction(GameState gameState, String pid) {
    final playerCount = gameState.playersInfo.length;
    final neededCards = (playerCount * 4);
    if (gameState.deck.length < neededCards) {
      throw Exception('Not enough cards in deck to deal.');
    }
    for (final entry in gameState.playersInfo.entries) {
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
    final playerCount = gameState.playersInfo.length;
    final neededCards = (playerCount * 4) + 4;

    if (gameState.deck.length < neededCards) {
      throw Exception('Not enough cards in deck to deal.');
    }

    for (final entry in gameState.playersInfo.entries) {
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
            if (CasinoGameStateHandler.shouldDealSameRound(gameState)) {
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
}
