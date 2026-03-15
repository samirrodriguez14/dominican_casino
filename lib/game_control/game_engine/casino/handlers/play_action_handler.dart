import 'package:dominican_casino/game_control/game_engine/casino/handlers/event_handler.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/game_state_handler.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';

class CasinoPlayActionHandler {
  static GameState handleAction(
    GameState nextState,
    PlayAction a,
    CurrentCardSelection selection,
  ) {
    switch (a) {
      case PlayCardAction a:
        return CasinoPlayActionHandler.handlePlayCardAction(nextState, a);
      case TakeCardAction a:
        return CasinoPlayActionHandler.handleTakeCardAction(nextState, a);
      case AddCardsAction a:
        return CasinoPlayActionHandler.handleAddCardsAction(nextState, a);
      case PairCardsAction a:
        return CasinoPlayActionHandler.handlePairCardsAction(nextState, a);
    }
    return nextState;
  }

  static GameState handlePlayCardAction(GameState nextState, PlayCardAction a) {
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
    return nextState;
  }

  static GameState handleTakeCardAction(GameState nextState, TakeCardAction a) {
    final pid = a.performedById;

    // REMOVE USED CARD FROM PLAYER HAND
    nextState.hands[pid]?.removeWhere((card) => card == a.usedCard);

    // REMOVE TARGET CARD FROM PLAYING AREA
    nextState.playingArea.removeWhere((card) => card == a.targetCard);

    // ADD BOTH CARDS TO PLAYER'S WON/CAPTURED CARDS
    nextState.playersDeck.putIfAbsent(pid, () => []);
    nextState.playersDeck[pid]!.addAll([a.usedCard, a.targetCard]);

    // SET NEXT PLAYER TURN
    nextState.currentTurnPlayerId = GameStateHandler.getNextPlayerId(
      nextState,
      pid,
    );

    // HANDLE MOVE EVENTS
    nextState.cardMoveEvents = EventHandler.generateTakeCardEvents(a);

    return nextState;
  }

  static GameState handleAddCardsAction(GameState g, PlayAction a) {
    throw UnimplementedError();
  }

  static GameState handlePairCardsAction(GameState g, PlayAction a) {
    throw UnimplementedError();
  }
}
