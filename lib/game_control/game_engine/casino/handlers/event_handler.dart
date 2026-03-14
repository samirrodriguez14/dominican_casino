import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

class EventHandler {
  
  static List<CardMoveEvent> generatePlayEvents(PlayCardAction a) {
    Zone from = Zone(type: ZoneType.playerHand, holderId: a.performedById);
    Zone to = Zone(type: ZoneType.table, holderId: ZoneType.table.name);
    final fromHandtoTable = CardMoveEvent(
      from: from,
      to: to,
      card: a.usedCard,
      performedBy: a.performedById,
    );
    return [fromHandtoTable];
  }

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
      Zone to = Zone(type: ZoneType.playerDeck, holderId: pid);
      final fromDeckToHand = CardMoveEvent(
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
