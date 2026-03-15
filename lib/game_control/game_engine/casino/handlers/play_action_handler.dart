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
      case AddTableCardsAction a:
        return handleAddTableCardsAction(nextState, a);
      case PairCardsAction a:
        return handlePairCardsAction(nextState, a);
      case PairTableCardsAction a:
        return handlePairTableCardsAction(nextState, a);
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
