import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/general_handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/general_handlers/game_action_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/casino_game_state_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/casino_rules_handler.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/casino_play_action_handler.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';

class CasinoGameEngine extends GameEngine {
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
  GameState performPlayAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
    PlayAction action,
  ) {
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

    gameState = CasinoPlayActionHandler.handleAction(
      gameState,
      action,
      currentCardSelection,
    );

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
    final cardMoveEvents = EventHandler.handlegenerateEvents(gameState, action);
    gameState.cardMoveEvents = cardMoveEvents;
    gameState.settlementEvents = [];

    if (CasinoGameStateHandler.roundEnded(gameState)) {
      developer.log("round ended");
      // Leftover collect is a separate animation phase from the play/capture.
      final settlementEvents = EventHandler.generateSettleEndRoundEvents(
        gameState,
      );
      gameState = CasinoGameStateHandler.settleEndOfRoundIfNeeded(gameState);
      gameState.settlementEvents = settlementEvents;
      gameState = CasinoGameStateHandler.handleRoundEnded(gameState);
    }

    return gameState;
  }

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
    return GameActionHandler.getInGameAction(gameState, pid);
  }

  @override
  GameState performInGameAction(
    GameState state,
    InGameAction action,
    String pid,
  ) {
    final counts = GameRegistry.dealCounts(GameMode.casino);
    return GameActionHandler.handleGameAction(
      state,
      action,
      counts.$1,
      counts.$2,
      counts.$3,
      counts.$4,
      pid,
    );
  }
}
