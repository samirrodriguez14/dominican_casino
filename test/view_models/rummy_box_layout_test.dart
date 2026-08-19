import 'package:dominican_casino/view_models/games/rummy_box_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RummyBoxLayout', () {
    test('single card uses max width', () {
      final layout = RummyBoxLayout.forCount(1);
      expect(layout.cardWidth, RummyBoxLayout.maxCardWidth);
      expect(layout.gap, 0);
    });

    test('few cards stay large with comfortable gap', () {
      final layout = RummyBoxLayout.forCount(3);
      expect(layout.cardWidth, RummyBoxLayout.maxCardWidth);
      expect(layout.gap, greaterThanOrEqualTo(RummyBoxLayout.minGap));
    });

    test('many cards shrink and pack tighter', () {
      final layout = RummyBoxLayout.forCount(7);
      expect(layout.totalWidthFor(7), lessThanOrEqualTo(RummyBoxLayout.innerWidth + 0.5));
      expect(layout.gap, lessThanOrEqualTo(RummyBoxLayout.maxGap));
      expect(layout.cardWidth, lessThanOrEqualTo(RummyBoxLayout.maxCardWidth));
    });
  });
}
