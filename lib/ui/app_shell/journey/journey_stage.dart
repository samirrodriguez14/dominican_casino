import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_board.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_deck.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_motion.dart';
import 'package:flutter/cupertino.dart';

enum TableDeck { games, journey }

/// Swaps Games ↔ Journey. Orchestrates controllers; motion math lives in
/// [JourneyTimeline] / [JourneyTableLayout].
class JourneyStage extends StatefulWidget {
  const JourneyStage({
    super.key,
    required this.carouselKey,
    required this.showingGrid,
    required this.gridProgress,
    this.gamesTabKey,
    this.onGamesNavEat,
    this.onTableDeckChanged,
  });

  final GlobalKey<GameModeCarouselState> carouselKey;
  final bool showingGrid;
  final double gridProgress;
  final GlobalKey? gamesTabKey;
  final VoidCallback? onGamesNavEat;
  final ValueChanged<TableDeck>? onTableDeckChanged;

  @override
  State<JourneyStage> createState() => JourneyStageState();
}

class JourneyStageState extends State<JourneyStage>
    with TickerProviderStateMixin {
  late final AnimationController _swapAnim;
  late final AnimationController _peekFan;
  final GlobalKey<JourneyBoardState> _boardKey = GlobalKey();
  final GlobalKey _stageKey = GlobalKey();

  TableDeck _tableDeck = TableDeck.games;
  bool _busy = false;
  int _lastDealSoundIndex = -1;
  bool _pulsedEatIn = false;
  bool _pulsedSpitOut = false;

  @override
  void initState() {
    super.initState();
    _swapAnim = AnimationController(
      vsync: this,
      duration: JourneyTimeline.openDuration,
    )..addListener(_onSwapTick);
    _peekFan = AnimationController(
      vsync: this,
      duration: JourneyTimeline.peekFanDuration,
    );
  }

  @override
  void dispose() {
    _swapAnim.removeListener(_onSwapTick);
    _swapAnim.dispose();
    _peekFan.dispose();
    super.dispose();
  }

  TableDeck get tableDeck => _tableDeck;

  /// Called when the Games shell tab is focused again.
  void onShellTabVisible() {
    _boardKey.currentState?.onShellTabVisible();
  }

  bool get _closing => _swapAnim.status == AnimationStatus.reverse;

  JourneyOpenProgress get _open => JourneyTimeline.openProgress(
        t: _swapAnim.value,
        peekFan: _peekFan.value,
        closing: _closing,
      );

  double get _gameEat =>
      JourneyTimeline.gameEat(t: _swapAnim.value, closing: _closing);

  List<JourneyDealSlot> get _dealPlan =>
      _boardKey.currentState?.dealPlan ??
      JourneyDealPlan.forSnapshot(journeyBoardSnapshot);

  bool get _peekInteractive {
    final eat = _gameEat;
    final open = _open;
    return (1 - eat) > 0.55 && open.deckArrive < 0.05;
  }

  void _startPeekFan() {
    if (_peekFan.value < 0.01) _peekFan.forward(from: 0);
  }

  void _onSwapTick() {
    final eat = _gameEat;
    if (!_closing) {
      if (!_pulsedEatIn && eat >= 0.88) {
        _pulsedEatIn = true;
        widget.onGamesNavEat?.call();
        AppHaptics.mediumImpact();
      }
    } else if (!_pulsedSpitOut && eat < 0.88) {
      _pulsedSpitOut = true;
      widget.onGamesNavEat?.call();
      AppHaptics.mediumImpact();
    }

    if (eat <= 0.02) _pulsedEatIn = false;
    if (eat >= 0.99) _pulsedSpitOut = false;
    if (_closing) return;

    _tickDealSounds();
  }

  void _tickDealSounds() {
    final open = _open;
    final plan = _dealPlan;
    final challengerPiles = JourneyDealPlan.challengerPileCount(plan);
    final defeatedPiles = JourneyDealPlan.defeatedPileCount(plan);
    final total = challengerPiles + defeatedPiles;
    if (total == 0) return;

    var step = -1;
    if (open.pileDeal > 0.02 && challengerPiles > 0) {
      step = (open.pileDeal * challengerPiles).floor().clamp(0, challengerPiles - 1);
    }
    if (open.defeatedDeal > 0.02 && defeatedPiles > 0) {
      final dStep =
          (open.defeatedDeal * defeatedPiles).floor().clamp(0, defeatedPiles - 1);
      step = challengerPiles + dStep;
    }
    if (step < 0) {
      if (open.pileDeal <= 0.02) _lastDealSoundIndex = -1;
      return;
    }
    if (step > _lastDealSoundIndex) {
      _lastDealSoundIndex = step.clamp(0, total);
      SoundService.instance.playLayered(GameSound.softCard);
      AppHaptics.lightImpact();
    }
  }

  Offset _gamesTabCenterInStage(Size stage) {
    final tabCtx = widget.gamesTabKey?.currentContext;
    final stageCtx = _stageKey.currentContext;
    if (tabCtx != null && stageCtx != null) {
      final tabBox = tabCtx.findRenderObject() as RenderBox?;
      final stageBox = stageCtx.findRenderObject() as RenderBox?;
      if (tabBox != null &&
          stageBox != null &&
          tabBox.hasSize &&
          stageBox.hasSize) {
        final global = tabBox.localToGlobal(tabBox.size.center(Offset.zero));
        return stageBox.globalToLocal(global);
      }
    }
    return Offset(stage.width / 2, stage.height + 64);
  }

  Future<void> showJourney() async {
    if (_tableDeck == TableDeck.journey || _busy || _swapAnim.isAnimating) {
      return;
    }
    if (widget.carouselKey.currentState?.isBusy == true) return;

    _busy = true;
    _startPeekFan();
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.lightImpact();
    _lastDealSoundIndex = -1;
    _pulsedEatIn = false;
    _swapAnim.duration = JourneyTimeline.openDuration;

    setState(() => _tableDeck = TableDeck.journey);
    widget.onTableDeckChanged?.call(TableDeck.journey);
    _boardKey.currentState?.reloadFromProgress();

    // Keep Base (Sage) until the player confirms entering a kingdom.
    if (!mounted) {
      _busy = false;
      return;
    }

    await widget.carouselKey.currentState?.collapsePeeks();
    if (!mounted) {
      _busy = false;
      return;
    }

    await _swapAnim.forward(from: 0);
    _busy = false;
  }

  /// Jump straight to a fully laid Journey table (no enter animation).
  ///
  /// Used when returning from a Journey match that already had the board set.
  Future<void> restoreJourneySettled() async {
    // Always honor a return-from-match request, even if a prior swap left
    // [_busy] true (otherwise the Games carousel stays on the table).
    _busy = true;
    _swapAnim.stop();
    _swapAnim.value = 1;
    _peekFan.value = 1;
    _lastDealSoundIndex = JourneyDealPlan.dealCardCount;
    _pulsedEatIn = true;
    setState(() => _tableDeck = TableDeck.journey);
    widget.onTableDeckChanged?.call(TableDeck.journey);

    await widget.carouselKey.currentState?.collapsePeeks(
      duration: Duration.zero,
    );
    if (!mounted) {
      _busy = false;
      return;
    }
    await _boardKey.currentState?.reloadFromProgress();
    if (mounted) _busy = false;
  }

  Future<void> showGames() async {
    if (_tableDeck == TableDeck.games || _busy || _swapAnim.isAnimating) {
      return;
    }

    _busy = true;
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.lightImpact();
    _lastDealSoundIndex = JourneyDealPlan.dealCardCount;
    _pulsedSpitOut = false;
    _swapAnim.duration = JourneyTimeline.closeDuration;

    await _boardKey.currentState?.dismissSelectedIfNeeded();
    if (!mounted) {
      _busy = false;
      return;
    }

    await _swapAnim.reverse(from: 1);
    if (!mounted) {
      _busy = false;
      return;
    }

    _swapAnim.duration = JourneyTimeline.openDuration;
    _peekFan.value = 0;

    await widget.carouselKey.currentState?.revealPeeks();
    if (!mounted) {
      _busy = false;
      return;
    }

    setState(() => _tableDeck = TableDeck.games);
    widget.onTableDeckChanged?.call(TableDeck.games);
    _busy = false;
  }

  Future<void> toggleTableDeck() async {
    if (_tableDeck == TableDeck.games) {
      await showJourney();
    } else {
      await showGames();
    }
  }

  void _onWorldThemeEquipped(JourneyWorld world) {
    if (mounted) setState(() {});
  }

  bool _showLiveDeck(JourneyOpenProgress open, double gamesOnTable) {
    if (widget.showingGrid) return false;
    final gathering = open.cardGather > 0.01;
    final entering = open.pileDeal < 0.995 ||
        (JourneyDealPlan.defeatedPileCount(_dealPlan) > 0 &&
            open.defeatedDeal < 0.995);
    final peeking = open.deckArrive < 0.08 && open.pileDeal < 0.02;
    final peekOuting = open.deckArrive > 0.01 && open.deckArrive < 0.99;
    return (gathering || gamesOnTable > 0.4 || peekOuting || entering) &&
        (gathering || entering || peeking || peekOuting);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_swapAnim, _peekFan]),
      builder: (context, _) {
        final open = _open;
        final eat = _gameEat;
        final gamesOnTable = 1 - eat;
        final gathering = open.cardGather > 0.01;
        final hideGames = widget.showingGrid || eat > 0.995;
        final hideJourney = open.cardGather > 0.58 ||
            (open.sectionExpand < 0.02 && open.pileDeal < 0.02);
        final peekLive = _peekInteractive;

        return LayoutBuilder(
          builder: (context, constraints) {
            final stage = Size(constraints.maxWidth, constraints.maxHeight);
            final tabCenter = _gamesTabCenterInStage(stage);
            final gameDelta = JourneyTableLayout.gameCarouselDelta(
              eat: eat,
              stage: stage,
              tabCenter: tabCenter,
            );
            final gameScale =
                JourneyTimeline.gameScale(eat: eat, closing: _closing);

            return Stack(
              key: _stageKey,
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                IgnorePointer(
                  ignoring: hideGames || _tableDeck == TableDeck.journey,
                  child: Transform.translate(
                    offset: gameDelta,
                    child: Transform.scale(
                      scale: gameScale,
                      alignment: Alignment.center,
                      child: GameModeCarousel(key: widget.carouselKey),
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: hideJourney ||
                      (_busy && !gathering && open.defeatedDeal < 0.9),
                  child: Opacity(
                    opacity: hideJourney ? 0 : 1,
                    child: JourneyBoard(
                      key: _boardKey,
                      openProgress: open,
                      onWorldThemeEquipped: _onWorldThemeEquipped,
                    ),
                  ),
                ),
                if (_showLiveDeck(open, gamesOnTable))
                  JourneyLiveDeck(
                    dealPlan: _dealPlan,
                    peekDealPlan: JourneyDealPlan.ensurePeekCards(_dealPlan),
                    deckArrive: open.deckArrive,
                    deckFan: open.deckFan,
                    pileDeal: open.pileDeal,
                    defeatedDeal: open.defeatedDeal,
                    cardGather: open.cardGather,
                    stageSize: stage,
                    pileTargets: JourneyTableLayout.pileTargets(stage),
                    defeatedTargets: JourneyTableLayout.defeatedTargets(stage),
                    pileCardSize: JourneyTableLayout.pileCardSize(stage.width),
                    onTap: peekLive ? showJourney : null,
                    onPressStart: peekLive ? _startPeekFan : null,
                    showLabel: peekLive,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
