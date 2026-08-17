import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

/// One visual slot on the table — either a loose card or a stack.
/// [tableOrder] on [GameState] stores these as `c:<id>` / `s:<id>`.
sealed class TableSlot {
  const TableSlot();
  String get orderKey;
  double widthFor({required double cardWidth, double overlap = 30});
}

class TableCardSlot extends TableSlot {
  final PlayingCardModel card;
  const TableCardSlot(this.card);
  @override
  String get orderKey => 'c:${card.id}';
  @override
  double widthFor({required double cardWidth, double overlap = 30}) => cardWidth;
}

class TableStackSlot extends TableSlot {
  final PlayingAreaStackModel stack;
  const TableStackSlot(this.stack);
  @override
  String get orderKey => 's:${stack.id}';
  @override
  double widthFor({required double cardWidth, double overlap = 30}) {
    if (stack.cards.isEmpty) return cardWidth;
    return cardWidth + (stack.cards.length - 1) * (cardWidth - overlap);
  }
}

abstract final class TableOrder {
  static String cardKey(String id) => 'c:$id';
  static String stackKey(String id) => 's:$id';

  static bool isCard(String key) => key.startsWith('c:');
  static bool isStack(String key) => key.startsWith('s:');
  static String idOf(String key) => key.length > 2 ? key.substring(2) : key;
}
