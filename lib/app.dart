import 'dart:developer' as developer;

import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:dominican_casino/ui/home/home_screen.dart';
import 'package:dominican_casino/ui/home/instructions_screen.dart';
import 'package:dominican_casino/ui/lobby/lobby_screen.dart';
import 'package:dominican_casino/ui/game/game_screen.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/lobby_view_model.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appRepo = context.watch<AppRepo>();
    final router = GoRouter(
      initialLocation: '/home',

      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/instructions', builder: (context, state) => const InstructionsScreen()),
        GoRoute(
          path: '/lobby',
          builder: (context, state) {
            return ChangeNotifierProvider(
              create: (context) =>
                  LobbyViewModel(appRepo: context.read<AppRepo>()),

              child: LobbyScreen(),
            );
          },
        ),
        GoRoute(
          path: '/game:gameId',
          builder: (context, state) {
            // final gameId = state.pathParameters['gameId']!;

            return ChangeNotifierProvider(
              create: (context) => RoomViewModel(
                gameRepo: context.read<GameRepo>(),
                appRepo: context.read<AppRepo>(),
              ),
              child: GameScreen(),
            );
          },
        ),
      ],
      redirect: (context, state) {
        String loc = state.matchedLocation;
        developer.log("AppState ${appRepo.appStatus}. going: $loc");

        try {
          if (appRepo.appStatus == AppStatus.inGame) {
            return '/game:${appRepo.currentGameId}';
          }
        } catch (e) {
          appRepo.appStatus = AppStatus.notReady;
          return '/home';
        }
        return null;
      },
    );
    return CupertinoApp.router(
      title: 'Dominican Casino',
      routerConfig: router,
      theme: buildCupertinoTheme(),
      builder: (context, child) {
        if (child == null) return const SizedBox();

        return Material(
          color: AppStyle.theme.background,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
