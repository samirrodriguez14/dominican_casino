import 'package:barajando/models/game_state.dart';
import 'package:barajando/models/tutorial_post_action.dart';
import 'package:barajando/repositories/app_repo.dart';
import 'package:barajando/routing/game_routes.dart';
import 'package:barajando/ui/app_shell/games/game_mode_actions.dart';
import 'package:barajando/ui/app_shell/games/quick_play_dialog.dart';
import 'package:barajando/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

void launchTutorialMatch(BuildContext context, GameMode mode) {
  final gid = const Uuid().v4().substring(0, 6);
  context.go(GameRoutes.game(gameId: gid, gameMode: mode.name, tutorial: true));
}

/// Home Quick Play: Sweep tutorial-first, then unrestricted matchmaking.
Future<void> runHomeQuickPlay(BuildContext context) async {
  final repo = context.read<AppRepo>();
  if (!repo.hasAnyTutorialDone) {
    repo.setTutorialPostAction(TutorialPostAction.matchmaking);
    launchTutorialMatch(context, GameMode.casino);
    return;
  }
  if (!context.mounted) return;
  await showQuickPlayDialog(context);
}

/// After tutorial finish/skip — honor pending launch or post action.
Future<void> runTutorialPostCompletion(BuildContext context) async {
  if (!context.mounted) return;
  final repo = context.read<AppRepo>();
  final launch = repo.takeTutorialPendingLaunch();
  final post = repo.takeTutorialPostAction();
  final vm = context.read<GamesViewModel>();

  if (launch != null && launch.afterTutorial) {
    await gameEnter(
      context,
      vm,
      launch.mode,
      launch.local,
      playerCount: launch.playerCount,
      entryCost: launch.entryCost,
      turnDurationSeconds: launch.turnDurationSeconds,
    );
    return;
  }

  if (post == TutorialPostAction.matchmaking) {
    await showQuickPlayDialog(context);
  }
}
