import 'package:dominican_casino/game_control/game_engine/casino/casino_game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/tresydos/tres_dos_game_engine.dart';
import 'package:dominican_casino/models/game_state.dart';

/// Single factory for playable engines. Unknown / disabled modes return null.
class GameRegistry {
  GameRegistry._();

  static const Set<GameMode> playableModes = {
    GameMode.casino,
    GameMode.casinoSpeed,
    GameMode.tresydos,
  };

  static bool isPlayable(GameMode mode) => playableModes.contains(mode);

  /// Classic Casino and Casino Speed share capture rules / UI / coins.
  static bool isCasinoFamily(GameMode mode) =>
      mode == GameMode.casino || mode == GameMode.casinoSpeed;

  /// In-match label (top of board / status popup).
  static String displayTitle(GameMode mode) {
    switch (mode) {
      case GameMode.casino:
        return 'Casino: Classic';
      case GameMode.casinoSpeed:
        return 'Casino: Speed Mode';
      case GameMode.tresydos:
        return 'Tres y Dos';
      case GameMode.robaito:
        return 'Robaito';
    }
  }

  /// How a match is won — for game-over / status copy.
  static String winConditionPhrase(GameMode mode) {
    switch (mode) {
      case GameMode.casino:
        return 'reaching 21 across many rounds';
      case GameMode.casinoSpeed:
        return 'making the most points in a single round';
      case GameMode.tresydos:
        return 'winning 3 rounds';
      case GameMode.robaito:
        return 'collecting the most cards';
    }
  }

  static GameMode? modeFromRoute(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw) {
      case 'casino':
        return GameMode.casino;
      case 'casinoSpeed':
        return GameMode.casinoSpeed;
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
      case GameMode.casinoSpeed:
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
      case GameMode.casinoSpeed:
        return (4, 4, 4, 0);
      case GameMode.tresydos:
        return (5, 1, 0, 1);
      case GameMode.robaito:
        return (0, 0, 0, 0);
    }
  }
}
