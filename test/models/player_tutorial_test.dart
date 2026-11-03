import 'package:barajando/models/game_state.dart';
import 'package:barajando/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Player tutorial migration', () {
    test('legacy completedTutorial migrates to casino', () {
      final player = Player.fromDto({
        'id': 'p1',
        'completedTutorial': true,
      });
      expect(player.completedGameTutorials, {GameMode.casino});
      expect(player.completedTutorial, isTrue);
    });

    test('completedGameTutorials json round-trips for Sweep', () {
      final player = Player(
        id: 'p1',
        completedTutorial: true,
        completedGameTutorials: {GameMode.casino},
      );
      final restored = Player.fromDto(player.toJson());
      expect(restored.completedGameTutorials, {GameMode.casino});
    });

    test('non-Sweep tutorial ids fall back to legacy casino', () {
      final player = Player.fromDto({
        'id': 'p1',
        'completedTutorial': true,
        'completedGameTutorials': ['rummy', 'bs'],
      });
      // Non-Sweep ids are dropped; legacy flag migrates to Sweep.
      expect(player.completedGameTutorials, {GameMode.casino});
    });
  });
}
