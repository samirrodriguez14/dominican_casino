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
  GameState nextState,
  GameService gameService,
  TakeCardAction a,
) async {
  final pid = a.performedById;

  // REMOVE USED CARD FROM PLAYER HAND
  nextState.hands[pid]?.removeWhere((card) => card == a.usedCard);

  // REMOVE TARGET CARD FROM PLAYING AREA
  nextState.playingArea.removeWhere((card) => card == a.targetCard);

  // ADD BOTH CARDS TO PLAYER'S WON/CAPTURED CARDS
  nextState.playersDeck.putIfAbsent(pid, () => []);
  nextState.playersDeck[pid]!.addAll([
    a.usedCard,
    a.targetCard,
  ]);

  // SET NEXT PLAYER TURN
  nextState.currentTurnPlayerId = GameStateHandler.getNextPlayerId(
    nextState,
    pid,
  );

  // HANDLE MOVE EVENTS
  nextState.cardMoveEvents = EventHandler.generateTakeCardEvents(a);

  // SEND CHANGES
  nextState = await gameService.updateGame(nextState);
  return nextState;
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
