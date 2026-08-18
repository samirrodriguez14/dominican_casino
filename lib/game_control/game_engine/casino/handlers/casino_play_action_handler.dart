import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:uuid/uuid.dart';

class CasinoPlayActionHandler {
  static final Uuid _uuid = const Uuid();

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
      case TakeStackAction a:
        return handleTakeStackAction(nextState, a);
      case AddCardsAction a:
        return handleAddCardsAction(nextState, a);
      case AddCardStackAction a:
        return handleAddCardStackAction(nextState, a);
      case AddTableCardsAction a:
        return handleAddTableCardsAction(nextState, a);
      case PairCardsAction a:
        return handlePairCardsAction(nextState, a);
      case PairTableCardsAction a:
        return handlePairTableCardsAction(nextState, a);
      case AddAndPairCardsAction a:
        return handleAddAndPairAction(nextState, a);
      case AddAndTakeAction a:
        return handleAddAndTakeAction(nextState, a);
      case PairAndTakeCardsAction a:
        return handlePairAndTakeAction(nextState, a);
    }
    return nextState;
  }

  static GameState handlePlayCardAction(GameState nextState, PlayCardAction a) {
    final pid = a.performedById;
    nextState.hands[pid]?.removeWhere((card) => card == a.usedCard);
    nextState.placeCardOnTable(a.usedCard);
    return nextState;
  }

  static GameState handleTakeCardAction(GameState nextState, TakeCardAction a) {
    final pid = a.performedById;
    nextState.hands[pid]?.removeWhere((card) => card == a.usedCard);
    nextState.removeLooseCardFromTable(a.targetCard);
    nextState.addCapturedCards(pid, [a.usedCard, a.targetCard]);
    return nextState;
  }

  static GameState handleTakeStackAction(
    GameState nextState,
    TakeStackAction a,
  ) {
    final pid = a.performedById;
    nextState.hands[pid]?.removeWhere((card) => card == a.usedCard);
    nextState.removeStackFromTable(a.targetStack);
    nextState.addCapturedCards(pid, [a.usedCard, ...a.targetStack.cards]);
    return nextState;
  }

  static GameState handleAddCardsAction(GameState g, AddCardsAction a) {
    final pid = a.performedById;
    final usedCard = a.usedCard;
    final stackCards = <PlayingCardModel>[usedCard];

    g.hands[pid]?.removeWhere((c) => c == usedCard);
    for (final card in a.targetCards) {
      stackCards.add(card);
    }

    final newStack = PlayingAreaStackModel(
      id: _uuid.v4().substring(0, 8),
      cards: stackCards,
      stackValue: _calculateStackValue(stackCards),
      paired: false,
    );

    g.formStackInPlace(
      stack: newStack,
      removedCards: a.targetCards,
    );
    return g;
  }

  static GameState handleAddCardStackAction(GameState g, AddCardStackAction a) {
    final pid = a.performedById;
    final usedCard = a.usedCard;
    final stackCards = <PlayingCardModel>[usedCard];

    g.hands[pid]?.removeWhere((c) => c.id == usedCard.id);
    for (final stack in a.targetStacks) {
      stackCards.addAll(stack.cards);
    }

    final newStack = PlayingAreaStackModel(
      id: _uuid.v4().substring(0, 8),
      cards: stackCards,
      stackValue: _calculateStackValue(stackCards),
      paired: false,
    );

    g.formStackInPlace(stack: newStack, removedStacks: a.targetStacks);
    return g;
  }

  static GameState handleAddTableCardsAction(
    GameState g,
    AddTableCardsAction a,
  ) {
    final stackCards = <PlayingCardModel>[...a.targetCards];
    final newStack = PlayingAreaStackModel(
      id: _uuid.v4().substring(0, 8),
      cards: stackCards,
      stackValue: _calculateStackValue(stackCards),
      paired: false,
    );
    g.formStackInPlace(stack: newStack, removedCards: a.targetCards);
    return g;
  }

  static GameState handlePairCardsAction(GameState g, PairCardsAction a) {
    final pid = a.performedById;
    final pairCards = <PlayingCardModel>[a.usedCard];

    g.hands[pid]?.removeWhere((c) => c == a.usedCard);
    for (final card in a.targetCards) {
      pairCards.add(card);
    }
    for (final stack in a.targetStacks) {
      pairCards.addAll(stack.cards);
    }

    final newStack = PlayingAreaStackModel(
      cards: pairCards,
      stackValue: a.usedCard.valueHigh,
      paired: true,
      id: _uuid.v4().substring(0, 8),
    );

    g.formStackInPlace(
      stack: newStack,
      removedCards: a.targetCards,
      removedStacks: a.targetStacks,
    );
    return g;
  }

  static GameState handlePairTableCardsAction(
    GameState g,
    PairTableCardsAction a,
  ) {
    final pairCards = <PlayingCardModel>[];
    for (final card in a.targetCards) {
      pairCards.add(card);
    }
    for (final stack in a.targetStacks) {
      pairCards.addAll(stack.cards);
    }

    final newStack = PlayingAreaStackModel(
      cards: pairCards,
      stackValue: _resolvePairTableValue(a),
      paired: true,
      id: _uuid.v4().substring(0, 8),
    );

    g.formStackInPlace(
      stack: newStack,
      removedCards: a.targetCards,
      removedStacks: a.targetStacks,
    );
    return g;
  }

  static GameState handleAddAndPairAction(
    GameState g,
    AddAndPairCardsAction a,
  ) {
    final pid = a.performedById;
    final pairCards = <PlayingCardModel>[];
    final removedCards = <PlayingCardModel>[];
    final removedStacks = <PlayingAreaStackModel>[];

    g.hands[pid]?.removeWhere((c) => c == a.usedCard);
    pairCards.add(a.usedCard);

    int addBaseValue = 0;

    if (a.targetCards.isNotEmpty && a.targetStacks.isEmpty) {
      removedCards.addAll(a.targetCards);
      pairCards.addAll(a.targetCards);
      addBaseValue = _calculateStackValue(a.targetCards);
    } else if (a.targetStacks.length == 1 && a.targetCards.isEmpty) {
      final targetStack = a.targetStacks.first;
      removedStacks.add(targetStack);
      pairCards.addAll(targetStack.cards);
      addBaseValue = targetStack.stackValue;
    } else {
      throw Exception(
        'AddAndPairCardsAction must target either loose cards or exactly one stack.',
      );
    }

    final pairValue = addBaseValue + a.usedCard.valueLow;

    final matchingLooseCards = g.playingArea.where((card) {
      return _possibleValuesForTableCard(card).contains(pairValue) &&
          !removedCards.any((r) => r.id == card.id);
    }).toList();
    removedCards.addAll(matchingLooseCards);
    pairCards.addAll(matchingLooseCards);

    final matchingStacks = g.playingAreaStacks.where((stack) {
      return stack.stackValue == pairValue &&
          !removedStacks.any((r) => r.id == stack.id);
    }).toList();
    removedStacks.addAll(matchingStacks);
    for (final stack in matchingStacks) {
      pairCards.addAll(stack.cards);
    }

    final newStack = PlayingAreaStackModel(
      cards: pairCards,
      stackValue: pairValue,
      paired: true,
      id: _uuid.v4().substring(0, 8),
    );

    g.formStackInPlace(
      stack: newStack,
      removedCards: removedCards,
      removedStacks: removedStacks,
    );
    return g;
  }

  static GameState handleAddAndTakeAction(GameState g, AddAndTakeAction a) {
    final pid = a.performedById;
    final takenCards = <PlayingCardModel>[a.usedCard];

    g.hands[pid]?.removeWhere((c) => c == a.usedCard);
    for (final card in a.targetCards) {
      g.removeLooseCardFromTable(card);
      takenCards.add(card);
    }

    g.addCapturedCards(pid, takenCards);
    return g;
  }

  static GameState handlePairAndTakeAction(
    GameState g,
    PairAndTakeCardsAction a,
  ) {
    final pid = a.performedById;
    final takenCards = <PlayingCardModel>[a.usedCard];

    g.hands[pid]?.removeWhere((c) => c == a.usedCard);
    for (final card in a.targetCards) {
      g.removeLooseCardFromTable(card);
      takenCards.add(card);
    }
    for (final stack in a.targetStacks) {
      g.removeStackFromTable(stack);
      takenCards.addAll(stack.cards);
    }

    g.addCapturedCards(pid, takenCards);
    return g;
  }

  static Set<int> _possibleValuesForTableCard(PlayingCardModel card) {
    if (card.valueLow != card.valueHigh) {
      return {card.valueLow, card.valueHigh};
    }
    return {card.valueLow};
  }

  static int _resolvePairTableValue(PairTableCardsAction a) {
    if (a.targetStacks.isNotEmpty) {
      return a.targetStacks.first.stackValue;
    }
    if (a.targetCards.isNotEmpty) {
      return a.targetCards.first.valueHigh;
    }
    throw Exception(
      'PairTableCardsAction requires targetCards or targetStacks.',
    );
  }

  static int _calculateStackValue(List<PlayingCardModel> cards) {
    return cards.fold(0, (sum, c) => sum + c.valueLow);
  }
}
