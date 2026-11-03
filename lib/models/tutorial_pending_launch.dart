import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/wallet_config.dart';

/// Stashed game-creation params while the player is in a tutorial match.
class TutorialPendingLaunch {
  const TutorialPendingLaunch({
    required this.mode,
    required this.local,
    this.playerCount = 2,
    this.entryCost = WalletConfig.entryCost,
    this.turnDurationSeconds = WalletConfig.defaultSpeedTurnSeconds,
    this.afterTutorial = true,
    this.thenMatchmaking = false,
  });

  final GameMode mode;
  final bool local;
  final int playerCount;
  final int entryCost;
  final int turnDurationSeconds;
  final bool afterTutorial;
  final bool thenMatchmaking;
}
