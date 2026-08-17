import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/style/layouts/casino_board.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/tutorial/tutorial_casino_steps.dart';
import 'package:dominican_casino/ui/animations/card_flight_animator.dart';
import 'package:dominican_casino/ui/animations/shuffle_animator.dart';
import 'package:dominican_casino/ui/app_shell/games/account_setup_popup.dart';
import 'package:dominican_casino/ui/general_game/areas/new_casino_playing_area.dart';
import 'package:dominican_casino/ui/general_game/areas/gen_player_area.dart';
import 'package:dominican_casino/ui/general_game/areas/new_tresydos_playing_area.dart';
import 'package:dominican_casino/ui/general_game/game_info_sheet.dart';
import 'package:dominican_casino/ui/general_game/gen_game_control.dart';
import 'package:dominican_casino/ui/general_game/game_status_sheet.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_overlay.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:dominican_casino/view_models/tutorial_view_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Prevents stacking duplicate round/game status popups.
  String? _shownStatusKey;
  bool _statusPopupOpen = false;
  bool _leavingTutorial = false;

  void _bindFlightRunner(GeneralGameViewModel gameVm) {
    gameVm.motion.runner = (flights, {onLanded}) => CardFlightAnimator.flyAll(
      context: context,
      vsync: this,
      flights: flights,
      onLanded: onLanded,
    );
    gameVm.motion.shuffleRunner = (request, {onSquared}) => ShuffleAnimator.play(
      context: context,
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
        await initvm.joinGame();
        if (!initvm.tutorialMode) {
          initvm.gameRepo.listenToGame(initvm.gid);
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
  }

  void _onVmChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Wait until card flights finish (incl. leftover collect) before status UI.
      if (vm.isAnimating) return;
      if (_leavingTutorial) return;

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

      showAppPopup(
        context: context,
        title: isGameOver ? 'Game Over' : 'Round Complete',
        content: GameStatusSheet(vm: vm),
        primaryText: 'Continue',
        barrierDismissible: false,
        onPrimary: () {
          _statusPopupOpen = false;
          if (tutorialContinue) {
            tutorialVm.nextStep();
            return;
          }
          vm.continueAfterRound();
        },
      ).whenComplete(() {
        _statusPopupOpen = false;
      });
    });
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
                  onPressed: () {
                    context.go('/landing');
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width.clamp(0, 600),
      child: CupertinoPageScaffold(
        child: DecoratedBox(
          decoration: AppStyle.theme.tableBackground(),
          child: AnimatedBuilder(
            animation: tutorialVm,
            builder: (context, _) {
              return Stack(
                children: [
                  Padding(
                    padding: EdgeInsetsGeometry.symmetric(vertical: 48),
                    child: CasinoBoard(child: Container()),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 40),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: _selectPlayingArea(vm.gameState.gameMode),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GenPlayerArea(),
                      const SizedBox(height: 10),

                      _buildGameTopBar(context, vm),
                      const SizedBox(height: 24),
                    ],
                  ),
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
                  AnimatedBuilder(
                    animation: tutorialVm,
                    builder: (_, __) {
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
              );
            },
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
        return NewCasinoPlayingArea();
      case GameMode.robaito:
    }
    return null;
  }

  Widget _buildGameTopBar(BuildContext context, GeneralGameViewModel vm) {
    return Row(
      mainAxisAlignment: .center,
      spacing: 10,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            vm.sortHandCards();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: AppStyle.theme.raisedSurfaceBox(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Center: Joined As
                Icon(
                  CupertinoIcons.arrow_up_arrow_down,
                  color: AppStyle.theme.cardBorder,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            showAppPopup(
              context: context,
              title: "Game Info",
              content: GameInfoSheet(vm: vm),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: AppStyle.theme.raisedSurfaceBox(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Center: Joined As
                Icon(
                  CupertinoIcons.info,
                  color: AppStyle.theme.cardBorder,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            showAppPopup(
              context: context,
              title: "Game Status",
              content: GameStatusSheet(vm: vm),
            );
          },
          child: Container(
            key: vm.scoreKey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: AppStyle.theme.raisedSurfaceBox(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(
                  Icons.keyboard_control_key_sharp,
                  color: AppStyle.theme.cardBorder,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
