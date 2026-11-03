import 'package:youareup/models/game_state.dart';
import 'package:youareup/models/tutorial_pending_launch.dart';
import 'package:youareup/models/tutorial_post_action.dart';
import 'package:youareup/models/wallet_config.dart';
import 'package:youareup/repositories/app_repo.dart';
import 'package:youareup/routing/game_routes.dart';
import 'package:youareup/ui/app_shell/games/game_mode_actions.dart';
import 'package:youareup/ui/app_shell/games/quick_play_dialog.dart';
import 'package:youareup/ui/app_shell/games/tutorial_game_picker_dialog.dart';
import 'package:youareup/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

void launchTutorialMatch(BuildContext context, GameMode mode) {
  final gid = const Uuid().v4().substring(0, 6);
  context.go(GameRoutes.game(gameId: gid, gameMode: mode.name, tutorial: true));
}

/// Landing Quick Match: picker → tutorial if needed → AI bot.
Future<void> runLandingQuickMatch(BuildContext context) async {
  final repo = context.read<AppRepo>();
  final mode = await showTutorialGamePickerDialog(context);
  if (!context.mounted || mode == null) return;

  if (repo.isGameTutorialDone(mode)) {
    await gameEnter(context, context.read<GamesViewModel>(), mode, true);
    return;
  }

  repo.setTutorialPendingLaunch(
    TutorialPendingLaunch(
      mode: mode,
      local: true,
      entryCost: WalletConfig.stakesFor(allowNoBet: true).first,
    ),
  );
  repo.setTutorialPostAction(TutorialPostAction.savedLaunch);
  launchTutorialMatch(context, mode);
}

/// Home Quick Play: tutorial-first path or restricted matchmaking.
Future<void> runHomeQuickPlay(BuildContext context) async {
  final repo = context.read<AppRepo>();
  if (!repo.hasAnyTutorialDone) {
    final mode = await showTutorialGamePickerDialog(context);
    if (!context.mounted || mode == null) return;
    repo.setTutorialPostAction(TutorialPostAction.matchmaking);
    launchTutorialMatch(context, mode);
    return;
  }
  if (!context.mounted) return;
  await showRestrictedQuickPlayDialog(context);
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
    await showRestrictedQuickPlayDialog(context);
  }
}
