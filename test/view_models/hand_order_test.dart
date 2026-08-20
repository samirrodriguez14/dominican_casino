import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/view_models/games/hand_order.dart';
import 'package:flutter_test/flutter_test.dart';

PlayingCardModel _c(String id) => PlayingCardModel(
  id: id,
  suit: 'H',
  rank: 'A',
);

void main() {
  group('applyPreferredHandOrder', () {
    test('keeps the remembered fan when a remote replace reshuffles ids', () {
      final incoming = [_c('3'), _c('1'), _c('2')];
      applyPreferredHandOrder(incoming, ['1', '2', '3']);
      expect(handOrderIds(incoming), ['1', '2', '3']);
    });

    test('drops cards that left the hand and appends newly drawn ones', () {
      final incoming = [_c('2'), _c('4'), _c('1')];
      applyPreferredHandOrder(incoming, ['1', '2', '3']);
      expect(handOrderIds(incoming), ['1', '2', '4']);
    });

    test('leaves a dealt hand alone when nothing from the old fan remains', () {
      final incoming = [_c('a'), _c('b'), _c('c')];
      applyPreferredHandOrder(incoming, ['1', '2', '3']);
      expect(handOrderIds(incoming), ['a', 'b', 'c']);
    });

    test('no-ops on an empty incoming hand', () {
      final incoming = <PlayingCardModel>[];
      applyPreferredHandOrder(incoming, ['1']);
      expect(incoming, isEmpty);
    });
  });
}
