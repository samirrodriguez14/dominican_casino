import 'package:dominican_casino/game_control/game_engine/casino/casino_game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/tresydos/tres_dos_game_engine.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GameRegistry creates correct engines for playable modes', () {
    expect(
      GameRegistry.createEngineFromRoute('casino')?.runtimeType,
      CasinoGameEngine().runtimeType,
    );
    expect(
      GameRegistry.createEngineFromRoute('casinoSpeed')?.runtimeType,
      CasinoGameEngine().runtimeType,
    );
    expect(
      GameRegistry.createEngineFromRoute('tresydos')?.runtimeType,
      TresDosGameEngine().runtimeType,
    );

    // Unknown / disabled modes must fail closed.
    expect(GameRegistry.createEngineFromRoute('robaito'), isNull);
  });

  test('GameRegistry.dealCounts uses mode-specific parameters', () {
    expect(GameRegistry.dealCounts(GameMode.casino), (4, 4, 4, 0));
    expect(GameRegistry.dealCounts(GameMode.casinoSpeed), (4, 4, 4, 0));
    expect(GameRegistry.dealCounts(GameMode.tresydos), (5, 1, 0, 1));
    expect(GameRegistry.dealCounts(GameMode.rummy), (7, 1, 0, 1));
  });

  test('maxSeatsFor allows 2-4 at Tres y Dos and Rummy', () {
    expect(maxSeatsFor(GameMode.tresydos), 4);
    expect(maxSeatsFor(GameMode.rummy), 4);
    expect(maxSeatsFor(GameMode.casino), 2);
  });
}
