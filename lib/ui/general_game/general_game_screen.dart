import 'dart:math' as math;

import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/style/layouts/casino_board.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/tutorial/tutorial_casino_steps.dart';
import 'package:dominican_casino/ui/animations/card_flight_animator.dart';
import 'package:dominican_casino/ui/animations/currency_burst.dart';
import 'package:dominican_casino/ui/animations/flight_layer.dart';
import 'package:dominican_casino/ui/animations/shuffle_animator.dart';
import 'package:dominican_casino/ui/app_shell/games/account_setup_popup.dart';
import 'package:dominican_casino/ui/general_game/areas/gen_player_area.dart';
import 'package:dominican_casino/ui/general_game/areas/new_tresydos_playing_area.dart';
import 'package:dominican_casino/ui/general_game/gen_game_control.dart';
import 'package:dominican_casino/ui/general_game/game_status_sheet.dart';
import 'package:dominican_casino/ui/general_game/simple/simple_casino_playing_area.dart';
import 'package:dominican_casino/ui/general_game/simple/simple_player_area.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_overlay.dart';
import 'package:dominican_casino/ui/widgets/coin_hint_ticker.dart';
import 'package:dominican_casino/ui/widgets/player_score_avatar.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
import 'package:dominican_casino/ui/widgets/popup_circle_button.dart';
import 'package:dominican_casino/ui/widgets/reaction_bubble.dart';
import 'package:dominican_casino/ui/widgets/wallet_dialogs.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:dominican_casino/view_models/tutorial_view_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GeneralGameScreen extends StatefulWidget {
  const GeneralGameScreen({super.key});

  @override
  State<GeneralGameScreen> createState() => GeneralGameScreenState();
}

class GeneralGameScreenState extends State<GeneralGameScreen>
    with TickerProviderStateMixin {
  GeneralGameViewModel get vm => context.read<GeneralGameViewModel>();
  GeneralGameViewModel? _boundVm;

  late final TutorialViewModel tutorialVm;
  final FlightLayerController _flightLayer = FlightLayerController();

  /// Prevents stacking duplicate round/game status popups.
  String? _shownStatusKey;
  bool _statusPopupOpen = false;
  bool _leavingTutorial = false;
  bool _playingDeckCoins = false;

  void _bindFlightRunner(GeneralGameViewModel gameVm) {
    gameVm.motion.flightLayer = _flightLayer;
    gameVm.motion.runner = (flights, {onLanded, onLaunched}) =>
        CardFlightAnimator.flyAll(
          layer: _flightLayer,
          vsync: this,
          flights: flights,
          onLanded: onLanded,
          onLaunched: onLaunched,
        );
    gameVm.motion.shuffleRunner = (request, {onSquared}) =>
        ShuffleAnimator.play(
          layer: _flightLayer,
          vsync: this,
          request: request,
          onSquared: onSquared,
        );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initvm = context.read<GeneralGameViewModel>();
      _bindFlightRunner(initvm);

      tutorialVm = TutorialViewModel(
        getCasinoTutorialSteps(
          deckKey: initvm.deckKey,
          tableKey: initvm.tableKey,
          handKey: initvm.myHandKey,
          myDeckKey: initvm.myDeckKey,
          oppDeckKey: initvm.oppDeckKey,
          playButtonKey: initvm.playButtonKey,
          addButtonKey: initvm.addButtonKey,
          takeStackButtonKey: initvm.takeStackButtonKey,
          scoreKey: initvm.scoreKey,
        ),
      );
      initvm.actionGuard = tutorialVm.tryProgress;
      initvm.tutorialAllowsOpponentPlay = () =>
          tutorialVm.active && tutorialVm.step.playOpponent;
      final ok = await initvm.loadGame();

      if (ok && mounted) {
        final join = await initvm.joinGame();
        if (join == JoinGameResult.notEnoughCoins) {
          if (!mounted) return;
          await showInsufficientFundsDialog(context, energy: false);
          if (mounted) context.go('/landing');
          return;
        }
        if (join != JoinGameResult.ok) {
          if (mounted) context.go('/home');
          return;
        }
        if (!initvm.tutorialMode) {
          initvm.gameRepo.listenToGame(initvm.gid);
          initvm.listenToReactions();
        }

        if (initvm.tutorialMode &&
            initvm.gameState.gameMode == GameMode.casino) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              tutorialVm.start();
            }
          });
        }

        return;
      }

      if (mounted) context.go('/home');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newVm = context.read<GeneralGameViewModel>();
    if (_boundVm != newVm) {
      _boundVm?.removeListener(_onVmChanged);
      _boundVm = newVm;
      _boundVm?.addListener(_onVmChanged);
      _bindFlightRunner(newVm);
    }
  }

  @override
  void dispose() {
    _boundVm?.removeListener(_onVmChanged);
    super.dispose();
  }

  void _onTutorialNext() {
    if (tutorialVm.isLastStep) return;
    tutorialVm.nextStep();
    if (tutorialVm.step.playOpponent) {
      vm.playTutorialOpponentIfNeeded();
    }
    if (tutorialVm.step.awaitRoundStatus) {
      _onVmChanged();
    }
  }

  void _onTutorialSkip(BuildContext context) {
    showAppPopup(
      context: context,
      title: 'Skip tutorial?',
      content: Text(
        'Go to the games lobby and set up your name when you are ready.',
        textAlign: TextAlign.center,
        style: AppStyle.theme.body,
      ),
      primaryText: 'Skip',
      onPrimary: _finishTutorialReturnHome,
      secondaryText: 'Stay',
      onSecondary: () {},
    );
  }

  Future<void> _finishTutorialReturnHome() async {
    _leavingTutorial = true;
    tutorialVm.finish();
    await context.read<AppRepo>().completeTutorial();
    if (!mounted) return;
    context.go('/landing');
  }

  Future<void> _finishTutorialPlayGame() async {
    _leavingTutorial = true;
    tutorialVm.finish();
    await context.read<AppRepo>().completeTutorial();
    if (!mounted) return;

    final player = context.read<AppRepo>().player;
    if (player != null && player.needsAccountSetup) {
      await showAccountSetupPopup(context);
      if (!mounted) return;
    }

    try {
      final gid = await context.read<GamesViewModel>().newGame(
        GameMode.casino,
        true,
      );
      if (!mounted) return;
      if (gid == null) {
        context.go('/landing');
        return;
      }
      context.go(GameRoutes.game(gameId: gid, gameMode: GameMode.casino.name));
    } catch (_) {
      if (mounted) context.go('/landing');
    }
  }

  void _onVmChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Wait until card flights finish (incl. leftover collect) before status UI.
      if (vm.isAnimating) return;
      if (_leavingTutorial) return;
      if (_playingDeckCoins) return;

      final coinFlight = vm.takeDeckCoinFlight();
      if (coinFlight != null) {
        _playingDeckCoins = true;
        await _playDeckCoinFlight(coinFlight);
        if (mounted) vm.revealPendingCoins();
        _playingDeckCoins = false;
        if (!mounted) return;
      }

      final gs = vm.gameState;
      final isGameOver = gs.gameStatus == GameStatus.gameOver;
      final isRoundDone =
          gs.gameStatus == GameStatus.inProgress &&
          gs.round.roundStatus == RoundStatus.completed;

      if (!isGameOver && !isRoundDone) return;

      final waitingForTutorialStatus =
          vm.tutorialMode &&
          tutorialVm.active &&
          tutorialVm.step.awaitRoundStatus;

      if (vm.tutorialMode && tutorialVm.active && !waitingForTutorialStatus) {
        return;
      }

      final key = isGameOver
          ? 'game_over_${gs.round.id}_${gs.winnerId}'
          : 'round_${gs.round.id}_completed';

      if (_statusPopupOpen || _shownStatusKey == key) return;
      _shownStatusKey = key;
      _statusPopupOpen = true;

      final tutorialContinue = waitingForTutorialStatus;

      showGameStatusPopup(
        context,
        vm: vm,
        showActions: false,
        title: isGameOver ? 'Game Over' : 'Round Complete',
        subtitle: GameRegistry.displayTitle(gs.gameMode),
        primaryText: 'Continue',
        barrierDismissible: false,
        revealLastRound: true,
        onPrimary: () {
          _statusPopupOpen = false;
          if (tutorialContinue) {
            tutorialVm.nextStep();
            return;
          }
          if (isGameOver) {
            _leaveToHome();
            return;
          }
          vm.continueAfterRound();
        },
      ).whenComplete(() {
        _statusPopupOpen = false;
      });
    });
  }

  Future<void> _leaveToHome() async {
    await vm.queueHomeCoinClaim();
    if (mounted) context.go('/landing');
  }

  Future<void> _playDeckCoinFlight(DeckCoinFlight flight) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    final fromKey = flight.mine ? vm.myDeckKey : vm.oppDeckKey;
    final toKey = flight.mine ? vm.scoreKey : vm.oppScoreKey;
    final from = CurrencyBar.centerOf(fromKey);
    final to = CurrencyBar.centerOf(toKey);
    if (from == null || to == null) return;
    await CurrencyBurst.play(
      context: context,
      from: from,
      to: to,
      icon: coinIcon,
      color: AppStyle.theme.turnHighlight,
      count: flight.amount,
      jump: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (vm.loading) {
      return CupertinoPageScaffold(
        child: SafeArea(
          // top: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(),
                Text("taking too long?"),
                CupertinoButton(
                  child: Text("Home"),
                  onPressed: SoundService.wrapTap(() {
                    context.go('/landing');
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final useSimpleLayout = GameRegistry.isPlayable(vm.gameState.gameMode);

    return SizedBox(
      width: MediaQuery.of(context).size.width.clamp(0, 600),
      child: CupertinoPageScaffold(
        child: DecoratedBox(
          decoration: AppStyle.theme.tableBackground(),
          child: CoinHintTickerScope(
            child: AnimatedBuilder(
              animation: tutorialVm,
              builder: (context, _) {
                final bottomInset = MediaQuery.paddingOf(context).bottom;
                return FlightLayer(
                  controller: _flightLayer,
                  child: Stack(
                    children: [
                      if (!useSimpleLayout)
                        Padding(
                          padding: EdgeInsetsGeometry.symmetric(vertical: 48),
                          child: CasinoBoard(child: Container()),
                        ),
                      Column(
                        children: [
                          SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                              child: Center(
                                child: _GameModeChip(
                                  label: GameRegistry.displayTitle(
                                    vm.gameState.gameMode,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: useSimpleLayout ? 16 : 30,
                              ),
                              child: _selectPlayingArea(vm.gameState.gameMode),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (useSimpleLayout) ...[
                            Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                const SimplePlayerArea(),
                                const GenGameControl(),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const _SimpleControlBar(),
                          ] else
                            const GenPlayerArea(),
                          SizedBox(height: 16 + bottomInset),
                        ],
                      ),
                      if (!useSimpleLayout) ...[
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          alignment: vm.showInGameControl
                              ? Alignment.center
                              : Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsetsGeometry.only(right: 18),
                            child: GenGameControl(),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16 + bottomInset,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              PopupCircleButton(
                                emphasized: true,
                                onPressed: () {
                                  AppHaptics.mediumImpact();
                                  vm.sortHandCards();
                                },
                                child: Transform.rotate(
                                  angle: math.pi / 2,
                                  child: Icon(
                                    CupertinoIcons.arrow_up_arrow_down,
                                    size: 22,
                                    color: AppStyle.theme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const _PlayerReactionButton(),
                              const SizedBox(height: 10),
                              PlayerScoreAvatar(
                                key: vm.scoreKey,
                                avatarId: vm.player.avatarId,
                                score: vm.gameState.scores[vm.me] ?? 0,
                                pendingCoins: vm.revealedPendingFor(vm.me),
                                onPressed: () {
                                  AppHaptics.mediumImpact();
                                  showGameStatusPopup(context, vm: vm);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      AnimatedBuilder(
                        animation: tutorialVm,
                        builder: (context, _) {
                          if (!tutorialVm.active ||
                              vm.isAnimating ||
                              tutorialVm.step.awaitRoundStatus) {
                            return const SizedBox.shrink();
                          }

                          return TutorialOverlay(
                            step: tutorialVm.currentStepData,
                            currentStep: tutorialVm.currentSection,
                            totalSteps: tutorialVm.totalSections,
                            isLastScreen: tutorialVm.isLastStep,
                            onNext: _onTutorialNext,
                            onSkip: () => _onTutorialSkip(context),
                            onPlay: _finishTutorialPlayGame,
                            onExit: _finishTutorialReturnHome,
                            canGoNext: true,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget? _selectPlayingArea(GameMode mode) {
    switch (mode) {
      case GameMode.tresydos:
        return NewTresydosPlayingArea();
      case GameMode.casino:
      case GameMode.casinoSpeed:
        return const SimpleCasinoPlayingArea();
      case GameMode.robaito:
    }
    return null;
  }
}

class _SimpleControlBar extends StatelessWidget {
  const _SimpleControlBar();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupCircleButton(
            emphasized: true,
            onPressed: () {
              AppHaptics.mediumImpact();
              vm.sortHandCards();
            },
            child: Transform.rotate(
              angle: math.pi / 2,
              child: Icon(
                CupertinoIcons.arrow_up_arrow_down,
                size: 22,
                color: AppStyle.theme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          PlayerScoreAvatar(
            key: vm.scoreKey,
            avatarId: vm.player.avatarId,
            score: vm.gameState.scores[vm.me] ?? 0,
            pendingCoins: vm.revealedPendingFor(vm.me),
            onPressed: () {
              AppHaptics.mediumImpact();
              showGameStatusPopup(context, vm: vm);
            },
          ),
          const SizedBox(width: 14),
          const _PlayerReactionButton(),
        ],
      ),
    );
  }
}

class _PlayerReactionButton extends StatefulWidget {
  const _PlayerReactionButton();

  @override
  State<_PlayerReactionButton> createState() => _PlayerReactionButtonState();
}

class _PlayerReactionButtonState extends State<_PlayerReactionButton> {
  bool _open = false;
  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  void _setOpen(bool open) {
    if (_open == open) return;
    setState(() => _open = open);
    if (open) {
      _overlay.show();
    } else {
      _overlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final outgoing = vm.outgoingReaction;
    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: (context) {
        return Align(
          alignment: Alignment.topLeft,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.bottomRight,
            offset: const Offset(0, -4),
            child: GameReactionPicker(
              onSelected: (emoji) {
                AppHaptics.lightImpact();
                _setOpen(false);
                vm.sendReaction(emoji);
              },
            ),
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              PopupCircleButton(
                icon: CupertinoIcons.smiley,
                emphasized: true,
                selected: _open,
                onPressed: () {
                  AppHaptics.lightImpact();
                  _setOpen(!_open);
                },
              ),
              if (!_open)
                Positioned(
                  left: -32,
                  right: -32,
                  bottom: 56,
                  child: Center(
                    child: IgnorePointer(
                      child: ReactionBubblePopup(
                        emoji: outgoing?.emoji,
                        reactionId: outgoing?.id,
                        tail: ReactionBubbleTail.bottom,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameModeChip extends StatelessWidget {
  const _GameModeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.border.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: theme.caption.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: theme.textPrimary.withValues(alpha: .9),
        ),
      ),
    );
  }
}
