import 'package:youareup/models/game_state.dart';
import 'package:youareup/models/player.dart';
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

    test('completedGameTutorials json round-trips', () {
      final player = Player(
        id: 'p1',
        completedTutorial: true,
        completedGameTutorials: {GameMode.rummy, GameMode.bs},
      );
      final restored = Player.fromDto(player.toJson());
      expect(restored.completedGameTutorials, player.completedGameTutorials);
    });

    test('explicit tutorials are not overwritten by legacy flag', () {
      final player = Player.fromDto({
        'id': 'p1',
        'completedTutorial': true,
        'completedGameTutorials': ['rummy'],
      });
      expect(player.completedGameTutorials, {GameMode.rummy});
    });
  });
}
