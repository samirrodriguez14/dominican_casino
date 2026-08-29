import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/bs/bs_handlers.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/general_handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/general_handlers/game_action_handler.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';

class BsGameEngine extends GameEngine {
  @override
  List<PlayAction> getAvailableActions(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    return BsRulesHandler.getAvailableActions(
      gameState,
      currentCardSelection,
    );
  }

  @override
  ValidateResult validateAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
    PlayAction action,
  ) {
    if (action is ClaimPlayAction) {
      return BsRulesHandler.validateClaimPlay(
        gameState,
        currentCardSelection,
        action,
      );
    }
    return ValidateResult.failure('Unsupported play action');
  }

  @override
  GameState performPlayAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
    PlayAction action,
  ) {
    final result = validateAction(gameState, currentCardSelection, action);
    if (!result.result) {
      throw Exception('Invalid Move: ${result.reason}');
    }
    if (gameState.currentTurnPlayerId != action.performedById) {
      throw Exception('Not your turn');
    }
    if (action is! ClaimPlayAction) {
      throw Exception('Unsupported play action');
    }

    gameState = BsPlayActionHandler.handleClaimPlay(gameState, action);
    gameState.cardMoveEvents = EventHandler.generateClaimPlayEvents(action);
    gameState.settlementEvents = [];
    gameState.refreshTurnClock(restart: false);
    return gameState;
  }

  @override
  List<OutOfTurnAction> getOutOfTurnActions(GameState state, String pid) {
    return BsRulesHandler.getOutOfTurnActions(state, pid);
  }

  @override
  ValidateResult validateOutOfTurn(GameState state, OutOfTurnAction action) {
    return BsRulesHandler.validateOutOfTurn(state, action);
  }

  @override
  GameState performOutOfTurnAction(GameState state, OutOfTurnAction action) {
    final result = validateOutOfTurn(state, action);
    if (!result.result) {
      throw Exception('Invalid Move: ${result.reason}');
    }

    if (action is CallBluffAction) {
      return BsOutOfTurnHandler.handleCallBluff(state, action);
    }
    if (action is AcceptClaimAction) {
      return BsOutOfTurnHandler.handleAcceptClaim(state, action);
    }
    throw Exception('Unsupported out-of-turn action');
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
    developer.log('bs performInGameAction: $action');

    if (action == InGameAction.deal) {
      state.cardMoveEvents = [];
      state.settlementEvents = [];
      return BsGameStateHandler.dealAll(state, pid);
    }

    if (action == InGameAction.start || action == InGameAction.shuffle) {
      final next = GameActionHandler.handleGameAction(
        state,
        action,
        0,
        0,
        0,
        0,
        pid,
      );
      next.bsState = null;
      // Stage the full shoe on the center pile so shuffle lands there and
      // deal flights leave from a visible discard stack.
      BsGameStateHandler.stageShoeOnTable(next);
      return next;
    }

    return GameActionHandler.handleGameAction(state, action, 0, 0, 0, 0, pid);
  }
}
