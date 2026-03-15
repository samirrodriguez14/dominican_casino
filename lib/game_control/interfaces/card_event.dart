import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

abstract class GameEvent {
  String id;
  String performedBy;
  String? description;
  GameEvent({required this.id, required this.performedBy});
}

class CardMoveEvent extends GameEvent {
  PlayingCardModel card;
  final Zone from;
  final Zone to;
  CardMoveEvent({
    required this.from,
    required this.to,
    required this.card,
    required super.performedBy,
    required super.id,
  });
  factory CardMoveEvent.fromDto(Map<String, dynamic> gameEventDto) {
    return CardMoveEvent(
      id: gameEventDto['id'],
      from: Zone.fromDto(gameEventDto['from']),
      to: Zone.fromDto(gameEventDto['to']),
      card: PlayingCardModel.fromMap(gameEventDto['card']),
      performedBy: gameEventDto['performedBy'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    "from": from.toJson(),
    "to": to.toJson(),
    "card": card.toMap(),
    "performedBy": super.performedBy,
  };
}
