import 'package:dominican_casino/game_control/game_engine/bs/bs_game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/casino/casino_game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/tresydos/tres_dos_game_engine.dart';
import 'package:dominican_casino/models/game_state.dart';

/// Single factory for playable engines. Unknown / disabled modes return null.
class GameRegistry {
  GameRegistry._();

  static const Set<GameMode> playableModes = {
    GameMode.casino,
    GameMode.casinoSpeed,
    GameMode.tresydos,
    GameMode.rummy,
    GameMode.bs,
  };

  static bool isPlayable(GameMode mode) => playableModes.contains(mode);

  /// Classic Casino and Casino Speed share capture rules / UI / coins.
  static bool isCasinoFamily(GameMode mode) =>
      mode == GameMode.casino || mode == GameMode.casinoSpeed;

  /// Games that share the draw/discard turn loop.
  static bool isDrawDiscardFamily(GameMode mode) =>
      mode == GameMode.tresydos || mode == GameMode.rummy;

  /// In-match label (top of board / status popup).
  static String displayTitle(GameMode mode) {
    switch (mode) {
      case GameMode.casino:
        return 'Casino: Classic';
      case GameMode.casinoSpeed:
        return 'Casino: Speed Mode';
      case GameMode.tresydos:
        return 'Tres y Dos';
      case GameMode.rummy:
        return 'Rummy (Romir)';
      case GameMode.robaito:
        return 'Robaito';
      case GameMode.bs:
        return 'BS';
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
      case GameMode.rummy:
        return 'go-out on the contract in 1 round';
      case GameMode.robaito:
        return 'collecting the most cards';
      case GameMode.bs:
        return 'emptying your hand first';
    }
  }

  static GameMode? modeFromRoute(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    const prefix = 'GameMode.';
    final key = raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
    switch (key) {
      case 'casino':
        return GameMode.casino;
      case 'casinoSpeed':
        return GameMode.casinoSpeed;
      case 'tresydos':
        return GameMode.tresydos;
      case 'rummy':
        return GameMode.rummy;
      case 'robaito':
        return GameMode.robaito;
      case 'bs':
        return GameMode.bs;
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
      case GameMode.rummy:
        return RummyGameEngine();
      case GameMode.bs:
        return BsGameEngine();
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
  /// BS deals the full deck in its own handler — counts are unused.
  static (int, int, int, int) dealCounts(GameMode mode) {
    switch (mode) {
      case GameMode.casino:
      case GameMode.casinoSpeed:
        return (4, 4, 4, 0);
      case GameMode.tresydos:
        return (5, 1, 0, 1);
      case GameMode.rummy:
        return (7, 1, 0, 1);
      case GameMode.robaito:
      case GameMode.bs:
        return (0, 0, 0, 0);
    }
  }
}
