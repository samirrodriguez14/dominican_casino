import 'package:dominican_casino/game_control/game_engine/casino/handlers/game_action_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/rules_handler.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/play_action_handler.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';

class CasinoGameEngine extends GameEngine {
  //Orchestrator
  CasinoGameEngine({required super.gameService});

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
    gameState = CasinoPlayActionHandler.handleAction(
      gameState,
      action,
      currentCardSelection,
    );
    //SEND CHANGES
    final nextgameState = await gameService.updateGame(gameState);
    return nextgameState;
  }

  //FORWARD TO VALIDATE ACTION ON GAME RULE
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
