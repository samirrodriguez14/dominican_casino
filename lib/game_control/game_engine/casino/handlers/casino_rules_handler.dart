import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

class CasinoRulesHandler {
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
    if (canAddAction(gameState, currentCardSelection).result) {
      available.add(
        AddCardsAction(
          usedCard: currentCardSelection.selectedCard!,
          targetCards: currentCardSelection.selectedCards,
          performedById: performedBy,
        ),
      );
    }
    if (canAddStackAction(gameState, currentCardSelection).result) {
      available.add(
        AddCardStackAction(
          usedCard: currentCardSelection.selectedCard!,
          targetStacks: currentCardSelection.selectedStacks,
          performedById: performedBy,
        ),
      );
    }
    if (canAddTableAction(gameState, currentCardSelection).result) {
      available.add(
        AddTableCardsAction(
          targetCards: currentCardSelection.selectedCards,
          performedById: performedBy,
        ),
      );
    }
    if (canTakeCard(gameState, currentCardSelection).result) {
      available.add(
        TakeCardAction(
          usedCard: currentCardSelection.selectedCard!,
          targetCard: currentCardSelection.selectedCards[0],
          performedById: performedBy,
        ),
      );
    }
    if (canTakeStack(gameState, currentCardSelection).result) {
      available.add(
        TakeStackAction(
          usedCard: currentCardSelection.selectedCard!,
          targetStack: currentCardSelection.selectedStacks[0],
          performedById: performedBy,
        ),
      );
    }
    if (canPairAllAction(gameState, currentCardSelection).result) {
      available.add(
        PairCardsAction(
          usedCard: currentCardSelection.selectedCard!,
          targetCards: currentCardSelection.selectedCards,
          targetStacks: currentCardSelection.selectedStacks,
          performedById: performedBy,
        ),
      );
    }
    if (canPairAllTableAction(gameState, currentCardSelection).result) {
      available.add(
        PairTableCardsAction(
          targetCards: currentCardSelection.selectedCards,
          targetStacks: currentCardSelection.selectedStacks,
          performedById: performedBy,
        ),
      );
    }
    if (canAddAndPairAction(gameState, currentCardSelection).result) {
      available.add(
        AddAndPairCardsAction(
          usedCard: currentCardSelection.selectedCard!,
          targetCards: currentCardSelection.selectedCards,
          targetStacks: currentCardSelection.selectedStacks,
          performedById: performedBy,
        ),
      );
    }
    if (canAddAndTakeAction(gameState, currentCardSelection).result) {
      available.add(
        AddAndTakeAction(
          usedCard: currentCardSelection.selectedCard!,
          targetCards: currentCardSelection.selectedCards,
          performedById: performedBy,
        ),
      );
    }
    if (canPairAndTakeAction(gameState, currentCardSelection).result) {
      available.add(
        PairAndTakeCardsAction(
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
  static ValidateResult validateAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
    PlayAction action,
  ) {
    switch (action) {
      case PlayCardAction _:
        return canPlayAction(gameState, currentCardSelection);
      case AddCardsAction _:
        return canAddAction(gameState, currentCardSelection);
      case AddCardStackAction _:
        return canAddStackAction(gameState, currentCardSelection);
      case AddTableCardsAction _:
        return canAddTableAction(gameState, currentCardSelection);
      case TakeCardAction _:
        return canTakeCard(gameState, currentCardSelection);
      case TakeStackAction _:
        return canTakeStack(gameState, currentCardSelection);
      case PairCardsAction _:
        return canPairAllAction(gameState, currentCardSelection);
      case PairTableCardsAction _:
        return canPairAllTableAction(gameState, currentCardSelection);
      case AddAndPairCardsAction _:
        return canAddAndPairAction(gameState, currentCardSelection);
      case AddAndTakeAction _:
        return canAddAndTakeAction(gameState, currentCardSelection);
      case PairAndTakeCardsAction _:
        return canPairAndTakeAction(gameState, currentCardSelection);
      default:
    }
    return ValidateResult(reason: "no valid action", result: false);
  }

  ///VALIDATE SPECIFIC ACTION BASED ON CARD SELECTION AND GAMESTATE
  static ValidateResult canPlayAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    if (currentCardSelection.selectedCard != null &&
        currentCardSelection.selectedCards.isEmpty &&
        currentCardSelection.selectedStacks.isEmpty) {
      return ValidateResult.success();
    }
    return ValidateResult.failure("Must select only one card from hand");
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
      return ValidateResult.notTurn();
    }

    // Must have a card from hand selected
    if (selectedCard == null) {
      return ValidateResult.noSelectedCard();
    }

    // Must select exactly one table card
    if (selectedCards.length != 1) {
      return ValidateResult.exactlyOneTable();
    }

    final targetCard = selectedCards.first;

    // Must actually be on table
    if (!gameState.playingArea.contains(targetCard)) {
      return ValidateResult.mustBeOnTable();
    }

    final cardVals = possibleCardValues(selectedCard);
    final totals = possibleTotals(selectedCards);

    return ValidateResult.canTake(cardVals.any(totals.contains));
  }

  static ValidateResult canTakeStack(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final selectedCard = currentCardSelection.selectedCard;
    final selectedStacks = currentCardSelection.selectedStacks;
    final pid = currentCardSelection.pid;

    if (gameState.currentTurnPlayerId != pid) {
      return ValidateResult.notTurn();
    }

    if (selectedCard == null) {
      return ValidateResult.noSelectedCard();
    }

    if (selectedStacks.length != 1) {
      return ValidateResult.exactlyOneTable();
    }

    final cardVals = possibleCardValues(selectedCard);
    final selectedStacksValue = selectedStacks[0].stackValue;

    return ValidateResult.canTakeStack(cardVals.contains(selectedStacksValue));
  }

  static ValidateResult canAddAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final selectedCard = currentCardSelection.selectedCard;
    final selectedCards = currentCardSelection.selectedCards;
    final pid = currentCardSelection.pid;
    final myHandCards = gameState.hands[pid] ?? [];
    if (selectedCard != null) {
      // values of the selectedCard (A => [1,14])
      final cardVals = possibleCardValues(selectedCard);
      // values in hand excluding selectedCard
      final handVals = possibleValuesInHand(myHandCards, selectedCard);
      // selectedCard + selectedCards(sum) must equal some other card in hand
      if (selectedCards.isNotEmpty) {
        final totals = possibleTotals(selectedCards);
        for (final cv in cardVals) {
          for (final t in totals) {
            final needed = cv + t;
            if (handVals.contains(needed)) return ValidateResult.success();
          }
        }
        return ValidateResult.failure(
          "Card sum does not match any card in hand",
        );
      }
    }
    return ValidateResult.failure("Invalid card selection for add action");
  }

  static ValidateResult canAddStackAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final selectedCard = currentCardSelection.selectedCard;
    final selectedCards = currentCardSelection.selectedCards;
    final selectedStacks = currentCardSelection.selectedStacks;
    final pid = currentCardSelection.pid;
    final myHandCards = gameState.hands[pid] ?? [];
    if (selectedCard != null) {
      // values of the selectedCard (A => [1,14])
      final cardVals = possibleCardValues(selectedCard);
      // values in hand excluding selectedCard
      final handVals = possibleValuesInHand(myHandCards, selectedCard);
      // selectedCard + selectedCards(sum) must equal some other card in hand
      if (selectedCards.isEmpty && selectedStacks.length == 1 && !selectedStacks[0].paired) {
        for (final cv in cardVals) {
          final needed = cv + selectedStacks[0].stackValue;
          if (handVals.contains(needed)) return ValidateResult.success();
        }
        return ValidateResult.failure(
          "Card sum does not match any card in hand",
        );
      }
    }
    return ValidateResult.failure("Invalid card selection for add stack action");
  }

  static ValidateResult canAddTableAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    if (currentCardSelection.selectedCard != null ||
        currentCardSelection.selectedStacks.isNotEmpty) {
      return ValidateResult.failure(
        "Cannot add table cards with hand or stack selection",
      );
    }
    final selectedCards = currentCardSelection.selectedCards;
    final pid = currentCardSelection.pid;

    final myHandCards = gameState.hands[pid] ?? [];
    if (selectedCards.length > 1) {
      // values of the selectedCard (A => [1,14])
      final handVals = possibleValuesInHand(myHandCards, null);
      final totals = possibleTotals(selectedCards);
      for (final t in totals) {
        if (handVals.contains(t)) return ValidateResult.success();
      }
      return ValidateResult.failure(
        "Card sum does not match any card in hand",
      );
    }
    return ValidateResult.failure("Must select at least 2 table cards");
  }

  static ValidateResult canPairAllAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final selectedCard = currentCardSelection.selectedCard;
    final selectedCards = currentCardSelection.selectedCards;
    final selectedStacks = currentCardSelection.selectedStacks;
    final pid = currentCardSelection.pid;

    final myHandCards = gameState.hands[pid] ?? [];

    if (gameState.currentTurnPlayerId != pid) {
      return ValidateResult.notTurn();
    }

    if (selectedCard == null) {
      return ValidateResult.noSelectedCard();
    }

    if (selectedCards.isEmpty && selectedStacks.isEmpty) {
      return ValidateResult.failure("Must select cards or stacks to pair");
    }

    final cardVals = possibleCardValues(selectedCard);
    final handVals = possibleValuesInHand(myHandCards, selectedCard);

    for (final v in cardVals) {
      final allCardsMatch = selectedCards.every(
        (c) => possibleValuesForTableCard(c).contains(v),
      );

      if (!allCardsMatch) continue;

      final allStacksMatch = selectedStacks.every((s) => s.stackValue == v);

      if (!allStacksMatch) continue;

      if (handVals.contains(v)) {
        return ValidateResult.success();
      }
    }

    return ValidateResult.failure(
      "No matching card in hand to pair the selection",
    );
  }

  static ValidateResult canPairAllTableAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final selectedCard = currentCardSelection.selectedCard;
    final selectedCards = currentCardSelection.selectedCards;
    final selectedStacks = currentCardSelection.selectedStacks;
    final pid = currentCardSelection.pid;

    final myHandCards = gameState.hands[pid] ?? [];

    if (gameState.currentTurnPlayerId != pid) {
      return ValidateResult.notTurn();
    }

    // table-only pair
    if (selectedCard != null) {
      return ValidateResult.failure(
        "Cannot use hand card for table-only pair",
      );
    }

    final totalSelected = selectedCards.length + selectedStacks.length;
    if (totalSelected < 2) {
      return ValidateResult.failure(
        "Must select at least 2 table cards or stacks",
      );
    }

    final handVals = possibleValuesInHand(myHandCards, null);

    final sets = <Set<int>>[];

    for (final card in selectedCards) {
      sets.add(possibleValuesForTableCard(card));
    }

    for (final stack in selectedStacks) {
      sets.add({stack.stackValue});
    }

    if (sets.isEmpty) {
      return ValidateResult.failure("No valid selections");
    }

    final commonVals = intersectAll(sets);
    if (commonVals.isEmpty) {
      return ValidateResult.failure(
        "Selected cards do not have common value",
      );
    }

    if (commonVals.any(handVals.contains)) {
      return ValidateResult.success();
    }

    return ValidateResult.failure(
      "No matching card in hand to pair the selection",
    );
  }

  ///VALIDATE COMBO ACTIONS BASED ON CARD SELECTION AND GAMESTATE
  static ValidateResult canAddAndPairAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final selectedCard = currentCardSelection.selectedCard;
    final selectedCards = currentCardSelection.selectedCards;
    final selectedStacks = currentCardSelection.selectedStacks;
    final pid = currentCardSelection.pid;

    final myHandCards = gameState.hands[pid] ?? [];
    final playingAreaCards = gameState.playingArea;
    final playingAreaStacks = gameState.playingAreaStacks;

    if (selectedCard == null) {
      return ValidateResult.noSelectedCard();
    }

    final handVals = possibleValuesInHand(myHandCards, selectedCard);
    final selectedVals = possibleCardValues(selectedCard);

    Set<int> addTotals;

    // add to loose cards
    if (selectedCards.isNotEmpty && selectedStacks.isEmpty) {
      addTotals = possibleTotals(selectedCards);
    }
    // add to one unpaired stack
    else if (selectedStacks.length == 1 &&
        !selectedStacks.first.paired &&
        selectedCards.isEmpty) {
      addTotals = {selectedStacks.first.stackValue};
    } else {
      return ValidateResult.failure(
        "Invalid selection for add and pair action",
      );
    }

    final potentialValues = <int>{};
    for (final sv in selectedVals) {
      for (final t in addTotals) {
        potentialValues.add(sv + t);
      }
    }

    // Search the rest of the table for matching value after the add
    for (final v in potentialValues) {
      bool existsOnTable = false;

      // other loose cards on table
      for (final c in playingAreaCards) {
        if (selectedCards.contains(c)) continue;

        if (possibleValuesForTableCard(c).contains(v)) {
          existsOnTable = true;
          break;
        }
      }

      // other stacks on table
      if (!existsOnTable) {
        for (final s in playingAreaStacks) {
          if (selectedStacks.contains(s)) continue;

          if (s.stackValue == v) {
            existsOnTable = true;
            break;
          }
        }
      }

      final existsInHand = handVals.contains(v);

      if (existsOnTable && existsInHand) {
        return ValidateResult.success();
      }
    }

    return ValidateResult.failure(
      "No matching pair exists after add on table",
    );
  }

  static ValidateResult canAddAndTakeAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final selectedCard = currentCardSelection.selectedCard;
    final selectedCards = currentCardSelection.selectedCards;

    if (selectedCard == null) {
      return ValidateResult.noSelectedCard();
    }

    if (selectedCards.length < 2) {
      return ValidateResult.failure("Must select at least 2 table cards");
    }

    final cardVals = possibleCardValues(selectedCard);
    final totals = possibleTotals(selectedCards);

    if (cardVals.any(totals.contains)) {
      return ValidateResult.success();
    }

    return ValidateResult.failure(
      "Card value does not match the sum of selected cards",
    );
  }

  static ValidateResult canPairAndTakeAction(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  ) {
    final selectedCard = currentCardSelection.selectedCard;
    final selectedCards = currentCardSelection.selectedCards;
    final selectedStacks = currentCardSelection.selectedStacks;

    if (selectedCard == null) {
      return ValidateResult.noSelectedCard();
    }

    if (selectedCards.isEmpty && selectedStacks.isEmpty) {
      return ValidateResult.failure("Must select cards or stacks to pair");
    }
    if ((selectedCards.isEmpty && selectedStacks.length < 2) ||
        (selectedCards.length < 2 && selectedStacks.isEmpty)) {
      return ValidateResult.failure(
        "Must select at least 2 items to pair and take",
      );
    }

    final cardVals = possibleCardValues(selectedCard);

    for (final v in cardVals) {
      final allCardsMatch = selectedCards.every(
        (c) => possibleValuesForTableCard(c).contains(v),
      );

      if (!allCardsMatch) continue;

      final allStacksMatch = selectedStacks.every((s) => s.stackValue == v);

      if (!allStacksMatch) continue;

      return ValidateResult.success();
    }

    return ValidateResult.failure(
      "No matching card value found to pair and take",
    );
  }

  /// --------- HELPERS --------- ///
  static Set<int> possibleValuesForTableCard(PlayingCardModel c) =>
      c.isAce ? {1, 14} : {c.valueLow};

  static Set<int> intersectAll(Iterable<Set<int>> sets) {
    final it = sets.iterator;
    if (!it.moveNext()) return <int>{};
    var acc = Set<int>.from(it.current);
    while (it.moveNext()) {
      acc = acc.intersection(it.current);
      if (acc.isEmpty) break;
    }
    return acc;
  }

  static List<int> possibleCardValues(PlayingCardModel c) {
    return c.isAce ? const [1, 14] : [c.valueLow];
  }

  /// All possible totals for a list of cards (accounts for A=1 or 14)
  static Set<int> possibleTotals(List<PlayingCardModel> cards) {
    Set<int> totals = {0};
    for (final c in cards) {
      final vals = possibleCardValues(c);
      final next = <int>{};
      for (final t in totals) {
        for (final v in vals) {
          next.add(t + v);
        }
      }
      totals = next;
    }
    return totals;
  }

  /// Player card values excluding selectedCard (your previous behavior)
  static Set<int> possibleValuesInHand(
    List<PlayingCardModel> cards,
    PlayingCardModel? selectedCard,
  ) {
    final set = <int>{};
    for (final c in cards) {
      if (selectedCard != null && c == selectedCard) continue;
      set.addAll(possibleCardValues(c));
    }
    return set;
  }

  static int? pickTargetValue(
    Set<int> candidates, {
    int max = 14,
    int? mustEqual,
  }) {
    final filtered = candidates.where((v) => v <= max).toList()..sort();
    if (filtered.isEmpty) return null;
    if (mustEqual != null) {
      final i = filtered.indexOf(mustEqual);
      if (i != -1) return mustEqual;
    }
    return filtered.last; // choose highest <= max (good default)
  }

  static Set<int> possibleBuildTotals({
    required PlayingCardModel? selectedCard,
    required List<PlayingCardModel> selectedCards,
    required List<PlayingAreaStackModel> selectedStacks,
  }) {
    Set<int> totals = {0};

    // selectedCards sum (ace-flex)
    if (selectedCards.isNotEmpty) {
      final t = possibleTotals(selectedCards);
      final next = <int>{};
      for (final a in totals) {
        for (final b in t) {
          next.add(a + b);
        }
      }
      totals = next;
    }

    // selectedStacks contribute fixed values (your stacks currently fixed)
    for (final s in selectedStacks) {
      final next = <int>{};
      for (final a in totals) {
        next.add(a + s.stackValue);
      }
      totals = next;
    }

    // selectedCard (ace-flex)
    if (selectedCard != null) {
      final vals = possibleCardValues(selectedCard);
      final next = <int>{};
      for (final a in totals) {
        for (final v in vals) {
          next.add(a + v);
        }
      }
      totals = next;
    }

    return totals;
  }
}
