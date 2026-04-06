import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';

class TresDosPlayActionHandler {
  static GameState handleAction(
    GameState nextState,
    PlayAction a,
    CurrentCardSelection selection,
  ) {
    switch (a) {
      case PlayCardAction a:
        return handlePlayCardAction(nextState, a);
      case TakeCardAction a:
        return handleTakeCardAction(nextState, a);
      default:
        () => {};
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
    return nextState;
  }

  static GameState handleTakeCardAction(GameState nextState, TakeCardAction a) {
    final pid = a.performedById;
    // REMOVE TARGET CARD FROM PLAYING AREA
    nextState.playingArea.removeWhere((card) => card == a.targetCard);
    nextState.deck.removeWhere((card) => card == a.targetCard);

    // ADD CARD TO PLAYER'S WON/CAPTURED CARDS
    nextState.hands.putIfAbsent(pid, () => []);
    nextState.hands[pid]!.add(a.targetCard);

    return nextState;
  }
}
