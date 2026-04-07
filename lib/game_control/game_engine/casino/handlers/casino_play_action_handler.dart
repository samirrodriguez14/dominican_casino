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

    // REMOVE USED CARD FROM PLAYER HAND
    nextState.hands[pid]?.removeWhere((card) => card == a.usedCard);

    // REMOVE TARGET CARD FROM PLAYING AREA
    nextState.playingArea.removeWhere((card) => card == a.targetCard);

    // ADD BOTH CARDS TO PLAYER'S WON/CAPTURED CARDS
    nextState.playersDeck.putIfAbsent(pid, () => []);
    nextState.playersDeck[pid]!.addAll([a.usedCard, a.targetCard]);

    return nextState;
  }

  static GameState handleTakeStackAction(
    GameState nextState,
    TakeStackAction a,
  ) {
    final pid = a.performedById;

    // REMOVE USED CARD FROM PLAYER HAND
    nextState.hands[pid]?.removeWhere((card) => card == a.usedCard);

    // REMOVE TARGET STACK FROM PLAYING AREA
    nextState.playingAreaStacks.removeWhere((stack) => stack == a.targetStack);

    // ADD CARD AND STACK PLAYER'S WON/CAPTURED CARDS
    nextState.playersDeck.putIfAbsent(pid, () => []);
    nextState.playersDeck[pid]!.addAll([a.usedCard, ...a.targetStack.cards]);

    return nextState;
  }

  static GameState handleAddCardsAction(GameState g, AddCardsAction a) {
    final pid = a.performedById;
    final usedCard = a.usedCard;

    final stackCards = <PlayingCardModel>[];

    // remove used hand card
    g.hands[pid]?.removeWhere((c) => c == usedCard);
    stackCards.add(usedCard);

    // remove selected table cards
    for (final card in a.targetCards) {
      g.playingArea.removeWhere((c) => c == card);
      stackCards.add(card);
    }

    final newStack = PlayingAreaStackModel(
      id: _uuid.v4().substring(0, 8),
      cards: stackCards,
      stackValue: _calculateStackValue(stackCards),
      paired: false,
    );

    g.playingAreaStacks.add(newStack);

    return g;
  }

  static GameState handleAddCardStackAction(GameState g, AddCardStackAction a) {
    final pid = a.performedById;
    final usedCard = a.usedCard;

    final stackCards = <PlayingCardModel>[];

    // remove used hand card
    g.hands[pid]?.removeWhere((c) => c.id == usedCard.id);
    stackCards.add(usedCard);

    // remove selected table stacks
    final targetStackIds = a.targetStacks.map((s) => s.id).toSet();
    g.playingAreaStacks.removeWhere((s) => targetStackIds.contains(s.id));

    // add cards from removed stacks
    for (final stack in a.targetStacks) {
      stackCards.addAll(stack.cards);
    }

    final newStack = PlayingAreaStackModel(
      id: _uuid.v4().substring(0, 8),
      cards: stackCards,
      stackValue: _calculateStackValue(stackCards),
      paired: false,
    );

    g.playingAreaStacks.add(newStack);

    return g;
  }

  static GameState handleAddTableCardsAction(
    GameState g,
    AddTableCardsAction a,
  ) {
    final stackCards = <PlayingCardModel>[];
    // remove selected table cards
    for (final card in a.targetCards) {
      g.playingArea.removeWhere((c) => c == card);
      stackCards.add(card);
    }
    final newStack = PlayingAreaStackModel(
      id: _uuid.v4().substring(0, 8),
      cards: stackCards,
      stackValue: _calculateStackValue(stackCards),
      paired: false,
    );
    g.playingAreaStacks.add(newStack);
    return g;
  }

  static GameState handlePairCardsAction(GameState g, PairCardsAction a) {
    final pid = a.performedById;
    final usedCard = a.usedCard;

    final pairCards = <PlayingCardModel>[];

    // remove used card from player's hand
    g.hands[pid]?.removeWhere((c) => c == usedCard);

    // the used card becomes part of the pair stack
    pairCards.add(usedCard);

    // remove selected loose cards from table
    for (final card in a.targetCards) {
      g.playingArea.removeWhere((c) => c == card);
      pairCards.add(card);
    }

    // remove selected stacks from table and merge their cards
    for (final stack in a.targetStacks) {
      g.playingAreaStacks.removeWhere((s) => s == stack);
      pairCards.addAll(stack.cards);
    }

    final newStack = PlayingAreaStackModel(
      cards: pairCards,
      stackValue: a.usedCard.valueHigh,
      paired: true,
      id: _uuid.v4().substring(0, 8),
    );

    g.playingAreaStacks.add(newStack);

    return g;
  }

  static GameState handlePairTableCardsAction(
    GameState g,
    PairTableCardsAction a,
  ) {
    final pairCards = <PlayingCardModel>[];

    // remove selected loose cards from table
    for (final card in a.targetCards) {
      g.playingArea.removeWhere((c) => c == card);
      pairCards.add(card);
    }

    // remove selected stacks from table and merge their cards
    for (final stack in a.targetStacks) {
      g.playingAreaStacks.removeWhere((s) => s == stack);
      pairCards.addAll(stack.cards);
    }

    // determine pair value from the selection
    final pairValue = _resolvePairTableValue(a);

    final newStack = PlayingAreaStackModel(
      cards: pairCards,
      stackValue: pairValue,
      paired: true,
      id: _uuid.v4().substring(0, 8),
    );

    g.playingAreaStacks.add(newStack);

    return g;
  }

  static GameState handleAddAndPairAction(
    GameState g,
    AddAndPairCardsAction a,
  ) {
    final pid = a.performedById;
    final pairCards = <PlayingCardModel>[];

    // remove used card from hand
    g.hands[pid]?.removeWhere((c) => c == a.usedCard);
    pairCards.add(a.usedCard);

    // determine add base value
    int addBaseValue = 0;

    // remove selected loose cards being added to
    if (a.targetCards.isNotEmpty && a.targetStacks.isEmpty) {
      for (final card in a.targetCards) {
        g.playingArea.removeWhere((c) => c == card);
        pairCards.add(card);
      }
      addBaseValue = _calculateStackValue(a.targetCards);
    }
    // remove selected stack being added to
    else if (a.targetStacks.length == 1 && a.targetCards.isEmpty) {
      final targetStack = a.targetStacks.first;
      g.playingAreaStacks.removeWhere((s) => s == targetStack);
      pairCards.addAll(targetStack.cards);
      addBaseValue = targetStack.stackValue;
    } else {
      throw Exception(
        'AddAndPairCardsAction must target either loose cards or exactly one stack.',
      );
    }

    // resulting value after adding usedCard
    final pairValue = addBaseValue + a.usedCard.valueLow;

    // absorb all remaining loose table cards matching pairValue
    final matchingLooseCards = g.playingArea.where((card) {
      return _possibleValuesForTableCard(card).contains(pairValue);
    }).toList();

    for (final card in matchingLooseCards) {
      g.playingArea.removeWhere((c) => c == card);
      pairCards.add(card);
    }

    // absorb all remaining stacks matching pairValue
    final matchingStacks = g.playingAreaStacks.where((stack) {
      return stack.stackValue == pairValue;
    }).toList();

    for (final stack in matchingStacks) {
      g.playingAreaStacks.removeWhere((s) => s == stack);
      pairCards.addAll(stack.cards);
    }

    final newStack = PlayingAreaStackModel(
      cards: pairCards,
      stackValue: pairValue,
      paired: true,
      id: _uuid.v4().substring(0, 8),
    );

    g.playingAreaStacks.add(newStack);

    return g;
  }

  static GameState handleAddAndTakeAction(GameState g, AddAndTakeAction a) {
    final pid = a.performedById;
    final takenCards = <PlayingCardModel>[];

    // remove used card from hand
    g.hands[pid]?.removeWhere((c) => c == a.usedCard);
    takenCards.add(a.usedCard);

    // remove selected loose cards from table
    for (final card in a.targetCards) {
      g.playingArea.removeWhere((c) => c == card);
      takenCards.add(card);
    }

    // add all taken cards to player's deck
    g.playersDeck.putIfAbsent(pid, () => []);
    g.playersDeck[pid]!.addAll(takenCards);

    // track last taker if you use that for leftover table cards later
    g.lastTookCardId = pid;

    return g;
  }

  static GameState handlePairAndTakeAction(
    GameState g,
    PairAndTakeCardsAction a,
  ) {
    final pid = a.performedById;
    final takenCards = <PlayingCardModel>[];

    // remove used card from hand
    g.hands[pid]?.removeWhere((c) => c == a.usedCard);
    takenCards.add(a.usedCard);

    // remove selected loose cards from table
    for (final card in a.targetCards) {
      g.playingArea.removeWhere((c) => c == card);
      takenCards.add(card);
    }

    // remove selected stacks from table
    for (final stack in a.targetStacks) {
      g.playingAreaStacks.removeWhere((s) => s == stack);
      takenCards.addAll(stack.cards);
    }

    // add all taken cards to player's deck
    g.playersDeck.putIfAbsent(pid, () => []);
    g.playersDeck[pid]!.addAll(takenCards);

    // track last taker
    g.lastTookCardId = pid;

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
