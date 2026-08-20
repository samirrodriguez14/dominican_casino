import 'dart:math' as math;
import 'dart:async';

import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/local_player/casino_player.dart';
import 'package:dominican_casino/local_player/tresdos_player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/style/layouts/casino_board.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/tutorial/tutorial_casino_steps.dart';
import 'package:dominican_casino/ui/animations/card_flight_animator.dart';
import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:dominican_casino/ui/animations/currency_burst.dart';
import 'package:dominican_casino/ui/animations/flight_layer.dart';
import 'package:dominican_casino/ui/animations/shuffle_animator.dart';
import 'package:dominican_casino/ui/app_shell/games/account_setup_popup.dart';
import 'package:dominican_casino/ui/general_game/areas/gen_player_area.dart';
import 'package:dominican_casino/ui/general_game/areas/new_tresydos_playing_area.dart';
import 'package:dominican_casino/ui/general_game/areas/rummy_playing_area.dart';
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
import 'package:dominican_casino/ui/widgets/win_confetti_overlay.dart';
import 'package:dominican_casino/ui/widgets/wallet_dialogs.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:dominican_casino/view_models/tutorial_view_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GeneralGameScreen extends StatefulWidget {
  const GeneralGameScreen({super.key});

  @override
  State<GeneralGameScreen> createState() => GeneralGameScreenState();
}

enum _SkipTutorialChoice { stay, home, play }

class GeneralGameScreenState extends State<GeneralGameScreen>
    with TickerProviderStateMixin {
  GeneralGameViewModel get vm => context.read<GeneralGameViewModel>();
  GeneralGameViewModel? _boundVm;

  late final TutorialViewModel tutorialVm;
  final FlightLayerController _flightLayer = FlightLayerController();
  late final FlightTickerBag _flightTickers = FlightTickerBag(this);

  /// Prevents stacking duplicate round/game status popups.
  String? _shownStatusKey;
  bool _statusPopupOpen = false;
  bool _leavingTutorial = false;
  bool _playingDeckCoins = false;

  // Idle hints (after tutorial): if the player does nothing for 5–8 seconds,
  // highlight a suggested legal move.
  Timer? _idleHintTimer;
  int _idleHintToken = 0;
  final math.Random _idleHintRng = math.Random();
  int _idleHintRoundId = -1;
  String _idleHintTurnPid = '';

  void _bindFlightRunner(GeneralGameViewModel gameVm) {
    gameVm.motion.flightLayer = _flightLayer;
    gameVm.motion.runner = (flights, {onLanded, onLaunched}) =>
        CardFlightAnimator.flyAll(
          layer: _flightLayer,
          tickers: _flightTickers,
          flights: flights,
          onLanded: onLanded,
          onLaunched: onLaunched,
        );
    gameVm.motion.shuffleRunner = (request, {onFlyersAttached, onHidden, onSquared}) =>
        ShuffleAnimator.play(
          layer: _flightLayer,
          tickers: _flightTickers,
          request: request,
          onFlyersAttached: onFlyersAttached,
          onHidden: onHidden,
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
          l10n: AppLocalizations.of(context),
          tableContentKey: initvm.tableContentKey,
          myDeckKey: initvm.myDeckKey,
          addButtonKey: initvm.addButtonKey,
          takeStackButtonKey: initvm.takeStackButtonKey,
          handCardKey: (id) => initvm.keyForCard(id, CardSlot.myHand),
          tableCardKey: (id) {
            final table = initvm.keyForCard(id, CardSlot.table);
            if (table.currentContext != null) return table;
            return initvm.keyForCard(id, CardSlot.inStack);
          },
          firstStackKey: () {
            final stacks = initvm.gameState.playingAreaStacks;
            if (stacks.isEmpty) return null;
            return initvm.keyForStack(stacks.first.id);
          },
        ),
      );
      initvm.actionGuard = tutorialVm.tryProgress;
      initvm.tutorialAllowsOpponentPlay = () =>
          tutorialVm.active && tutorialVm.step.playOpponent;
      initvm.tutorialAllowsDrag = tutorialVm.allowsDrag;
      final ok = await initvm.loadGame();

      if (ok && mounted) {
        final join = await initvm.joinGame();
        if (join == JoinGameResult.notEnoughCoins) {
          if (!mounted) return;
          await showInsufficientFundsDialog(context, energy: false);
          if (mounted) context.go('/landing');
          return;
        }
        if (join == JoinGameResult.notEnoughEnergy) {
          if (!mounted) return;
          await showInsufficientFundsDialog(context, energy: true);
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
    _boundVm?.motion.runner = null;
    _boundVm?.motion.shuffleRunner = null;
    _flightTickers.cancel();
    _idleHintTimer?.cancel();
    _idleHintTimer = null;
    tutorialVm.clearIdleHint();
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

  Future<void> _onTutorialSkip(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final choice = await showAppCenterPopup<_SkipTutorialChoice>(
      context: context,
      builder: (dialogContext) {
        return Container(
          width: 300,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.border.withValues(alpha: .7)),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: .45),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.skipTutorialTitle,
                textAlign: TextAlign.center,
                style: theme.title.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.skipTutorialBody,
                textAlign: TextAlign.center,
                style: theme.body.copyWith(height: 1.4),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: theme.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: SoundService.wrapTap(() {
                    Navigator.pop(dialogContext, _SkipTutorialChoice.play);
                  }),
                  child: Text(
                    l10n.play,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: SoundService.wrapTap(() {
                    Navigator.pop(dialogContext, _SkipTutorialChoice.home);
                  }),
                  child: Text(
                    l10n.home,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.only(top: 4),
                onPressed: SoundService.wrapTap(
                  () => Navigator.pop(dialogContext, _SkipTutorialChoice.stay),
                ),
                child: Text(l10n.stay, style: TextStyle(color: theme.muted)),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    switch (choice) {
      case _SkipTutorialChoice.play:
        await _finishTutorialPlayGame();
      case _SkipTutorialChoice.home:
        await _finishTutorialReturnHome();
      case _SkipTutorialChoice.stay:
      case null:
        break;
    }
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
      if (vm.isAnimating) {
        _cancelIdleHintTimer(clearHint: true);
        return;
      }
      if (_leavingTutorial) {
        _cancelIdleHintTimer(clearHint: true);
        return;
      }
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

      _maybeUpdateIdleHint();

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

      // Hold the winning beat until the celebration timer expires.
      if (vm.winCelebrationSecondsLeft > 0) {
        return;
      }

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

  bool _userIsInteracting(GeneralGameViewModel vm) {
    if (vm.isAnimating) return true;
    if (vm.motion.isShuffling) return true;
    if (vm.isBoardDragging) return true;
    if (vm.hasDropPending) return true;
    if (vm.draggingSource != null) return true;
    if (vm.selectedCard != null) return true;
    if (vm.selectedCards.isNotEmpty) return true;
    if (vm.selectedStacks.isNotEmpty) return true;
    return false;
  }

  void _cancelIdleHintTimer({bool clearHint = true}) {
    _idleHintTimer?.cancel();
    _idleHintTimer = null;
    _idleHintToken++;
    _idleHintRoundId = -1;
    _idleHintTurnPid = '';
    if (clearHint) {
      tutorialVm.clearIdleHint();
    }
  }

  bool _idleHintsEnabledForMode(GameMode mode) =>
      mode == GameMode.casino ||
      mode == GameMode.casinoSpeed ||
      mode == GameMode.tresydos;

  void _maybeUpdateIdleHint() {
    if (!mounted) return;

    // Only after the guided tutorial finishes.
    if (tutorialVm.active) {
      _cancelIdleHintTimer(clearHint: true);
      return;
    }

    // Clear when not in a live casino round.
    final gs = vm.gameState;
    if (gs.gameStatus != GameStatus.inProgress ||
        gs.round.roundStatus != RoundStatus.playing ||
        !_idleHintsEnabledForMode(gs.gameMode)) {
      _cancelIdleHintTimer(clearHint: true);
      return;
    }

    // Only on your turn, and only when it is safe to highlight (no dragging /
    // no deal/shuffle animations).
    if (!vm.isMyTurn || !vm.canPlayTurn) {
      _cancelIdleHintTimer(clearHint: true);
      return;
    }

    if (_userIsInteracting(vm)) {
      _cancelIdleHintTimer(clearHint: true);
      return;
    }

    // If a hint is already on screen, keep it until the next interaction
    // (or the turn changes).
    if (tutorialVm.idleHintActive || _idleHintTimer != null) return;

    final delay = Duration(seconds: 5 + _idleHintRng.nextInt(4)); // 5–8
    _idleHintRoundId = gs.round.id;
    _idleHintTurnPid = gs.currentTurnPlayerId ?? '';
    final token = ++_idleHintToken;

    _idleHintTimer = Timer(delay, () async {
      // Timer has fired; allow future idle-hint scheduling later in the
      // game (after we clear the current hint).
      _idleHintTimer = null;
      if (!mounted) return;
      if (_idleHintToken != token) return;

      final currentVm = context.read<GeneralGameViewModel>();
      final curGs = currentVm.gameState;
      if (currentVm.isAnimating ||
          currentVm.motion.isShuffling ||
          currentVm.selectedCard != null ||
          currentVm.selectedCards.isNotEmpty ||
          currentVm.selectedStacks.isNotEmpty) {
        return;
      }
      if (tutorialVm.active) return;
      if (curGs.gameStatus != GameStatus.inProgress ||
          curGs.round.roundStatus != RoundStatus.playing ||
          !_idleHintsEnabledForMode(curGs.gameMode)) {
        return;
      }
      if (!currentVm.isMyTurn || !currentVm.canPlayTurn) return;
      if (curGs.round.id != _idleHintRoundId) return;
      if ((curGs.currentTurnPlayerId ?? '') != _idleHintTurnPid) return;
      if (_userIsInteracting(currentVm)) return;

      final best = switch (curGs.gameMode) {
        GameMode.tresydos =>
          await TresdosPlayer.tresdosBestAction(
            currentVm.me,
            currentVm.gameState,
          ),
        _ => await CasinoPlayer.casinoBestAction(
          currentVm.me,
          currentVm.gameState,
        ),
      };

      if (!mounted) return;
      if (_idleHintToken != token) return;
      if (tutorialVm.active) return;

      final action = best.playAction;
      final hint = _idleHintForPlayAction(currentVm, action);
      if (hint == null) return;

      tutorialVm.setIdleHint(
        message: hint.message,
        cardIds: hint.cardIds,
        stackIds: hint.stackIds,
        keys: hint.keys,
      );
    });
  }

  ({
    String message,
    Set<String> cardIds,
    Set<String> stackIds,
    Set<GlobalKey> keys,
  })?
      _idleHintForPlayAction(GeneralGameViewModel vm, PlayAction action) {
    Set<String> cardIds = const {};
    Set<String> stackIds = const {};
    final keys = <GlobalKey>{};

    int sumOf(Iterable<PlayingCardModel> cards) =>
        cards.fold(0, (acc, c) => acc + c.valueHigh);

    switch (action) {
      case PlayCardAction(:final usedCard):
        cardIds = {usedCard.id};
        if (vm.gameState.gameMode != GameMode.tresydos) {
          keys.add(vm.playButtonKey);
        }
        return (
          message: vm.gameState.gameMode == GameMode.tresydos
              ? 'Hint: play ${usedCard.rank} card.'
              : 'Hint: play ${usedCard.rank}.',
          cardIds: cardIds,
          stackIds: stackIds,
          keys: keys,
        );

      case TakeCardAction(:final usedCard, :final targetCard, :final fromZone):
        cardIds = {usedCard.id, targetCard.id};
        if (vm.gameState.gameMode == GameMode.tresydos) {
          final takeFrom = fromZone == ZoneType.table ? 'pile' : 'deck';
          final message = 'Hint: take from the $takeFrom.';

          return (
            message: message,
            cardIds: cardIds,
            stackIds: stackIds,
            keys: const <GlobalKey>{},
          );
        }

        keys.add(vm.playButtonKey);
        return (
          message:
              'Hint: take ${targetCard.rank} with ${usedCard.rank}.',
          cardIds: cardIds,
          stackIds: stackIds,
          keys: keys,
        );

      case TakeStackAction(:final usedCard, :final targetStack):
        cardIds = {usedCard.id};
        stackIds = {targetStack.id};
        keys.add(vm.takeStackButtonKey);
        return (
          message:
              'Hint: take the ${targetStack.stackValue}-point stack with ${usedCard.rank}.',
          cardIds: cardIds,
          stackIds: stackIds,
          keys: keys,
        );

      case AddCardsAction(:final usedCard, :final targetCards):
        cardIds = {usedCard.id, for (final c in targetCards) c.id};
        final sum = usedCard.valueHigh + sumOf(targetCards);
        keys.add(vm.addButtonKey);
        return (
          message:
              'Hint: add ${usedCard.rank} and ${targetCards.map((e) => e.rank).join(' and ')} to form $sum.',
          cardIds: cardIds,
          stackIds: stackIds,
          keys: keys,
        );

      case AddTableCardsAction(:final targetCards):
        cardIds = {for (final c in targetCards) c.id};
        final sum = sumOf(targetCards);
        keys.add(vm.addButtonKey);
        return (
          message:
              'Hint: combine ${targetCards.map((e) => e.rank).join(' and ')} to form $sum.',
          cardIds: cardIds,
          stackIds: stackIds,
          keys: keys,
        );

      case AddCardStackAction(:final usedCard, :final targetStacks):
        cardIds = {usedCard.id};
        stackIds = {for (final s in targetStacks) s.id};
        final sum = usedCard.valueHigh +
            targetStacks.fold(0, (acc, s) => acc + s.stackValue);
        keys.add(vm.addButtonKey);
        return (
          message:
              'Hint: add ${usedCard.rank} to that ${targetStacks.length == 1 ? 'stack' : 'stacks'} to form $sum.',
          cardIds: cardIds,
          stackIds: stackIds,
          keys: keys,
        );

      case PairCardsAction(:final usedCard):
        cardIds = {usedCard.id};
        keys.add(vm.playButtonKey);
        return (
          message: 'Hint: pair ${usedCard.rank}.',
          cardIds: cardIds,
          stackIds: stackIds,
          keys: keys,
        );

      default:
        return null;
    }
  }

  Future<void> _leaveToHome() async {
    await vm.queueHomeCoinClaim();
    await vm.queueHomeDailyChallengeEnergyClaims();
    await vm.queueHomeXpClaim();
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
                  onPressed: SoundService.wrapTap(() {
                    context.go('/landing');
                  }),
                  child: Text("Home"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final useSimpleLayout = GameRegistry.isPlayable(vm.gameState.gameMode);

    return ChangeNotifierProvider<TutorialViewModel>.value(
      value: tutorialVm,
      child: SizedBox(
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
                                  stake: vm.tutorialMode
                                      ? null
                                      : vm.gameState.entryCost,
                                  seats: vm.gameState.seatedPlayerCount,
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
                                name: vm.player.name,
                                score: vm.gameState.scores[vm.me] ?? 0,
                                pendingCoins: vm.revealedPendingFor(vm.me),
                                isTurn: vm.isSeatTurn(vm.me),
                                turnDeadline: vm.turnDeadlineFor(vm.me),
                                turnTotal: vm.turnTotal,
                                onPressed: () {
                                  AppHaptics.mediumImpact();
                                  showGameStatusPopup(context, vm: vm);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (vm.showWinCelebration)
                        Positioned.fill(
                          child: Builder(
                            builder: (context) {
                              final stackBox =
                                  context.findRenderObject() as RenderBox?;
                              final targetPid = vm.winCelebrationPid;
                              final targetKey = targetPid == null
                                  ? vm.myHandKey
                                  : targetPid == vm.me
                                  ? vm.myHandKey
                                  : vm.celebrationAvatarKeyForPid(targetPid);
                              final targetBox = targetKey.currentContext
                                  ?.findRenderObject() as RenderBox?;

                              if (stackBox == null || targetBox == null) {
                                return const SizedBox.shrink();
                              }

                              final stackSize = stackBox.size;
                              final w = stackSize.width;
                              final h = stackSize.height;
                              if (w <= 0 || h <= 0) {
                                return WinConfettiOverlay(
                                  originFraction: const Offset(.5, .5),
                                  key: ValueKey(vm.activeWinCelebrationKey),
                                );
                              }

                              final centerGlobal =
                                  targetBox.localToGlobal(
                                    targetBox.size.center(Offset.zero),
                                  );
                              final centerLocal = stackBox.globalToLocal(centerGlobal);

                              final originFraction = Offset(
                                (centerLocal.dx / w).clamp(0.08, 0.92),
                                (centerLocal.dy / h).clamp(0.08, 0.92),
                              );

                              return WinConfettiOverlay(
                                originFraction: originFraction,
                                key: ValueKey(vm.activeWinCelebrationKey),
                              );
                            },
                          ),
                        ),
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
                            tableAnchorKey: vm.tableContentKey,
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
      ),
    );
  }

  Widget? _selectPlayingArea(GameMode mode) {
    switch (mode) {
      case GameMode.tresydos:
        return NewTresydosPlayingArea();
      case GameMode.rummy:
        return const RummyPlayingArea();
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
    final tutorial = context.watch<TutorialViewModel>();
    final scoreHint =
        tutorial.active && tutorial.pulsesTarget(key: vm.scoreKey);
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
            name: vm.player.name,
            score: vm.gameState.scores[vm.me] ?? 0,
            pendingCoins: vm.revealedPendingFor(vm.me),
            isTurn: vm.tutorialMode ? scoreHint : vm.isSeatTurn(vm.me),
            turnDeadline: vm.tutorialMode
                ? null
                : vm.turnDeadlineFor(vm.me),
            turnTotal: vm.tutorialMode ? null : vm.turnTotal,
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
  const _GameModeChip({
    required this.label,
    this.stake,
    this.seats = 2,
  });

  final String label;
  final int? stake;
  final int seats;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final showStake = stake != null && stake! > 0;
    final tableSeats = seats.clamp(2, 4);
    final jackpot = showStake ? WalletConfig.potTotal(stake!, tableSeats) : 0;
    final chip = Container(
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: theme.textPrimary.withValues(alpha: .9),
            ),
          ),
          if (showStake) ...[
            Container(
              width: 1,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: theme.border.withValues(alpha: .7),
            ),
            Icon(
              coinIcon,
              size: 12,
              color: theme.turnHighlight,
            ),
            const SizedBox(width: 4),
            Text(
              '$jackpot',
              style: theme.caption.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: theme.turnHighlight,
              ),
            ),
          ],
        ],
      ),
    );

    if (!showStake) return chip;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      pressedOpacity: 0.72,
      onPressed: SoundService.wrapTap(() {
        AppHaptics.lightImpact();
        _showPotInfo(context, title: label, stake: stake!, seats: seats);
      }),
      child: chip,
    );
  }
}

void _showPotInfo(
  BuildContext context, {
  required String title,
  required int stake,
  required int seats,
}) {
  final theme = AppStyle.theme;
  final l10n = AppLocalizations.of(context);
  final tableSeats = seats.clamp(2, 4);
  final pot = WalletConfig.potTotal(stake, tableSeats);

  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withValues(alpha: .55),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: CupertinoColors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.border.withValues(alpha: .7)),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: .45),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.title.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.eachPlayerBets(stake),
                    textAlign: TextAlign.center,
                    style: theme.mutedText.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(coinIcon, size: 14, color: theme.turnHighlight),
                      const SizedBox(width: 4),
                      Text(
                        l10n.potTotal(pot),
                        style: theme.title.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.turnHighlight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var place = 1; place <= tableSeats; place++) ...[
                    if (place > 1) const SizedBox(height: 6),
                    _PotPlaceRow(
                      label: l10n.coinPayoutPlace(place),
                      amount: WalletConfig.potShareForRank(
                        stake,
                        tableSeats,
                        place,
                      ),
                    ),
                  ],
                  CupertinoButton(
                    padding: const EdgeInsets.only(top: 6),
                    onPressed: SoundService.wrapTap(
                      () => Navigator.pop(dialogContext),
                    ),
                    child: Text(l10n.done, style: TextStyle(color: theme.muted)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      );
    },
  );
}

class _PotPlaceRow extends StatelessWidget {
  const _PotPlaceRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final paid = amount > 0;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.body.copyWith(
              color: paid ? theme.textPrimary : theme.muted,
            ),
          ),
        ),
        Icon(
          coinIcon,
          size: 13,
          color: paid ? theme.turnHighlight : theme.muted,
        ),
        const SizedBox(width: 4),
        Text(
          '$amount',
          style: theme.title.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: paid ? theme.turnHighlight : theme.muted,
          ),
        ),
      ],
    );
  }
}
