import 'package:dominican_casino/game_control/game_engine/casino/casino_game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/tresydos/tres_dos_game_engine.dart';
import 'package:dominican_casino/models/game_state.dart';

/// Single factory for playable engines. Unknown / disabled modes return null.
class GameRegistry {
  GameRegistry._();

  static const Set<GameMode> playableModes = {
    GameMode.casino,
    GameMode.tresydos,
  };

  static bool isPlayable(GameMode mode) => playableModes.contains(mode);

  static GameMode? modeFromRoute(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw) {
      case 'casino':
        return GameMode.casino;
      case 'tresydos':
        return GameMode.tresydos;
      case 'robaito':
        return GameMode.robaito;
      default:
        return null;
    }
  }

  static GameEngine? createEngine(GameMode mode) {
    switch (mode) {
      case GameMode.casino:
        return CasinoGameEngine();
      case GameMode.tresydos:
        return TresDosGameEngine();
      case GameMode.robaito:
        return null;
    }
  }

  static GameEngine? createEngineFromRoute(String? raw) {
    final mode = modeFromRoute(raw);
    if (mode == null || !isPlayable(mode)) return null;
    return createEngine(mode);
  }

  /// Deal parameters: (cardsPerPlayer, table, redealPlayer, redealTable).
  static (int, int, int, int) dealCounts(GameMode mode) {
    switch (mode) {
      case GameMode.casino:
        return (4, 4, 4, 0);
      case GameMode.tresydos:
        return (5, 1, 0, 1);
      case GameMode.robaito:
        return (0, 0, 0, 0);
    }
  }
}
