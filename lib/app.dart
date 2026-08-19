import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/services/notifications_service.dart';
import 'package:dominican_casino/ui/app_shell/app_shell.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/general_game/general_game_screen.dart';
import 'package:dominican_casino/ui/home/home_screen.dart';
import 'package:dominican_casino/ui/home/instructions_screen.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_screen.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:dominican_casino/view_models/tutorial_view_model_base.dart';
import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _MyAppState();
}

class _MyAppState extends State<App> with WidgetsBindingObserver {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  StreamSubscription<RemoteMessage>? _fcmOpenedSub;
  late final GoRouter _router;

  bool _handledInitialLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
          path: '/tutorial',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => TutorialViewModelBase(context.read<AppRepo>()),
            child: const TutorialScreen(),
          ),
        ),
        GoRoute(
          path: '/join/:gameId/:gameMode',
          redirect: (context, state) {
            final gameId = state.pathParameters['gameId']!;
            final gameMode = state.pathParameters['gameMode']!;
            if (!GameRoutes.isValidGameId(gameId) ||
                GameRegistry.modeFromRoute(gameMode) == null ||
                !GameRegistry.isPlayable(
                  GameRegistry.modeFromRoute(gameMode)!,
                )) {
              return '/home';
            }
            return GameRoutes.game(gameId: gameId, gameMode: gameMode);
          },
        ),
        GoRoute(
          path: '/game/:gameId/:gameMode/:tutorialMode',
          builder: (context, state) {
            final gameId = state.pathParameters['gameId']!;
            final gameMode = state.pathParameters['gameMode']!;
            final tutorialMode = state.pathParameters['tutorialMode'];

            final player = context.read<AppRepo>().player;
            if (player == null) return const HomeScreen();

            final engine = GameRegistry.createEngineFromRoute(gameMode);
            if (engine == null || !GameRoutes.isValidGameId(gameId)) {
              return const HomeScreen();
            }

            return ChangeNotifierProvider(
              key: ValueKey('$gameId-$tutorialMode'),
              create: (_) => GeneralGameViewModel(
                gid: gameId,
                gameEngine: engine,
                player: player,
                gameRepo: context.read<GameRepo>(),
                appRepo: context.read<AppRepo>(),
                tutorialMode: tutorialMode == 'true',
              ),
              child: GeneralGameScreen(key: ValueKey('$gameId-$tutorialMode')),
            );
          },
        ),
      ],
    );

    _router.routerDelegate.addListener(_syncActiveGamePresence);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncActiveGamePresence();
    });

    _initDeepLinks();
    _initNotificationTaps();
  }

  /// Turn pushes are skipped while this device is looking at that match.
  /// Leaving, switching games, or backgrounding clears it so FCM still fires.
  void _syncActiveGamePresence() {
    if (!mounted) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final visible = lifecycle == null ||
        lifecycle == AppLifecycleState.resumed ||
        lifecycle == AppLifecycleState.inactive;
    final segments = _router.state.uri.pathSegments;
    String? gid;
    if (visible &&
        segments.length >= 2 &&
        segments.first == 'game' &&
        GameRoutes.isValidGameId(segments[1])) {
      gid = segments[1];
    }
    context.read<AppRepo>().setActiveGameId(gid);
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

  Future<void> _initNotificationTaps() async {
    _fcmOpenedSub = NotificationsService.instance.opened.listen(
      _openFromNotification,
    );
    await NotificationsService.instance.configure();
    if (!mounted) return;
    NotificationsService.instance.flushLaunchMessage();
  }

  Future<void> _openFromNotification(RemoteMessage message) async {
    final invite = GameRoutes.parseNotificationData(message.data);
    if (invite == null) return;

    final appRepo = context.read<AppRepo>();
    await appRepo.loadApp();
    if (!mounted) return;

    var gameMode = invite.gameMode;
    if (GameRegistry.modeFromRoute(gameMode) == null) {
      try {
        final game = await appRepo.fs.loadGame(invite.gameId);
        gameMode = gameModeTo(game.gameMode);
      } catch (e, st) {
        developer.log(
          'FCM: Failed to load game ${invite.gameId}',
          error: e,
          stackTrace: st,
        );
        return;
      }
    }
    await _openGame(gameId: invite.gameId, gameMode: gameMode);
  }

  void _handleIncomingUri(Uri uri) {
    developer.log('DeepLink: path segments: ${uri.pathSegments}');
    final invite = GameRoutes.parseInvite(uri);
    if (invite == null) {
      _router.go('/home');
      return;
    }
    unawaited(_openGame(gameId: invite.gameId, gameMode: invite.gameMode));
  }

  Future<void> _openGame({
    required String gameId,
    required String gameMode,
  }) async {
    final appRepo = context.read<AppRepo>();
    await appRepo.loadApp();
    if (!mounted) return;
    final mode = GameRegistry.modeFromRoute(gameMode);
    if (mode == null || !GameRegistry.isPlayable(mode)) {
      _router.go('/home');
      return;
    }
    if (appRepo.player == null) {
      _router.go('/home');
      return;
    }
    _router.go(GameRoutes.join(gameId: gameId, gameMode: gameMode));
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_syncActiveGamePresence);
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    _fcmOpenedSub?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final sounds = SoundService.instance;
    switch (state) {
      case AppLifecycleState.resumed:
        sounds.startMusic();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        sounds.pauseMusic();
        break;
    }
    _syncActiveGamePresence();
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
          locale: appRepo.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            if (child == null) return const SizedBox();
            AppStyle.theme = appRepo.selectedTheme;
            AppStyle.cardBack = appRepo.cardBack;
            AppStyle.cardBackMark = appRepo.cardBackMark;
            AppStyle.cardBackTintId = appRepo.cardBackTintId;
            AppStyle.cardBackAvatarId = appRepo.player?.avatarId;
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
