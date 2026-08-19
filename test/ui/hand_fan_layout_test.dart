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
      expect(layout.totalWidth(5), lessThanOrEqualTo(300));
    });

    test('accounts for celebration scale in width budget', () {
      final normal = HandFanLayout.fit(
        count: 7,
        maxWidth: 400,
        preferredCardWidth: 110,
        minGap: 12,
        maxGap: 56,
        visualScale: 1.0,
      );
      final celebrating = HandFanLayout.fit(
        count: 7,
        maxWidth: 400,
        preferredCardWidth: 110,
        minGap: 12,
        maxGap: 64,
        visualScale: HandFanLayout.celebrationScale,
      );
      expect(celebrating.gap, lessThan(normal.gap));
      final footprint = celebrating.cardWidth * HandFanLayout.celebrationScale +
          (7 - 1) * celebrating.gap;
      expect(footprint, lessThanOrEqualTo(400 + 0.01));
    });
  });
}
