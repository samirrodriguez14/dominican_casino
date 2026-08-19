import 'package:dominican_casino/routing/game_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRoutes.parseNotificationData', () {
    test('returns null for energy_full', () {
      final data = {
        'type': 'energy_full',
        'gid': 'ABCD',
        'gameMode': 'GameMode.casino',
      };
      expect(GameRoutes.parseNotificationData(data), isNull);
    });

    test('normalizes GameMode. prefix and accepts gid alias', () {
      final data = {
        'type': 'turn',
        'gid': 'ABCD',
        'gameMode': 'GameMode.casinoSpeed',
      };

      final result = GameRoutes.parseNotificationData(data);
      expect(result, isNotNull);
      expect(result!.gameId, 'ABCD');
      expect(result!.gameMode, 'casinoSpeed');
    });

    test('returns null for invalid game id', () {
      final data = {
        'type': 'turn',
        'gid': 'x',
        'gameMode': 'GameMode.casino',
      };
      expect(GameRoutes.parseNotificationData(data), isNull);
    });

    test('accepts gameId alias when gid is missing', () {
      final data = {
        'type': 'turn',
        'gameId': 'ABCD',
        'mode': 'casino',
      };
      final result = GameRoutes.parseNotificationData(data);
      expect(result, isNotNull);
      expect(result!.gameId, 'ABCD');
      expect(result!.gameMode, 'casino');
    });
  });
}

