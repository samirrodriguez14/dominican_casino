import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_requirement.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

class RummyRulesHandler {
  /// Deal-time win check is performed by the game state handler after a
  /// successful discard. This rules handler only validates and enumerates
  /// legal actions.
  static List<PlayAction> getAvailableActions(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final performedBy = currentCardSelection.pid;
    final available = <PlayAction>[];

    if (canPlayAction(gameState, currentCardSelection).result) {
      final card = currentCardSelection.selectedCard;
      if (card != null) {
        available.add(
          PlayCardAction(
            usedCard: card,
            performedById: performedBy,
          ),
        );
      }
    }

    if (canTakeCard(gameState, currentCardSelection).result) {
      final selected = currentCardSelection.selectedCards[0];
      final fromDeck = gameState.deck.any((c) => c.id == selected.id);
      available.add(
        TakeCardAction(
          usedCard: selected,
          targetCard: selected,
          performedById: performedBy,
          fromZone: fromDeck ? ZoneType.gameDeck : ZoneType.table,
        ),
      );
    }

    return available;
  }

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
        return ValidateResult.failure('Invalid action for Rummy');
    }
  }

  static ValidateResult canPlayAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final pid = currentCardSelection.pid;
    final selectedCard = currentCardSelection.selectedCard;
    final hand = gameState.hands[pid] ?? const <PlayingCardModel>[];

    if (gameState.currentTurnPlayerId != pid) {
      return ValidateResult.notTurn();
    }
    if (currentCardSelection.selectedCards.isNotEmpty ||
        currentCardSelection.selectedStacks.isNotEmpty) {
      return ValidateResult.invalidSelection(
        'When playing, select exactly one hand card',
      );
    }
    if (selectedCard == null) {
      return ValidateResult.noSelectedCard();
    }
    if (hand.length != 8) {
      return ValidateResult.failure('Must discard when hand has 8 cards');
    }
    if (!hand.any((c) => c.id == selectedCard.id)) {
      return ValidateResult.invalidSelection('Selected card not in hand');
    }

    return ValidateResult.success();
  }

  static ValidateResult canTakeCard(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final pid = currentCardSelection.pid;
    final selectedCard = currentCardSelection.selectedCard;
    final selectedCards = currentCardSelection.selectedCards;
    final hand = gameState.hands[pid] ?? const <PlayingCardModel>[];

    if (gameState.currentTurnPlayerId != pid) {
      return ValidateResult.notTurn();
    }
    if (selectedCard != null) {
      return ValidateResult.invalidSelection('Must not select a hand card');
    }
    if (selectedCards.length != 1) {
      return ValidateResult.invalidSelection('Must select exactly one card');
    }
    if (hand.length != 7) {
      return ValidateResult.failure('Must take when hand has 7 cards');
    }

    return ValidateResult.success();
  }
}

