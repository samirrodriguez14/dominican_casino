import 'dart:async';
import 'dart:developer' as developer;

import 'package:barajando/models/game_state.dart';
import 'package:barajando/models/wallet_config.dart';
import 'package:barajando/repositories/app_repo.dart';
import 'package:barajando/routing/game_routes.dart';
import 'package:barajando/store_shots/store_shot_flags.dart';
import 'package:barajando/view_models/games_view_model.dart';
import 'package:barajando/view_models/home_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Drives the App Store screenshot storyboard.
///
/// Prints `STORE_SHOT:<id>` when each screen is ready for `simctl` capture.
/// Only runs when launched via `lib/main_store_shots.dart`.
/// Pair with [tool/capture_store_screenshots.sh].
class StoreShotTour {
  StoreShotTour._();

  static bool _started = false;

  static Future<void> maybeStart(BuildContext context, GoRouter router) async {
    // Never auto-drive the normal app — leftover dart-defines used to leave
    // this on and spawn Sweep / Tres y Dos / Rummy vs Pulilo after login.
    if (!kStoreScreenshots || _started) return;
    _started = true;
    // Let first frame + Firebase settle, then run.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!context.mounted) return;
    try {
      await _run(context, router);
    } catch (e, st) {
      developer.log('StoreShotTour failed: $e', stackTrace: st);
      // ignore: avoid_print
      print('STORE_SHOT:ERROR $e');
    }
  }

  static Future<void> _hold(String id, {int seconds = 4}) async {
    // ignore: avoid_print
    print('STORE_SHOT:$id');
    await Future<void>.delayed(Duration(seconds: seconds));
  }

  static Future<void> _run(BuildContext context, GoRouter router) async {
    final repo = context.read<AppRepo>();
    final home = context.read<HomeViewModel>();
    final games = context.read<GamesViewModel>();

    await repo.loadApp();
    if (!context.mounted) return;

    // Seed a clean demo identity and skip first-run popups.
    await home.updatePlayerName('Alex');
    for (final mode in GameMode.values) {
      if (mode == GameMode.robaito) continue;
      await repo.completeGameTutorial(mode);
    }
    if (!context.mounted) return;

    router.go('/landing');
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!context.mounted) return;

    // 01 Games hub
    repo.requestShellTab(1);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await _hold('01-games');

    // 02 Sweep table
    await _openLocalGame(context, router, games, GameMode.casino);
    await _hold('02-sweep', seconds: 5);
    if (!context.mounted) return;
    router.go('/landing');
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // 03 Tres y Dos
    await _openLocalGame(context, router, games, GameMode.tresydos);
    await _hold('03-tresydos', seconds: 5);
    if (!context.mounted) return;
    router.go('/landing');
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // 04 Rummy
    await _openLocalGame(context, router, games, GameMode.rummy);
    await _hold('04-rummy', seconds: 5);
    if (!context.mounted) return;
    router.go('/landing');
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // 05 Journey
    if (!context.mounted) return;
    repo.requestShellTab(1);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    repo.requestOpenJourney();
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    await _hold('05-journey', seconds: 5);

    // 06 Profile
    if (!context.mounted) return;
    repo.requestShellTab(2);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await _hold('06-profile', seconds: 5);

    // ignore: avoid_print
    print('STORE_SHOT:DONE');
  }

  static Future<void> _openLocalGame(
    BuildContext context,
    GoRouter router,
    GamesViewModel games,
    GameMode mode,
  ) async {
    final gid = await games.newGame(
      mode,
      true,
      playerCount: 2,
      entryCost: 0,
      turnDurationSeconds: WalletConfig.defaultSpeedTurnSeconds,
    );
    if (gid == null || !context.mounted) {
      // ignore: avoid_print
      print('STORE_SHOT:WARN could not start $mode');
      return;
    }
    router.go(GameRoutes.game(gameId: gid, gameMode: mode.name));
    await Future<void>.delayed(const Duration(milliseconds: 1600));
  }
}
