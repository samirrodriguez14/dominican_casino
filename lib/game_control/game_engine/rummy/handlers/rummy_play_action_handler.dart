import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';

class RummyPlayActionHandler {
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
        return nextState;
    }
  }

  static GameState handlePlayCardAction(
    GameState nextState,
    PlayCardAction a,
  ) {
    final pid = a.performedById;

    // Move discarded card from hand to the discard pile (playingArea).
    nextState.hands[pid]?.removeWhere((card) => card.id == a.usedCard.id);
    nextState.playingArea.add(a.usedCard);

    // If the discarded card was boxed, remove it from the overlay so the
    // overlay matches the player's remaining 7-card hand.
    final rummy = nextState.rummyState;
    if (rummy != null) {
      rummy.boxAByPid[pid]?.removeWhere((id) => id == a.usedCard.id);
      rummy.boxBByPid[pid]?.removeWhere((id) => id == a.usedCard.id);
    }

    return nextState;
  }

  static GameState handleTakeCardAction(
    GameState nextState,
    TakeCardAction a,
  ) {
    final pid = a.performedById;
    // Remove the taken card from either the discard pile or the deck.
    nextState.playingArea.removeWhere((card) => card.id == a.targetCard.id);
    nextState.deck.removeWhere((card) => card.id == a.targetCard.id);

    nextState.hands.putIfAbsent(pid, () => []);
    nextState.hands[pid]!.add(a.targetCard);
    return nextState;
  }
}

