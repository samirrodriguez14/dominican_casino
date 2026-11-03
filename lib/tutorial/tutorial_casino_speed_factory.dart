import 'package:youareup/models/wallet_config.dart';
import 'package:youareup/tutorial/tutorial_casino_factory.dart';
import 'package:youareup/models/game_state.dart';

class TutorialCasinoSpeedFactory {
  static GameState createBasicTakeTutorial({
    required String gid,
    required String playerId,
  }) {
    return TutorialCasinoFactory.createBasicTakeTutorial(
      gid: gid,
      playerId: playerId,
      gameMode: GameMode.casinoSpeed,
      turnDurationSeconds: WalletConfig.defaultSpeedTurnSeconds,
    );
  }
}
