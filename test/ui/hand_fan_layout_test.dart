import 'package:dominican_casino/ui/general_game/hand_fan_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HandFanLayout.fit', () {
    test('single card fits preferred width', () {
      final layout = HandFanLayout.fit(
        count: 1,
        maxWidth: 200,
        preferredCardWidth: 110,
      );
      expect(layout.cardWidth, 110);
      expect(layout.gap, 0);
      expect(layout.totalWidth(1), 110);
    });

    test('tightens gap before shrinking cards', () {
      final layout = HandFanLayout.fit(
        count: 5,
        maxWidth: 300,
        preferredCardWidth: 110,
        minGap: 12,
        maxGap: 56,
      );
      expect(layout.cardWidth, 110);
      expect(layout.gap, lessThan(56));
      expect(layout.visualFootprint(5), lessThanOrEqualTo(300 + 0.01));
    });

    test('gap shrinks as card count increases', () {
      const maxWidth = 360.0;
      final three = HandFanLayout.fit(
        count: 3,
        maxWidth: maxWidth,
        preferredCardWidth: 110,
        maxGap: 56,
        lockCardSize: true,
      );
      final seven = HandFanLayout.fit(
        count: 7,
        maxWidth: maxWidth,
        preferredCardWidth: 110,
        maxGap: 56,
        lockCardSize: true,
      );
      expect(seven.gap, lessThan(three.gap));
      expect(seven.visualFootprint(7), lessThanOrEqualTo(maxWidth + 0.01));
    });

    test('accounts for celebration scale in width budget', () {
      final normal = HandFanLayout.fit(
        count: 7,
        maxWidth: 400,
        preferredCardWidth: 110,
        minGap: 12,
        maxGap: 56,
        visualScale: 1.0,
        lockCardSize: true,
      );
      final celebrating = HandFanLayout.fit(
        count: 7,
        maxWidth: 400,
        preferredCardWidth: 110,
        maxGap: 64,
        visualScale: HandFanLayout.celebrationScale,
        lockCardSize: true,
      );
      expect(celebrating.gap, lessThan(normal.gap));
      expect(
        celebrating.visualFootprint(
          7,
          visualScale: HandFanLayout.celebrationScale,
        ),
        lessThanOrEqualTo(400 + 0.01),
      );
    });

    test('progressive tighten pulls gap in every other card', () {
      const maxWidth = 360.0;
      final four = HandFanLayout.fit(
        count: 4,
        maxWidth: maxWidth,
        preferredCardWidth: 110,
        maxGap: 56,
        lockCardSize: true,
        progressiveTighten: true,
        widthMargin: 1.0,
      );
      final five = HandFanLayout.fit(
        count: 5,
        maxWidth: maxWidth,
        preferredCardWidth: 110,
        maxGap: 56,
        lockCardSize: true,
        progressiveTighten: true,
        widthMargin: 1.0,
      );
      expect(five.gap, lessThan(four.gap));
    });

    test('lockCardSize keeps width and overlaps when needed', () {
      final layout = HandFanLayout.fit(
        count: 7,
        maxWidth: 175,
        preferredCardWidth: 110,
        maxGap: 56,
        lockCardSize: true,
      );
      expect(layout.cardWidth, 110);
      expect(layout.gap, lessThan(110));
      expect(layout.visualFootprint(7), lessThanOrEqualTo(175 + 0.01));
    });
  });

  group('HandFanLayout.indexAtLocalX', () {
    test('picks nearest card center when overlapping', () {
      const layout = HandFanLayout(cardWidth: 110, gap: 20);
      expect(layout.indexAtLocalX(10, 5), 0);
      expect(layout.indexAtLocalX(75, 5), 1);
      expect(layout.indexAtLocalX(115, 5), 3);
    });
  });
}
