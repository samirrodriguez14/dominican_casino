import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/casino/handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/game_action_handler.dart';
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

  @override
  Future<GameState> performPlayAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
    PlayAction action,
  ) async {
    if (!validateAction(gameState, currentCardSelection, action)) {
      throw Exception("Invalid Move");
    }
    if (!validateTurn(gameState, action)) {
      throw Exception("Not your turn");
    }

    ///HANDLE ACTION [CasinoPlayActionHandler]
    ///DONE!!!! FOR NOW
    gameState = CasinoPlayActionHandler.handleAction(
      gameState,
      action,
      currentCardSelection,
    );

    //HANDLE NEXT ROUND [GameStateHandler]
    developer.log("Checking if round ended");

    if (GameStateHandler.roundEnded(gameState)) {
      developer.log("round ended");

      gameState = GameStateHandler.handleRoundEnded(gameState);
    }

    //HANDLE NEXT PLAYER [GameStateHandler]
    //SET NEXT PLAYER TURN only a handccard was used
    //WORKS FOR NOW
    if (currentCardSelection.selectedCard != null) {
      gameState.currentTurnPlayerId = GameStateHandler.getNextPlayerId(
        gameState,
        action.performedById,
      );
    }

    //HANDLE EVENTS [EventStateHandler]
    ///HANDLE MOVE EVENTS
    final cardMoveEvents = EventHandler.handlegenerateEvents(gameState, action);

    gameState.cardMoveEvents = cardMoveEvents;
    //SEND CHANGES
    final nextgameState = await gameService.updateGame(gameState);
    return nextgameState;
  }

  //FORWARD TO VALIDATE ACTION [GAME RULE HANDLER]
  @override
  bool validateAction(
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
    return CasinoGameActionHandler.getInGameAction(gameState, pid);
  }

  @override
  Future<GameState> performInGameAction(
    GameState state,
    InGameAction action,
    String pid,
  ) async {
    await CasinoGameActionHandler.handleGameAction(
      gameService,
      state,
      action,
      pid,
    );
    return state;
  }
}
