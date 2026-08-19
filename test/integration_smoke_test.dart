import 'package:dominican_casino/routing/game_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GameRoutes.parseInvite parses dominicancasino://join deep links', () {
    final uri = Uri.parse('dominicancasino://join/ABCD/casino');
    final result = GameRoutes.parseInvite(uri);
    expect(result, isNotNull);
    expect(result!.gameId, 'ABCD');
    expect(result.gameMode, 'casino');
  });

  test('GameRoutes.game includes tutorial flag segment', () {
    expect(
      GameRoutes.game(gameId: 'ABCD', gameMode: 'casino', tutorial: false),
      '/game/ABCD/casino/false',
    );
    expect(
      GameRoutes.game(gameId: 'ABCD', gameMode: 'casino', tutorial: true),
      '/game/ABCD/casino/true',
    );
  });
}

