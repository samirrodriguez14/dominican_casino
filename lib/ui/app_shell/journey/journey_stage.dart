import 'dart:math' as math;

import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_board.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_deck.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

enum TableDeck { games, journey }

/// Swaps Games ↔ Journey. The Journey deck is one live object (peek → deal).
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
    with SingleTickerProviderStateMixin {
  static const _swapDuration = Duration(milliseconds: 3200);

  late final AnimationController _swapAnim;
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
    _swapAnim = AnimationController(vsync: this, duration: _swapDuration)
      ..addListener(_onSwapTick);
  }

  @override
  void dispose() {
    _swapAnim.removeListener(_onSwapTick);
    _swapAnim.dispose();
    super.dispose();
  }

  TableDeck get tableDeck => _tableDeck;

  double get _t => _swapAnim.value;

  double get _gameEat {
    return const Interval(0.0, 0.22, curve: Curves.easeInCubic).transform(_t);
  }

  double get _deckArrive {
    return const Interval(0.08, 0.34, curve: Curves.easeInOutCubic)
        .transform(_t);
  }

  double get _sectionExpand {
    return const Interval(0.10, 0.36, curve: Curves.easeOutCubic)
        .transform(_t);
  }

  double get _pileDeal {
    return const Interval(0.34, 0.72, curve: Curves.linear).transform(_t);
  }

  double get _defeatedDeal {
    return const Interval(0.70, 1.0, curve: Curves.linear).transform(_t);
  }

  JourneyOpenProgress get _openProgress => JourneyOpenProgress(
        deckArrive: _deckArrive,
        sectionExpand: _sectionExpand,
        pileDeal: _pileDeal,
        defeatedDeal: _defeatedDeal,
      );

  List<JourneyDealSlot> get _dealPlan =>
      _boardKey.currentState?.dealPlan ??
      JourneyBoard.dealPlanFor(journeyBoardSnapshot);

  void _onSwapTick() {
    final eat = _gameEat;
    final reversing = _swapAnim.status == AnimationStatus.reverse;

    if (!reversing) {
      if (!_pulsedEatIn && eat >= 0.72) {
        _pulsedEatIn = true;
        widget.onGamesNavEat?.call();
        AppHaptics.mediumImpact();
      }
    } else {
      if (!_pulsedSpitOut && eat < 0.98 && eat > 0.15) {
        _pulsedSpitOut = true;
        widget.onGamesNavEat?.call();
        AppHaptics.mediumImpact();
      }
    }

    if (eat <= 0.02) _pulsedEatIn = false;
    if (eat >= 0.99) _pulsedSpitOut = false;

    final plan = _dealPlan;
    final challengerN = JourneyBoard.challengerCount(plan);
    final defeatedN = JourneyBoard.defeatedCount(plan);
    final total = plan.isEmpty ? JourneyBoard.dealCardCount : plan.length;

    final pileDeal = _pileDeal;
    final defeatedDeal = _defeatedDeal;
    var step = -1;
    if (pileDeal > 0.02 && challengerN > 0) {
      step = (pileDeal * challengerN).floor().clamp(0, challengerN - 1);
    }
    if (defeatedDeal > 0.02 && defeatedN > 0) {
      final dStep =
          (defeatedDeal * defeatedN).floor().clamp(0, defeatedN - 1);
      step = challengerN + dStep;
    }
    if (step < 0) {
      if (pileDeal <= 0.02) _lastDealSoundIndex = -1;
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
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.lightImpact();
    _lastDealSoundIndex = -1;
    _pulsedEatIn = false;

    setState(() => _tableDeck = TableDeck.journey);
    widget.onTableDeckChanged?.call(TableDeck.journey);

    final world =
        _boardKey.currentState?.activeWorld ?? JourneyWorld.diamonds;
    await context.read<AppRepo>().unlockAndEquipPack(world.themeId);
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

  Future<void> showGames() async {
    if (_tableDeck == TableDeck.games || _busy || _swapAnim.isAnimating) {
      return;
    }

    _busy = true;
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.lightImpact();
    _lastDealSoundIndex = JourneyBoard.dealCardCount;
    _pulsedSpitOut = false;

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _swapAnim,
      builder: (context, _) {
        final open = _openProgress;
        final eat = _gameEat;
        final gamesOnTable = 1 - _t;

        final hideGamesMain = widget.showingGrid || eat > 0.98;
        final hideJourneyMain =
            open.deckArrive < 0.02 && open.sectionExpand < 0.02;
        final dealPlan = _dealPlan;
        final showLiveDeck = !widget.showingGrid &&
            (gamesOnTable > 0.4 || open.deckArrive > 0.01) &&
            (open.pileDeal < 0.995 ||
                (JourneyBoard.defeatedCount(dealPlan) > 0 &&
                    open.defeatedDeal < 0.995));

        return LayoutBuilder(
          builder: (context, constraints) {
            final stage = Size(constraints.maxWidth, constraints.maxHeight);
            final originCenter = Offset(stage.width / 2, stage.height / 2);
            final tabCenter = _gamesTabCenterInStage(stage);

            final gameDelta = Offset.lerp(
              Offset.zero,
              tabCenter - originCenter,
              eat,
            )!;
            final gameScale = math.max(0.02, 1.0 - eat * 0.98);
            final gameOpacity =
                (1.0 - Curves.easeIn.transform(eat)).clamp(0.0, 1.0);

            final pileW = (stage.width - 30) / 4;
            final pileH = pileW / homeCardAspect;
            final pileTargets = <Offset>[
              for (var i = 0; i < 4; i++)
                Offset(15 + pileW * (i + 0.5), 8 + pileH * 0.42),
            ];
            final defeatedY = stage.height * 0.88;
            final defeatedTargets = <Offset>[
              for (var i = 0; i < 4; i++)
                Offset(15 + pileW * (i + 0.5), defeatedY),
            ];
            final pileCardSize = pileW * 0.88;

            return Stack(
              key: _stageKey,
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                IgnorePointer(
                  ignoring: hideGamesMain || _tableDeck == TableDeck.journey,
                  child: Opacity(
                    opacity: gameOpacity,
                    child: Transform.translate(
                      offset: gameDelta,
                      child: Transform.scale(
                        scale: gameScale,
                        alignment: Alignment.center,
                        child: GameModeCarousel(key: widget.carouselKey),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: hideJourneyMain ||
                      (_busy && open.defeatedDeal < 0.9),
                  child: Opacity(
                    opacity: hideJourneyMain ? 0 : 1,
                    child: JourneyBoard(
                      key: _boardKey,
                      openProgress: open,
                      onWorldThemeEquipped: _onWorldThemeEquipped,
                    ),
                  ),
                ),

                // One continuous deck object (peek arrangement → deal).
                if (showLiveDeck)
                  JourneyLiveDeck(
                    dealPlan: dealPlan,
                    deckArrive: open.deckArrive,
                    pileDeal: open.pileDeal,
                    defeatedDeal: open.defeatedDeal,
                    stageSize: stage,
                    pileTargets: pileTargets,
                    defeatedTargets: defeatedTargets,
                    pileCardSize: pileCardSize,
                    onTap: gamesOnTable > 0.55 && open.deckArrive < 0.05
                        ? showJourney
                        : null,
                    showLabel:
                        gamesOnTable > 0.55 && open.deckArrive < 0.05,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
