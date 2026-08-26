import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Queue home claims, resolve Journey challenge outcome if any, then go home.
Future<void> leaveMatchToHome(
  BuildContext context,
  GeneralGameViewModel vm,
) async {
  await vm.queueHomeCoinClaim();
  await vm.queueHomeDailyChallengeEnergyClaims();
  await vm.queueHomeXpClaim();
  if (!context.mounted) return;

  final repo = context.read<AppRepo>();
  final pending = repo.journeyProgress.pendingChallenge;
  final gid = vm.gid;
  if (pending != null &&
      (pending.gameId == null || pending.gameId == gid)) {
    final over = vm.gameState.gameStatus == GameStatus.gameOver;
    if (over) {
      final won =
          vm.gameState.winnerId != null &&
          vm.gameState.winnerId!.isNotEmpty &&
          vm.gameState.winnerId == vm.me;
      await repo.noteJourneyChallengeResult(won: won, gameId: gid);
    }
    // In-progress Journey matches keep [pendingChallenge] (with [gameId])
    // so returning to the same game can still record win/loss on leave.
  }

  if (!context.mounted) return;
  context.go('/landing');
}
