import 'package:dominican_casino/game_control/game_engine/casino/handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/game_state_handler.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/services/game_service.dart';

class CasinoPlayActionHandler {
  static Future<GameState> handlePlayCardAction(
    GameState nextState,
    GameService gameService,
    PlayCardAction a,
  ) async {
    String pid = a.performedById;
    //MOVE TO GAMESTATE HANDLER
    //REMOVE CARD FROM PLAYER HAND
    nextState.hands[pid]?.removeWhere((card) => card == a.usedCard);
    //ADD CARD TO PLAYING AREA
    nextState.playingArea.add(a.usedCard);
    //SET NEXT PLAYER TURN
    nextState.currentTurnPlayerId = GameStateHandler.getNextPlayerId(
      nextState,
      pid,
    );
    ///HANDLE MOVEEVENTS
    final cardMoveEvents = EventHandler.generatePlayEvents(a);
    nextState.cardMoveEvents = cardMoveEvents;

    //SEND CHANGES
    nextState = await gameService.updateGame(nextState);
    return nextState;
  }

  static Future<GameState> handleTakeCardAction(
    GameState g,
    PlayAction a,
  ) async {
    throw UnimplementedError();
  }

  static Future<GameState> handleAddCardsAction(
    GameState g,
    PlayAction a,
  ) async {
    throw UnimplementedError();
  }

  static Future<GameState> handlePairCardsAction(
    GameState g,
    PlayAction a,
  ) async {
    throw UnimplementedError();
  }
}
