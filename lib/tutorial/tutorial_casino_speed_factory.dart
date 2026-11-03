import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/tutorial/tutorial_casino_factory.dart';
import 'package:dominican_casino/models/game_state.dart';

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
