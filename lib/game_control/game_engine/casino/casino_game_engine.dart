import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/general_handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/general_handlers/game_action_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/game_state_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/rules_handler.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/play_action_handler.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';

class CasinoGameEngine extends GameEngine {
  //Orchestrator
  CasinoGameEngine({required super.gameService});

  //DONE FOR NOW!!!
  @override
  List<PlayAction> getAvailableActions(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    return CasinoRulesHandler.getAvailableActions(
      gameState,
      currentCardSelection,
    );
  }

  ///PERFORM ACTION AND HANDLE END GAME
  @override
  Future<GameState> performPlayAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
    PlayAction action,
  ) async {
    ValidateResult result = validateAction(
      gameState,
      currentCardSelection,
      action,
    );
    if (!result.result) {
      throw Exception("Invalid Move: ${result.reason}");
    }
    if (!validateTurn(gameState, action)) {
      throw Exception("Not your turn");
    }

    // HANDLE ACTION
    gameState = CasinoPlayActionHandler.handleAction(
      gameState,
      action,
      currentCardSelection,
    );

    // NEXT PLAYER TURN
    if (currentCardSelection.selectedCard != null) {
      gameState.currentTurnPlayerId = GameActionHandler.getNextPlayerId(
        gameState,
        action.performedById,
      );
    }
    gameState = CasinoGameStateHandler.handleExtraPoints(
      gameState,
      action.performedById,
    );
    // MOVE EVENTS
    final cardMoveEvents = EventHandler.handlegenerateEvents(gameState, action);
    gameState.cardMoveEvents = cardMoveEvents;
    // SAVE NORMAL MOVE
    gameState = await gameService.updateGame(gameState);
    // // ROUND END
    if (CasinoGameStateHandler.roundEnded(gameState)) {
      developer.log("round ended");
      gameState = CasinoGameStateHandler.settleEndOfRoundIfNeeded(gameState);
      final settlementEvents = EventHandler.generateSettleEndRoundEvents(
        gameState,
      );
      gameState.cardMoveEvents.addAll(settlementEvents);
      gameState = CasinoGameStateHandler.handleRoundEnded(gameState);
      gameState = await gameService.updateGame(gameState);
    }

    return gameState;
  }

  //FORWARD TO VALIDATE ACTION [GAME RULE HANDLER]
  @override
  ValidateResult validateAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
    PlayAction action,
  ) {
    return CasinoRulesHandler.validateAction(
      gameState,
      currentCardSelection,
      action,
    );
  }

  bool validateTurn(GameState gameState, PlayAction action) {
    return (gameState.currentTurnPlayerId == action.performedById);
  }

  @override
  InGameAction getInGameAction(GameState gameState, String pid) {
    int maxPlayers = 2;
    List<bool> allJoinedVals = [];
    for (var entry in gameState.playersInfo.entries) {
      allJoinedVals.add(entry.key != "");
    }
    bool allJoined =
        allJoinedVals.length >= maxPlayers && allJoinedVals.every((v) => v);
    if (allJoined &&
        gameState.gameStatus != GameStatus.inProgress &&
        gameState.gameStatus != GameStatus.gameOver) {
      gameState.gameStatus = GameStatus.readyToStart;
      gameService.updateGame(gameState);
    }
    return GameActionHandler.getInGameAction(gameState, pid);
  }

  @override
  Future<GameState> performInGameAction(
    GameState state,
    InGameAction action,
    String pid,
  ) async {
    await GameActionHandler.handleGameAction(
      gameService,
      state,
      action,
      4,
      4,
      4,
      0,
      pid,
    );
    return state;
  }
}
