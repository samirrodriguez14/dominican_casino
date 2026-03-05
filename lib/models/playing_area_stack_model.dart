import 'package:dominican_casino/models/playing_card_model.dart';

class PlayingAreaStackModel {
  final String id; // useful for UI keys / Firestore diffing
  final List<PlayingCardModel> cards;

  /// What this stack is “worth” / capped to (<= 14 for now).
  final int stackValue;

  /// Later you can support aceHigh/aceLow per-stack; for now keep false.
  final bool aceHigh;
  final bool paired;
  PlayingAreaStackModel({
    required this.id,
    required this.cards,
    required this.stackValue,
    this.aceHigh = false,
    this.paired = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'stackValue': stackValue,
    'aceHigh': aceHigh,
    'cards': cards.map((c) => c.toMap()).toList(),
    'paired': paired,
  };

  static PlayingAreaStackModel fromMap(Map<String, dynamic> m) {
    final rawCards = (m['cards'] as List?) ?? const [];
    return PlayingAreaStackModel(
      id: (m['id'] as String?) ?? '',
      stackValue: (m['stackValue'] as num?)?.toInt() ?? 0,
      aceHigh: (m['aceHigh'] as bool?) ?? false,
      cards: rawCards
          .map(
            (e) =>
                PlayingCardModel.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      paired: m['paired'] ?? false,
    );
  }
}
