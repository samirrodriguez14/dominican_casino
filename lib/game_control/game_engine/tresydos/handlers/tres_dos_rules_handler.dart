import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/models/game_state.dart';

class TresDosRulesHandler {
  ///GET ALL AVAILABLE ACTIONS BASED ON CARD SELECTION AND GAME STATE
  static List<PlayAction> getAvailableActions(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    List<PlayAction> available = [];
    String performedBy = currentCardSelection.pid;

    if (canPlayAction(gameState, currentCardSelection).result) {
      available.add(
        PlayCardAction(
          usedCard: currentCardSelection.selectedCard!,
          performedById: performedBy,
        ),
      );
    }

    if (canTakeCard(gameState, currentCardSelection).result) {
      final card = currentCardSelection.selectedCards[0];
      final fromDeck = gameState.deck.any((c) => c.id == card.id);
      available.add(
        TakeCardAction(
          usedCard: card,
          targetCard: card,
          performedById: performedBy,
          fromZone: fromDeck ? ZoneType.gameDeck : ZoneType.table,
        ),
      );
    }

    return available;
  }

  ///VALIDATE ACTION BASED ON CARD SELECTION AND GAMESTATE
  static ValidateResult validateAction(
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
    return ValidateResult(reason: "", result: false);
  }

  ///VALIDATE SPECIFIC ACTION BASED ON CARD SELECTION AND GAMESTATE
  static ValidateResult canPlayAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    if (currentCardSelection.selectedCards.isEmpty &&
        currentCardSelection.selectedStacks.isEmpty) {
      return ValidateResult(
        reason: "",
        result:
            gameState.hands[currentCardSelection.pid]?.length == 6 &&
            currentCardSelection.selectedCard != null,
      );
    }
    return ValidateResult(reason: "reason", result: false);
  }

  static ValidateResult canTakeCard(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final selectedCard = currentCardSelection.selectedCard;
    final selectedCards = currentCardSelection.selectedCards;
    final pid = currentCardSelection.pid;

    // Must be this player's turn
    if (gameState.currentTurnPlayerId != pid) {
      return ValidateResult(reason: "Not your turn", result: false);
    }

    // Must not have a card from hand selected
    if (selectedCard != null) {
      return ValidateResult(
        reason: "Must Not Selected Card From hand",
        result: false,
      );
    }

    // Must select exactly one table card
    return ValidateResult(
      reason: "has table card",
      result: selectedCards.length == 1 && gameState.hands[pid]?.length != 6,
    );
  }


}
