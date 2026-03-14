import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';

class CasinoRulesHandler {
 
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
    if (canAddAction(gameState, currentCardSelection)) {
      available.add(
        AddCardsAction(
          usedCard: currentCardSelection.selectedCard!,
          targetCards: currentCardSelection.selectedCards,
          targetStacks: currentCardSelection.selectedStacks,
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
      case AddCardsAction _:
        return canAddAction(gameState, currentCardSelection);
      case AddTableCardsAction _:
        return canAddTableAction(gameState, currentCardSelection);
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
    if (currentCardSelection.selectedCard != null &&
        currentCardSelection.selectedCards.isEmpty &&
        currentCardSelection.selectedStacks.isEmpty) {
      return true;
    }
    return false;
  }

  static bool canAddAndPairAction() {
    return true;
  }

  static bool canAddAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    if (currentCardSelection.selectedCard != null) {
      return true;
    }
    return false;
  }

  static bool canAddTableAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    return true;
  }

  static bool canTakeCard(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    return true;
  }

  static bool canTakeStack() {
    return true;
  }


}
