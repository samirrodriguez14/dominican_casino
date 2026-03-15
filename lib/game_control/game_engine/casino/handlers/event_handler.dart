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
        return generateAddTableCardsEvent(a);
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

  static List<CardMoveEvent> generateAddTableCardsEvent(AddTableCardsAction a) {
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
}
