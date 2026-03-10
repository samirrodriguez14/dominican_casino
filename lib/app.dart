import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:dominican_casino/ui/app_shell/app_shell.dart';
import 'package:dominican_casino/ui/game/game_screen.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/home/home_screen.dart';
import 'package:dominican_casino/ui/home/instructions_screen.dart';
import 'package:dominican_casino/ui/lobby/lobby_screen.dart';
import 'package:dominican_casino/view_models/games/game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _MyAppState();
}

class _MyAppState extends State<App> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  late final GoRouter _router;

  bool _handledInitialLink = false;

  @override
  void initState() {
    super.initState();

    _appLinks = AppLinks();

    _router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
        GoRoute(
          path: '/landing',
          builder: (context, state) => const AppShell(),
        ),

        GoRoute(
          path: '/instructions',
          builder: (context, state) => const InstructionsScreen(),
        ),
        GoRoute(
          path: '/lobby',
          builder: (context, state) => const LobbyScreen(),
        ),

        // GoRoute(
        //   path: '/tresydos',
        //   builder: (context, state) => const TresyDosScreen(),
        // ),
        GoRoute(
          path: '/join/:gameId',
          redirect: (context, state) async {
            final gameId = state.pathParameters['gameId']!;
            return '/game/$gameId';
          },
        ),

        GoRoute(
          path: '/game/:gameId',
          builder: (context, state) {
            final gameId = state.pathParameters['gameId']!;
            final player = context.read<AppRepo>().player;
            if (player == null) return HomeScreen();
            return ChangeNotifierProvider(
              create: (_) => GameViewModel(
                gid: gameId,
                player: player,
                // pid: player.id,
                gameRepo: context.read<GameRepo>(),
              ),
              child: GameScreen(),
            );
          },
        ),
      ],
    );

    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (!_handledInitialLink && initialUri != null) {
        _handledInitialLink = true;
        developer.log('DeepLink: Initial app link: $initialUri');
        _handleIncomingUri(initialUri);
      }
    } catch (e, st) {
      developer.log(
        'DeepLink: Failed to read initial app link',
        error: e,
        stackTrace: st,
      );
    }

    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) {
        developer.log('DeepLink: Incoming app link stream: $uri');
        _handleIncomingUri(uri);
      },
      onError: (Object err, StackTrace st) {
        developer.log(
          'DeepLink: App link stream error',
          error: err,
          stackTrace: st,
        );
      },
    );
  }

  void _handleIncomingUri(Uri uri) {
    final segments = uri.pathSegments;
    developer.log('DeepLink: path segments: $segments');

    if (segments.isEmpty) return;

    if (segments.first == 'join' && segments.length >= 2) {
      final gameId = segments[1];
      _router.go('/join/$gameId');
      return;
    }

    if (segments.first == 'game' && segments.length >= 2) {
      final gameId = segments[1];
      _router.go('/join/$gameId');
      return;
    }
    _router.go('/home');
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppRepo appRepo = context.read<AppRepo>();

    return ListenableBuilder(
      listenable: appRepo,
      builder: (context, _) {
        return CupertinoApp.router(
          title: 'Dominican Casino',
          routerConfig: _router,
          theme: buildCupertinoTheme(appRepo.selectedTheme),
          builder: (context, child) {
            if (child == null) return const SizedBox();
            AppStyle.theme = appRepo.selectedTheme;
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
      },
    );
  }
}
