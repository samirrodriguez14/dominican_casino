import 'dart:math' as math;

import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_active_stage.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_defeated_row.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_face_card.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_motion.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_world_piles.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

export 'package:dominican_casino/ui/app_shell/journey/journey_motion.dart'
    show JourneyDealPlan, JourneyDealSlot, JourneyOpenProgress;

/// Three-band Journey board: piles / active stage / defeated.
class JourneyBoard extends StatefulWidget {
  const JourneyBoard({
    super.key,
    this.openProgress = JourneyOpenProgress.settled,
    this.onWorldThemeEquipped,
  });

  static const worldCount = JourneyDealPlan.worldCount;
  static const cardsPerPile = JourneyDealPlan.cardsPerPile;
  static const dealCardCount = JourneyDealPlan.dealCardCount;

  final JourneyOpenProgress openProgress;
  final ValueChanged<JourneyWorld>? onWorldThemeEquipped;

  static List<JourneyDealSlot> dealPlanFor(JourneyDisplaySnapshot snap) =>
      JourneyDealPlan.forSnapshot(snap);

  static int challengerCount(List<JourneyDealSlot> plan) =>
      JourneyDealPlan.challengerCount(plan);

  static int defeatedCount(List<JourneyDealSlot> plan) =>
      JourneyDealPlan.defeatedCount(plan);

  static double challengerFlight(
    List<JourneyDealSlot> plan,
    double pileDeal,
    int challengerIndex,
  ) =>
      JourneyDealPlan.challengerFlight(plan, pileDeal, challengerIndex);

  static double defeatedFlight(
    List<JourneyDealSlot> plan,
    double defeatedDeal,
    int defeatedIndex,
  ) =>
      JourneyDealPlan.defeatedFlight(plan, defeatedDeal, defeatedIndex);

  static int challengerLandedDepth(
    List<JourneyDealSlot> plan,
    double pileDeal,
    JourneyWorld world,
  ) =>
      JourneyDealPlan.challengerLandedDepth(plan, pileDeal, world);

  static int defeatedLandedCount(
    List<JourneyDealSlot> plan,
    double defeatedDeal,
    JourneyWorld world,
  ) =>
      JourneyDealPlan.defeatedLandedCount(plan, defeatedDeal, world);

  @override
  State<JourneyBoard> createState() => JourneyBoardState();
}

class JourneyBoardState extends State<JourneyBoard>
    with TickerProviderStateMixin {
  static const _flipDuration = Duration(milliseconds: 720);
  static const _defeatFlyDuration = Duration(milliseconds: 520);

  late List<JourneyWorldDef> _worlds;
  JourneyWorld _activeWorld = JourneyWorld.diamonds;
  JourneyCardDef? _selected;
  /// Where the focused card lives when not centered.
  bool _selectedFromDefeated = false;
  Offset? _selectFromOverride;
  late final AnimationController _selectAnim;
  late final AnimationController _defeatFlyAnim;
  JourneyCardDef? _defeatFlying;

  /// Live drag of a pile card toward the center.
  JourneyCardDef? _dragging;
  bool _draggingFromDefeated = false;
  Offset? _dragPos;

  @override
  void initState() {
    super.initState();
    _worlds = [
      for (final world in journeyBoardSnapshot.worlds)
        JourneyWorldDef(
          world: world.world,
          unlocked: world.unlocked,
          cards: List<JourneyCardDef>.from(world.cards),
        ),
    ];
    _selectAnim = AnimationController(vsync: this, duration: _flipDuration);
    _defeatFlyAnim = AnimationController(
      vsync: this,
      duration: _defeatFlyDuration,
    );
  }

  @override
  void dispose() {
    _selectAnim.dispose();
    _defeatFlyAnim.dispose();
    super.dispose();
  }

  JourneyWorld get activeWorld => _activeWorld;

  /// Flip + return the selected challenger to its pile before leaving Journey.
  Future<void> dismissSelectedIfNeeded() async {
    if (_selected == null && _selectAnim.value < 0.01) return;
    SoundService.instance.playLayered(GameSound.softCard);
    if (_selectAnim.value > 0.01) {
      await _selectAnim.reverse();
    }
    if (!mounted) return;
    setState(() => _selected = null);
  }

  JourneyDisplaySnapshot get _snapshot =>
      JourneyDisplaySnapshot(worlds: _worlds);

  /// Challengers first, defeated last (bottom of the deal stack).
  List<JourneyDealSlot> get dealPlan => JourneyBoard.dealPlanFor(_snapshot);

  Future<void> equipActiveWorldTheme() async {
    await _equipWorld(_activeWorld);
  }

  Future<void> _equipWorld(JourneyWorld world) async {
    final repo = context.read<AppRepo>();
    await repo.unlockAndEquipPack(world.themeId);
    widget.onWorldThemeEquipped?.call(world);
  }

  void _setCardState(
    JourneyWorld world,
    JourneyRank rank,
    JourneyCardState state,
  ) {
    setState(() {
      _worlds = [
        for (final w in _worlds)
          if (w.world != world)
            w
          else
            w.copyWith(
              cards: [
                for (final c in w.cards)
                  if (c.rank == rank) c.copyWith(state: state) else c,
              ],
            ),
      ];
      if (_selected?.world == world && _selected?.rank == rank) {
        _selected = null;
        _selectAnim.value = 0;
      }
    });
  }

  Future<void> _selectCard(
    JourneyCardDef card, {
    required bool fromDefeated,
    Offset? fromOverride,
    double startProgress = 0,
  }) async {
    final def = _snapshot.worldOf(card.world);
    if (!def.unlocked || !card.isSelectable) {
      SoundService.instance.playLayered(GameSound.softCard);
      AppHaptics.selectionClick();
      return;
    }

    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.mediumImpact();

    if (_selected?.world == card.world && _selected?.rank == card.rank) {
      await _selectAnim.reverse();
      if (!mounted) return;
      setState(() {
        _selected = null;
        _selectFromOverride = null;
      });
      return;
    }

    if (_selected != null && _selectAnim.value > 0.05) {
      await _selectAnim.reverse();
      if (!mounted) return;
      setState(() {
        _selected = null;
        _selectFromOverride = null;
      });
    }

    setState(() {
      _activeWorld = card.world;
      _selected = card;
      _selectedFromDefeated = fromDefeated;
      _selectFromOverride = fromOverride;
      _dragging = null;
      _dragPos = null;
    });
    await _equipWorld(card.world);
    if (!mounted) return;
    await _selectAnim.forward(from: startProgress.clamp(0.0, 0.85));
  }

  Future<void> _onWorldTap(JourneyWorld world) async {
    final def = _snapshot.worldOf(world);
    SoundService.instance.playLayered(GameSound.softCard);
    if (!def.unlocked) {
      AppHaptics.selectionClick();
      return;
    }
    AppHaptics.lightImpact();
    setState(() {
      _activeWorld = world;
      if (_selected != null && _selected!.world != world) {
        _selected = null;
        _selectAnim.value = 0;
        _selectFromOverride = null;
      }
    });
    await _equipWorld(world);
  }

  Future<void> _onTopCardTap(JourneyCardDef card) =>
      _selectCard(card, fromDefeated: false);

  Future<void> _onDefeatedTap(JourneyCardDef card) =>
      _selectCard(card, fromDefeated: true);

  void _onCardDragStart(
    JourneyCardDef card, {
    required bool fromDefeated,
    required Offset localPos,
  }) {
    if (_selectAnim.isAnimating || _defeatFlying != null) return;
    if (_dragging != null) return;
    final def = _snapshot.worldOf(card.world);
    if (!def.unlocked || !card.isSelectable) return;
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.selectionClick();
    setState(() {
      _dragging = card;
      _draggingFromDefeated = fromDefeated;
      _dragPos = localPos;
      if (_selected?.world == card.world && _selected?.rank == card.rank) {
        _selected = null;
        _selectAnim.value = 0;
        _selectFromOverride = null;
      }
    });
  }

  void _onCardDragUpdate(Offset localPos) {
    if (_dragging == null) return;
    setState(() => _dragPos = localPos);
  }

  void _cancelDrag() {
    if (_dragging == null) return;
    SoundService.instance.playLayered(GameSound.softCard);
    setState(() {
      _dragging = null;
      _dragPos = null;
    });
  }

  Future<void> _onCardDragEnd({
    required Offset centerTarget,
    required double boardHeight,
    required double boardWidth,
  }) async {
    final card = _dragging;
    final pos = _dragPos;
    final fromDefeated = _draggingFromDefeated;
    if (card == null || pos == null) return;

    // Generous center-stage drop zone (not a tiny point).
    final dropRadius = math.max(150.0, boardWidth * 0.38);
    final inCenterBand =
        pos.dy > boardHeight * 0.22 && pos.dy < boardHeight * 0.78;
    final dist = (pos - centerTarget).distance;
    final accepted = inCenterBand && dist < dropRadius;

    if (accepted) {
      final start = (1.0 - (dist / dropRadius).clamp(0.0, 1.0)) * 0.5;
      await _selectCard(
        card,
        fromDefeated: fromDefeated,
        fromOverride: pos,
        startProgress: start,
      );
      return;
    }

    _cancelDrag();
  }

  Future<void> _onChallenge() async {
    final card = _selected;
    if (card == null) return;

    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.mediumImpact();

    final outcome = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Challenge: ${card.title}'),
        content: const Text(
          'Test match outcome (placeholder until real matches wire up).',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop('defeat'),
            child: const Text('Defeat'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop('lose'),
            child: const Text('Lose'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (!mounted || outcome == null) return;

    if (outcome == 'defeat') {
      SoundService.instance.playLayered(GameSound.softCard);
      AppHaptics.heavyImpact();
      // One object: leave center straight to Defeated — never return to the
      // challenger pile first.
      setState(() {
        _defeatFlying = card;
        _selected = null;
      });
      _selectAnim.value = 0;
      _setCardState(card.world, card.rank, JourneyCardState.defeated);
      await _defeatFlyAnim.forward(from: 0);
      if (!mounted) return;
      setState(() => _defeatFlying = null);
      _defeatFlyAnim.value = 0;
      return;
    }

    if (outcome == 'lose') {
      SoundService.instance.playLayered(GameSound.softCard);
      AppHaptics.mediumImpact();
    }
  }

  Future<void> _onDismissSelected() async {
    if (_selected == null) return;
    SoundService.instance.playLayered(GameSound.softCard);
    await _selectAnim.reverse();
    if (!mounted) return;
    setState(() {
      _selected = null;
      _selectFromOverride = null;
    });
  }

  Offset _toLocal(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global;
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) {
    final worldDef = _snapshot.worldOf(_activeWorld);
    final hasAvailable = worldDef.nextSelectable != null;
    final open = widget.openProgress;
    final selected = _selected == null
        ? null
        : _snapshot.worldOf(_selected!.world).cards.firstWhere(
              (c) => c.rank == _selected!.rank,
              orElse: () => _selected!,
            );

    final centerReveal = journeySlotExpand(open.sectionExpand, 1, count: 3);
    final plan = dealPlan;

    // Only hide the centered selection from piles — keep the dragging card in
    // the pile tree (ghosted) so the pan GestureDetector stays alive.
    final hideChallenger =
        !_selectedFromDefeated ? selected : null;
    final hideDefeated = _defeatFlying ??
        (_selectedFromDefeated ? selected : null);
    final ghostChallenger =
        !_draggingFromDefeated ? _dragging : null;
    final ghostDefeated =
        _draggingFromDefeated ? _dragging : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stage = Size(constraints.maxWidth, constraints.maxHeight);
        final w = stage.width;
        final h = stage.height;
        final pileCardSize = JourneyTableLayout.pileCardSize(w);
        final pileTargets = JourneyTableLayout.pileTargets(stage);
        final defeatedTargets = JourneyTableLayout.defeatedTargets(stage);
        final centerTarget = Offset(w * 0.5, h * 0.48);
        final centerSize = (w * 0.42).clamp(120.0, 220.0);

        final interactive = open.pileDeal > 0.95 &&
            open.defeatedDeal > 0.95 &&
            open.cardGather < 0.02 &&
            _defeatFlying == null;

        return AnimatedBuilder(
          animation: Listenable.merge([_defeatFlyAnim, _selectAnim]),
          builder: (context, _) {
            final selectProgress = _selectAnim.value;
            final homeFrom = selected == null
                ? Offset.zero
                : (_selectFromOverride ??
                    (_selectedFromDefeated
                        ? defeatedTargets[
                            JourneyWorld.values.indexOf(selected.world)]
                        : pileTargets[
                            JourneyWorld.values.indexOf(selected.world)]));

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 22,
                        child: JourneyWorldPiles(
                          snapshot: _snapshot,
                          dealPlan: plan,
                          activeWorld: _activeWorld,
                          selectedCard: hideChallenger,
                          ghostCard: ghostChallenger,
                          sectionExpand: open.sectionExpand,
                          pileDeal: open.cardGather > 0.02 ? 0 : open.pileDeal,
                          onWorldTap: interactive ? _onWorldTap : null,
                          onTopCardTap: interactive ? _onTopCardTap : null,
                          onTopCardPanStart: interactive
                              ? (card, details) => _onCardDragStart(
                                    card,
                                    fromDefeated: false,
                                    localPos: _toLocal(details.globalPosition),
                                  )
                              : null,
                          onTopCardPanUpdate: interactive
                              ? (details) => _onCardDragUpdate(
                                    _toLocal(details.globalPosition),
                                  )
                              : null,
                          onTopCardPanEnd: interactive
                              ? (_) => _onCardDragEnd(
                                    centerTarget: centerTarget,
                                    boardHeight: h,
                                    boardWidth: w,
                                  )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        flex: 52,
                        child: Opacity(
                          opacity: centerReveal,
                          child: Transform.scale(
                            scale: 0.92 + 0.08 * centerReveal,
                            child: JourneyActiveStage(
                              hasAvailableChallenger: hasAvailable,
                              visible: selected == null &&
                                  selectProgress < 0.05 &&
                                  _defeatFlying == null &&
                                  _dragging == null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        flex: 26,
                        child: JourneyDefeatedRow(
                          snapshot: _snapshot,
                          dealPlan: plan,
                          sectionExpand: open.sectionExpand,
                          defeatedDeal:
                              open.cardGather > 0.02 ? 0 : open.defeatedDeal,
                          hidingCard: hideDefeated,
                          ghostCard: ghostDefeated,
                          onDefeatedTap: interactive ? _onDefeatedTap : null,
                          onDefeatedPanStart: interactive
                              ? (card, details) => _onCardDragStart(
                                    card,
                                    fromDefeated: true,
                                    localPos: _toLocal(details.globalPosition),
                                  )
                              : null,
                          onDefeatedPanUpdate: interactive
                              ? (details) => _onCardDragUpdate(
                                    _toLocal(details.globalPosition),
                                  )
                              : null,
                          onDefeatedPanEnd: interactive
                              ? (_) => _onCardDragEnd(
                                    centerTarget: centerTarget,
                                    boardHeight: h,
                                    boardWidth: w,
                                  )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dragging card under the finger.
                if (_dragging != null && _dragPos != null)
                  Positioned(
                    left: _dragPos!.dx - pileCardSize * 0.45,
                    top: _dragPos!.dy -
                        (pileCardSize * 0.9 / homeCardAspect) * 0.5,
                    width: pileCardSize * 0.9,
                    height: pileCardSize * 0.9 / homeCardAspect,
                    child: _draggingFromDefeated
                        ? JourneyFaceUpCard(
                            assetPath: _dragging!.assetPath,
                            world: _dragging!.world,
                          )
                        : JourneyFaceDownCard(world: _dragging!.world),
                  ),

                // Focus from the card's real home (challenger or defeated).
                if (selected != null &&
                    _defeatFlying == null &&
                    selectProgress > 0.01)
                  JourneyChallengerFocus(
                    card: selected,
                    progress: selectProgress,
                    from: homeFrom,
                    to: centerTarget,
                    fromSize: pileCardSize,
                    toSize: centerSize,
                    startsFaceUp: _selectedFromDefeated ||
                        _selectFromOverride != null,
                    onChallenge: _onChallenge,
                    onDismiss: _onDismissSelected,
                  ),

                if (_defeatFlying != null)
                  _DefeatedTransferCard(
                    card: _defeatFlying!,
                    flight: Curves.easeInOutCubic
                        .transform(_defeatFlyAnim.value),
                    from: centerTarget,
                    to: defeatedTargets[
                        JourneyWorld.values.indexOf(_defeatFlying!.world)],
                    size: centerSize * 0.85,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Face-up card moving into a defeated pile (one object — never duplicated).
class _DefeatedTransferCard extends StatelessWidget {
  const _DefeatedTransferCard({
    required this.card,
    required this.flight,
    required this.from,
    required this.to,
    required this.size,
  });

  final JourneyCardDef card;
  final double flight;
  final Offset from;
  final Offset to;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (flight >= 0.98) return const SizedBox.shrink();

    final t = Curves.easeInOutCubic.transform(flight.clamp(0.0, 1.0));
    final mid = Offset(
      (from.dx + to.dx) / 2,
      (from.dy < to.dy ? from.dy : to.dy) - 40,
    );
    final pos = JourneyTableLayout.quad(from, mid, to, t);
    final height = size / homeCardAspect;

    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - height / 2,
      width: size,
      height: height,
      child: JourneyFaceUpCard(
        assetPath: card.assetPath,
        world: card.world,
      ),
    );
  }
}
