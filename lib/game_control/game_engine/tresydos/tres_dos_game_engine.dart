import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/general_handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/general_handlers/game_action_handler.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/tresydos/handlers/tres_dos_play_action_handler.dart';
import 'package:dominican_casino/game_control/game_engine/tresydos/handlers/tres_dos_game_state_handler.dart';
import 'package:dominican_casino/game_control/game_engine/tresydos/handlers/tres_dos_rules_handler.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';

class TresDosGameEngine extends GameEngine {
  @override
  List<PlayAction> getAvailableActions(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    return TresDosRulesHandler.getAvailableActions(
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

    gameState = TresDosPlayActionHandler.handleAction(
      gameState,
      action,
      currentCardSelection,
    );

    if (gameState.hands[action.performedById]?.length == 5) {
      gameState.currentTurnPlayerId = GameActionHandler.getNextPlayerId(
        gameState,
        action.performedById,
      );
    }
    final cardMoveEvents = EventHandler.handlegenerateEvents(gameState, action);
    gameState.cardMoveEvents = cardMoveEvents;
    gameState.settlementEvents = [];

    if (TresDosGameStateHandler.roundEnded(gameState, action.performedById)) {
      developer.log("round ended");
      gameState = TresDosGameStateHandler.handleRoundEnded(
        gameState,
        action.performedById,
      );
    }
    if (TresDosGameStateHandler.shouldDealSameRound(gameState)) {
      TresDosGameStateHandler.handleShuffleRound(gameState);
    }
    return gameState;
  }

  @override
  ValidateResult validateAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
    PlayAction action,
  ) {
    return TresDosRulesHandler.validateAction(
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
    developer.log("performing in game action: $action");
    final counts = GameRegistry.dealCounts(GameMode.tresydos);
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
