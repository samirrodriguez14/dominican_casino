import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:uuid/uuid.dart';

class EventHandler {
  static final Uuid _uuid = const Uuid();

  static List<CardMoveEvent> handlegenerateEvents(
    GameState gameState,
    PlayAction actionn,
  ) {
    switch (actionn) {
      case PlayCardAction a:
        return generatePlayEvents(a);
      case TakeCardAction a:
        return generateTakeCardEvents(a);
      case TakeStackAction a:
        return generateTakeStackEvents(a);
      case AddCardsAction a:
        return generateAddCardsEvents(a);
      case AddTableCardsAction a:
        return generateAddTableCardsEvents(a);
      case PairCardsAction a:
        return generatePairCardsEvents(a);
      case PairTableCardsAction a:
        return generatePairTableCardsEvents(a);
      case AddAndPairCardsAction a:
        return generateAddAndPairCardsEvents(a);
      case AddAndTakeAction a:
        return generateAddAndTakeCardsEvent(a);
      case PairAndTakeCardsAction a:
        return generatePairAndTakeCardsEvent(a);
    }
    return [];
  }

  /// -----------PLAY ACTIONS EVENTS----------- ///
  static List<CardMoveEvent> generatePlayEvents(PlayCardAction a) {
    Zone from = Zone(type: ZoneType.playerHand, holderId: a.performedById);
    Zone to = Zone(type: ZoneType.table, holderId: ZoneType.table.name);
    final fromHandtoTable = CardMoveEvent(
      id: _uuid.v4().substring(0, 8),
      from: from,
      to: to,
      card: a.usedCard,
      performedBy: a.performedById,
    );
    return [fromHandtoTable];
  }

  static List<CardMoveEvent> generateTakeCardEvents(TakeCardAction a) {
    final Zone hand = Zone(
      type: ZoneType.playerHand,
      holderId: a.performedById,
    );

    final Zone table = Zone(
      type: ZoneType.table,
      holderId: ZoneType.table.name,
    );

    final Zone captured = Zone(
      type: ZoneType.playerDeck,
      holderId: a.performedById,
    );

    final playedTableToCaptured = CardMoveEvent(
      id: _uuid.v4().substring(0, 8),
      from: hand,
      to: captured,
      card: a.usedCard,
      performedBy: a.performedById,
    );

    final targetTableToCaptured = CardMoveEvent(
      id: _uuid.v4().substring(0, 8),
      from: table,
      to: captured,
      card: a.targetCard,
      performedBy: a.performedById,
    );

    return [targetTableToCaptured, playedTableToCaptured];
  }

  static List<CardMoveEvent> generateTakeStackEvents(TakeStackAction a) {
    final Zone hand = Zone(
      type: ZoneType.playerHand,
      holderId: a.performedById,
    );

    final Zone table = Zone(
      type: ZoneType.table,
      holderId: ZoneType.table.name,
    );

    final Zone captured = Zone(
      type: ZoneType.playerDeck,
      holderId: a.performedById,
    );
    List<CardMoveEvent> allEvents = [];
    final playedHandToCaptured = CardMoveEvent(
      id: _uuid.v4().substring(0, 8),
      from: hand,
      to: captured,
      card: a.usedCard,
      performedBy: a.performedById,
    );
    allEvents.add(playedHandToCaptured);
    for (var card in a.targetStack.cards) {
      final targetTableToCaptured = CardMoveEvent(
        id: _uuid.v4().substring(0, 8),
        from: table,
        to: captured,
        card: card,
        performedBy: a.performedById,
      );
      allEvents.add(targetTableToCaptured);
    }

    return allEvents;
  }

  static List<CardMoveEvent> generateAddCardsEvents(AddCardsAction a) {
    final Zone hand = Zone(
      type: ZoneType.playerHand,
      holderId: a.performedById,
    );

    final Zone table = Zone(
      type: ZoneType.table,
      holderId: ZoneType.table.name,
    );

    final List<CardMoveEvent> allEvents = [];

    final playedTableToCaptured = CardMoveEvent(
      id: _uuid.v4().substring(0, 8),
      from: hand,
      to: table,
      card: a.usedCard,
      performedBy: a.performedById,
    );
    allEvents.add(playedTableToCaptured);

    for (var card in a.targetCards) {
      final targetTableToTable = CardMoveEvent(
        id: _uuid.v4().substring(0, 8),
        from: table,
        to: table,
        card: card,
        performedBy: a.performedById,
      );
      allEvents.add(targetTableToTable);
    }

    return allEvents;
  }

  static List<CardMoveEvent> generateAddTableCardsEvents(
    AddTableCardsAction a,
  ) {
    final Zone table = Zone(
      type: ZoneType.table,
      holderId: ZoneType.table.name,
    );

    final List<CardMoveEvent> allEvents = [];
    for (var card in a.targetCards) {
      final targetTableToTable = CardMoveEvent(
        id: _uuid.v4().substring(0, 8),
        from: table,
        to: table,
        card: card,
        performedBy: a.performedById,
      );
      allEvents.add(targetTableToTable);
    }

    return allEvents;
  }

  static List<CardMoveEvent> generatePairCardsEvents(PairCardsAction a) {
    final Zone hand = Zone(
      type: ZoneType.playerHand,
      holderId: a.performedById,
    );

    final Zone table = Zone(
      type: ZoneType.table,
      holderId: ZoneType.table.name,
    );

    final List<CardMoveEvent> allEvents = [];

    // 1. Hand card goes to table
    final handToTable = CardMoveEvent(
      id: _uuid.v4().substring(0, 8),
      from: hand,
      to: table,
      card: a.usedCard,
      performedBy: a.performedById,
    );
    allEvents.add(handToTable);

    // 2. Loose table cards reorganize into the pair
    for (final card in a.targetCards) {
      final tableToTable = CardMoveEvent(
        id: _uuid.v4().substring(0, 8),
        from: table,
        to: table,
        card: card,
        performedBy: a.performedById,
      );
      allEvents.add(tableToTable);
    }

    // 3. Cards inside selected stacks reorganize into the pair
    for (final stack in a.targetStacks) {
      for (final card in stack.cards) {
        final stackToTable = CardMoveEvent(
          id: _uuid.v4().substring(0, 8),
          from: table,
          to: table,
          card: card,
          performedBy: a.performedById,
        );
        allEvents.add(stackToTable);
      }
    }

    return allEvents;
  }

  static List<CardMoveEvent> generatePairTableCardsEvents(
    PairTableCardsAction a,
  ) {
    final Zone table = Zone(
      type: ZoneType.table,
      holderId: ZoneType.table.name,
    );

    final List<CardMoveEvent> allEvents = [];

    // Loose table cards reorganize into the pair
    for (final card in a.targetCards) {
      final tableToTable = CardMoveEvent(
        id: _uuid.v4().substring(0, 8),
        from: table,
        to: table,
        card: card,
        performedBy: a.performedById,
      );
      allEvents.add(tableToTable);
    }

    // Cards inside selected stacks reorganize into the new pair
    for (final stack in a.targetStacks) {
      for (final card in stack.cards) {
        final stackToTable = CardMoveEvent(
          id: _uuid.v4().substring(0, 8),
          from: table,
          to: table,
          card: card,
          performedBy: a.performedById,
        );
        allEvents.add(stackToTable);
      }
    }

    return allEvents;
  }

  static List<CardMoveEvent> generateAddAndPairCardsEvents(
    AddAndPairCardsAction a,
  ) {
    final Zone hand = Zone(
      type: ZoneType.playerHand,
      holderId: a.performedById,
    );

    final Zone table = Zone(
      type: ZoneType.table,
      holderId: ZoneType.table.name,
    );

    final List<CardMoveEvent> allEvents = [];

    // 1. Hand card goes to table
    final handToTable = CardMoveEvent(
      id: _uuid.v4().substring(0, 8),
      from: hand,
      to: table,
      card: a.usedCard,
      performedBy: a.performedById,
    );
    allEvents.add(handToTable);

    // 2. Cards that were selected as the add target reorganize
    for (final card in a.targetCards) {
      final tableToTable = CardMoveEvent(
        id: _uuid.v4().substring(0, 8),
        from: table,
        to: table,
        card: card,
        performedBy: a.performedById,
      );
      allEvents.add(tableToTable);
    }

    // 3. Cards from the selected stack reorganize
    for (final stack in a.targetStacks) {
      for (final card in stack.cards) {
        final stackToTable = CardMoveEvent(
          id: _uuid.v4().substring(0, 8),
          from: table,
          to: table,
          card: card,
          performedBy: a.performedById,
        );
        allEvents.add(stackToTable);
      }
    }

    return allEvents;
  }

  static List<CardMoveEvent> generateAddAndTakeCardsEvent(AddAndTakeAction a) {
    final Zone hand = Zone(
      type: ZoneType.playerHand,
      holderId: a.performedById,
    );

    final Zone table = Zone(
      type: ZoneType.table,
      holderId: ZoneType.table.name,
    );

    final Zone captured = Zone(
      type: ZoneType.playerDeck,
      holderId: a.performedById,
    );

    final List<CardMoveEvent> allEvents = [];

    // 2. Played card gets captured
    final tableToCapturedPlayed = CardMoveEvent(
      id: _uuid.v4().substring(0, 8),
      from: hand,
      to: captured,
      card: a.usedCard,
      performedBy: a.performedById,
    );
    allEvents.add(tableToCapturedPlayed);

    // 3. Captured loose cards
    for (final card in a.targetCards) {
      final tableToCaptured = CardMoveEvent(
        id: _uuid.v4().substring(0, 8),
        from: table,
        to: captured,
        card: card,
        performedBy: a.performedById,
      );
      allEvents.add(tableToCaptured);
    }

    return allEvents;
  }

  static List<CardMoveEvent> generatePairAndTakeCardsEvent(
    PairAndTakeCardsAction a,
  ) {
    final Zone hand = Zone(
      type: ZoneType.playerHand,
      holderId: a.performedById,
    );

    final Zone table = Zone(
      type: ZoneType.table,
      holderId: ZoneType.table.name,
    );

    final Zone captured = Zone(
      type: ZoneType.playerDeck,
      holderId: a.performedById,
    );

    final List<CardMoveEvent> allEvents = [];

    // 2. played card gets captured
    allEvents.add(
      CardMoveEvent(
        id: _uuid.v4().substring(0, 8),
        from: hand,
        to: captured,
        card: a.usedCard,
        performedBy: a.performedById,
      ),
    );

    // 3. loose cards get captured
    for (final card in a.targetCards) {
      allEvents.add(
        CardMoveEvent(
          id: _uuid.v4().substring(0, 8),
          from: table,
          to: captured,
          card: card,
          performedBy: a.performedById,
        ),
      );
    }

    // 4. stack cards get captured
    for (final stack in a.targetStacks) {
      for (final card in stack.cards) {
        allEvents.add(
          CardMoveEvent(
            id: _uuid.v4().substring(0, 8),
            from: table,
            to: captured,
            card: card,
            performedBy: a.performedById,
          ),
        );
      }
    }

    return allEvents;
  }

  /// ----------- IN GAME ACTIONS EVENTS ----------- ///

  static List<CardMoveEvent> generateDealToHandEvent(
    List<PlayingCardModel> cards,
    String pid,
    String performedById,
  ) {
    List<CardMoveEvent> events = [];
    for (var card in cards) {
      Zone from = Zone(
        type: ZoneType.gameDeck,
        holderId: ZoneType.gameDeck.name,
      );
      Zone to = Zone(type: ZoneType.playerHand, holderId: pid);
      final fromDeckToHand = CardMoveEvent(
        id: _uuid.v4().substring(0, 8),
        from: from,
        to: to,
        card: card,
        performedBy: performedById,
      );
      events.add(fromDeckToHand);
    }
    return events;
  }

  static List<CardMoveEvent> generateDealToTableEvent(
    List<PlayingCardModel> cards,
    String performedById,
  ) {
    List<CardMoveEvent> events = [];
    for (var card in cards) {
      Zone from = Zone(
        type: ZoneType.gameDeck,
        holderId: ZoneType.gameDeck.name,
      );
      Zone to = Zone(type: ZoneType.table, holderId: ZoneType.table.name);
      final fromDeckToHand = CardMoveEvent(
        id: _uuid.v4().substring(0, 8),
        from: from,
        to: to,
        card: card,
        performedBy: performedById,
      );
      events.add(fromDeckToHand);
    }
    return events;
  }

  static List<CardMoveEvent> generateSettleEndRoundEvents(GameState gameState) {
    final lastTaker = gameState.lastTookCardId.trim();
    final playerIds = (gameState.playersInfo?.keys ?? <String>[])
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final receiverId = lastTaker.isNotEmpty
        ? lastTaker
        : (playerIds.isNotEmpty ? playerIds.first : '');

    if (receiverId.isEmpty) return [];

    final List<CardMoveEvent> events = [];

    final Zone table = Zone(
      type: ZoneType.table,
      holderId: ZoneType.table.name,
    );

    final Zone to = Zone(type: ZoneType.playerDeck, holderId: receiverId);

    for (final card in gameState.playingArea) {
      events.add(
        CardMoveEvent(
          id: _uuid.v4().substring(0, 8),
          from: table,
          to: to,
          card: card,
          performedBy: receiverId,
        ),
      );
    }

    for (final stack in gameState.playingAreaStacks) {
      for (final card in stack.cards) {
        events.add(
          CardMoveEvent(
            id: _uuid.v4().substring(0, 8),
            from: table,
            to: to,
            card: card,
            performedBy: receiverId,
          ),
        );
      }
    }

    return events;
  }
}
