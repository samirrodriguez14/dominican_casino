import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';

class TresDosRulesHandler {
  ///GET ALL AVAILABLE ACTIONS BASED ON CARD SELECTION AND GAME STATE
  static List<PlayAction> getAvailableActions(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    List<PlayAction> available = [];
    String performedBy = currentCardSelection.pid;

    if (canPlayAction(gameState, currentCardSelection)) {
      available.add(
        PlayCardAction(
          usedCard: currentCardSelection.selectedCard!,
          performedById: performedBy,
        ),
      );
    }

    if (canTakeCard(gameState, currentCardSelection)) {
      available.add(
        TakeCardAction(
          usedCard: currentCardSelection.selectedCards[0],
          targetCard: currentCardSelection.selectedCards[0],
          performedById: performedBy,
        ),
      );
    }

    return available;
  }

  ///VALIDATE ACTION BASED ON CARD SELECTION AND GAMESTATE
  static bool validateAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
    PlayAction action,
  ) {
    switch (action) {
      case PlayCardAction _:
        return canPlayAction(gameState, currentCardSelection);

      case TakeCardAction _:
        return canTakeCard(gameState, currentCardSelection);

      default:
    }
    return false;
  }

  ///VALIDATE SPECIFIC ACTION BASED ON CARD SELECTION AND GAMESTATE
  static bool canPlayAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    if (currentCardSelection.selectedCards.isEmpty &&
        currentCardSelection.selectedStacks.isEmpty) {
      return gameState.hands[currentCardSelection.pid]?.length == 6 &&
          currentCardSelection.selectedCard != null;
    }
    return false;
  }

  static bool canTakeCard(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final selectedCard = currentCardSelection.selectedCard;
    final selectedCards = currentCardSelection.selectedCards;
    final pid = currentCardSelection.pid;

    // Must be this player's turn
    if (gameState.currentTurnPlayerId != pid) {
      return false;
    }

    // Must not have a card from hand selected
    if (selectedCard != null) {
      return false;
    }

    // Must select exactly one table card
    return selectedCards.length == 1 && gameState.hands[pid]?.length != 6;
  }
}
