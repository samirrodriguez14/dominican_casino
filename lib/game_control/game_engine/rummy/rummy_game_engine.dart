import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/general_handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/general_handlers/game_action_handler.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/handlers/rummy_game_state_handler.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/handlers/rummy_play_action_handler.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/handlers/rummy_rules_handler.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';

class RummyGameEngine extends GameEngine {
  @override
  List<PlayAction> getAvailableActions(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    return RummyRulesHandler.getAvailableActions(
      gameState,
      currentCardSelection,
    );
  }

  @override
  GameState performPlayAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
    PlayAction action,
  ) {
    final result = validateAction(
      gameState,
      currentCardSelection,
      action,
    );
    if (!result.result) {
      throw Exception("Invalid Move: ${result.reason}");
    }
    if (!_validateTurn(gameState, action)) {
      throw Exception("Not your turn");
    }

    gameState = RummyPlayActionHandler.handleAction(
      gameState,
      action,
      currentCardSelection,
    );

    // Turn advances when the player returns to 7 cards after discarding.
    if (gameState.hands[action.performedById]?.length == 7) {
      gameState.setTurn(
        GameActionHandler.getNextPlayerId(gameState, action.performedById),
      );
    }

    final cardMoveEvents = EventHandler.handlegenerateEvents(gameState, action);
    gameState.cardMoveEvents = cardMoveEvents;
    gameState.settlementEvents = [];

    if (RummyGameStateHandler.roundEnded(gameState, action.performedById)) {
      developer.log('rummy round ended');
      gameState = RummyGameStateHandler.handleRoundEnded(
        gameState,
        action.performedById,
      );
      gameState.refreshTurnClock(restart: false);
      return gameState;
    }

    if (RummyGameStateHandler.shouldReshuffle(gameState)) {
      RummyGameStateHandler.handleShuffleRound(gameState);
    }

    gameState.refreshTurnClock(restart: false);
    return gameState;
  }

  bool _validateTurn(GameState gameState, PlayAction action) {
    return (gameState.currentTurnPlayerId == action.performedById);
  }

  @override
  ValidateResult validateAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
    PlayAction action,
  ) {
    return RummyRulesHandler.validateAction(
      gameState,
      currentCardSelection,
      action,
    );
  }

  @override
  InGameAction getInGameAction(GameState gameState, String pid) {
    return GameActionHandler.getInGameAction(gameState, pid);
  }

  @override
  GameState performInGameAction(
    GameState state,
    InGameAction action,
    String pid,
  ) {
    developer.log('rummy performInGameAction: $action');

    final counts = GameRegistry.dealCounts(GameMode.rummy);
    final next = GameActionHandler.handleGameAction(
      state,
      action,
      counts.$1,
      counts.$2,
      counts.$3,
      counts.$4,
      pid,
    );

    if (action == InGameAction.deal) {
      RummyGameStateHandler.assignContractForDeal(next);
    } else if (action == InGameAction.start || action == InGameAction.shuffle) {
      next.rummyState = null;
    }

    return next;
  }
}

