import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_board.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_face_card.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Four world piles across the top of the Journey board.
class JourneyWorldPiles extends StatelessWidget {
  const JourneyWorldPiles({
    super.key,
    required this.snapshot,
    required this.dealPlan,
    required this.activeWorld,
    required this.selectedCard,
    this.ghostCard,
    this.revealCard,
    this.revealProgress = 1,
    this.sectionExpand = 1,
    this.pileDeal = 1,
    this.onWorldTap,
    this.onTopCardTap,
    this.onTopCardPanStart,
    this.onTopCardPanUpdate,
    this.onTopCardPanEnd,
  });

  final JourneyDisplaySnapshot snapshot;
  final List<JourneyDealSlot> dealPlan;
  final JourneyWorld activeWorld;
  final JourneyCardDef? selectedCard;
  /// Card being dragged — stays in the pile tree (invisible) so pan continues.
  final JourneyCardDef? ghostCard;
  /// Newly unlocked top card flipping face-up after a defeat.
  final JourneyCardDef? revealCard;
  final double revealProgress;
  final double sectionExpand;
  final double pileDeal;
  final ValueChanged<JourneyWorld>? onWorldTap;
  final ValueChanged<JourneyCardDef>? onTopCardTap;
  final void Function(JourneyCardDef card, DragStartDetails details)?
      onTopCardPanStart;
  final GestureDragUpdateCallback? onTopCardPanUpdate;
  final GestureDragEndCallback? onTopCardPanEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < JourneyWorld.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _ExpandSlot(
              expand: journeySlotExpand(sectionExpand, i),
              child: _WorldPile(
                worldDef: snapshot.worldOf(JourneyWorld.values[i]),
                active: JourneyWorld.values[i] == activeWorld,
                selectedCard: selectedCard,
                ghostCard: ghostCard,
                revealCard: revealCard,
                revealProgress: revealProgress,
                landedDepth: JourneyBoard.challengerLandedDepth(
                  dealPlan,
                  pileDeal,
                  JourneyWorld.values[i],
                ),
                onWorldTap: onWorldTap,
                onTopCardTap: onTopCardTap,
                onTopCardPanStart: onTopCardPanStart,
                onTopCardPanUpdate: onTopCardPanUpdate,
                onTopCardPanEnd: onTopCardPanEnd,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ExpandSlot extends StatelessWidget {
  const _ExpandSlot({required this.expand, required this.child});

  final double expand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = expand.clamp(0.0, 1.0);
    return Opacity(
      opacity: t,
      child: Transform(
        alignment: Alignment.centerLeft,
        transform: Matrix4.diagonal3Values(0.35 + 0.65 * t, 0.92 + 0.08 * t, 1),
        child: child,
      ),
    );
  }
}

class _WorldPile extends StatelessWidget {
  const _WorldPile({
    required this.worldDef,
    required this.active,
    required this.selectedCard,
    required this.landedDepth,
    this.ghostCard,
    this.revealCard,
    this.revealProgress = 1,
    this.onWorldTap,
    this.onTopCardTap,
    this.onTopCardPanStart,
    this.onTopCardPanUpdate,
    this.onTopCardPanEnd,
  });

  final JourneyWorldDef worldDef;
  final bool active;
  final JourneyCardDef? selectedCard;
  final JourneyCardDef? ghostCard;
  final JourneyCardDef? revealCard;
  final double revealProgress;
  final int landedDepth;
  final ValueChanged<JourneyWorld>? onWorldTap;
  final ValueChanged<JourneyCardDef>? onTopCardTap;
  final void Function(JourneyCardDef card, DragStartDetails details)?
      onTopCardPanStart;
  final GestureDragUpdateCallback? onTopCardPanUpdate;
  final GestureDragEndCallback? onTopCardPanEnd;

  bool _same(JourneyCardDef? a, JourneyCardDef? b) =>
      a != null &&
      b != null &&
      a.world == b.world &&
      a.rank == b.rank;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(worldDef.world);
    final theme = AppStyle.theme;
    final remaining = [
      for (final card in worldDef.pileCards)
        if (!_same(card, selectedCard)) card,
    ];
    final maxDepth = worldDef.unlocked
        ? remaining.length.clamp(0, JourneyBoard.cardsPerPile)
        : JourneyBoard.cardsPerPile;
    final showDepth = landedDepth.clamp(0, maxDepth);
    // Deal order for landing; available moved to visual top when present.
    final visible = remaining.take(showDepth).toList();
    final lockedVisible = [
      for (final card in visible)
        if (card.state != JourneyCardState.available) card,
    ];
    final availableVisible = [
      for (final card in visible)
        if (card.state == JourneyCardState.available) card,
    ];
    final pile = [...lockedVisible, ...availableVisible];
    final top = worldDef.unlocked ? worldDef.nextSelectable : null;
    final canPickTop =
        top != null && top.isSelectable && selectedCard == null;
    final draggingThis = _same(ghostCard, top);
    final revealingThis = _same(revealCard, top);
    final topAvailableOnPile =
        availableVisible.isNotEmpty && !draggingThis;
    final cardVisible = showDepth > 0;
    final panActive = canPickTop || draggingThis;

    return GestureDetector(
      onTap: cardVisible && !draggingThis
          ? () {
              if (!worldDef.unlocked) {
                onWorldTap?.call(worldDef.world);
                return;
              }
              if (canPickTop) {
                onTopCardTap?.call(top);
              } else if (selectedCard?.world == worldDef.world) {
                onTopCardTap?.call(selectedCard!);
              } else {
                onWorldTap?.call(worldDef.world);
              }
            }
          : null,
      onPanStart: panActive && top != null && onTopCardPanStart != null
          ? (details) => onTopCardPanStart!(top, details)
          : null,
      onPanUpdate: panActive ? onTopCardPanUpdate : null,
      onPanEnd: panActive ? onTopCardPanEnd : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = width / homeCardAspect;
                final cardH = height.clamp(0.0, constraints.maxHeight);
                final cardW = cardH * homeCardAspect;
                return Center(
                  child: SizedBox(
                    width: cardW,
                    height: cardH,
                    child: Opacity(
                      // Ghost the pile while the floating drag card is shown.
                      opacity: draggingThis ? 0 : 1,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: palette.cardBorder
                                      .withValues(alpha: .35),
                                ),
                                color:
                                    palette.background.withValues(alpha: .28),
                              ),
                              child: Center(
                                child: Text(
                                  worldDef.world.suitSymbol,
                                  style: TextStyle(
                                    color:
                                        palette.accent.withValues(alpha: .22),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (pile.isNotEmpty) ...[
                            for (var i = 0; i < pile.length; i++)
                              Positioned(
                                left: i * 2.2,
                                top: i * 1.8,
                                right: (pile.length - 1 - i) * 2.2,
                                bottom: (pile.length - 1 - i) * 1.8,
                                child: i == pile.length - 1 &&
                                        topAvailableOnPile
                                    ? _PileTopFace(
                                        card: availableVisible.last,
                                        world: worldDef.world,
                                        active: active,
                                        faceAmount: revealingThis
                                            ? revealProgress.clamp(0.0, 1.0)
                                            : 1.0,
                                      )
                                    : JourneyFaceDownCard(
                                        world: worldDef.world,
                                        dimmed: !worldDef.unlocked,
                                        highlighted: active &&
                                            worldDef.unlocked &&
                                            i == pile.length - 1 &&
                                            selectedCard == null &&
                                            !draggingThis &&
                                            !topAvailableOnPile,
                                        showSuit: i == pile.length - 1,
                                        shadow: i == pile.length - 1,
                                      ),
                              ),
                            if (!worldDef.unlocked)
                              const Center(
                                child: Icon(
                                  CupertinoIcons.lock_fill,
                                  color: Color(0xD9FFFFFF),
                                  size: 18,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: cardVisible ? 1 : 0.45,
            child: Text(
              '${worldDef.world.suitSymbol} ${worldDef.world.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.caption.copyWith(
                color: active && worldDef.unlocked && cardVisible
                    ? palette.accent
                    : theme.muted,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Face-up (or flipping) top challenger on an unlocked pile.
class _PileTopFace extends StatelessWidget {
  const _PileTopFace({
    required this.card,
    required this.world,
    required this.active,
    required this.faceAmount,
  });

  final JourneyCardDef card;
  final JourneyWorld world;
  final bool active;
  final double faceAmount;

  @override
  Widget build(BuildContext context) {
    final face = faceAmount.clamp(0.0, 1.0);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0014)
        ..rotateY((1 - face) * 1.55),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: (1.0 - face).clamp(0.0, 1.0),
            child: JourneyFaceDownCard(
              world: world,
              highlighted: active,
              showSuit: true,
              shadow: true,
            ),
          ),
          Opacity(
            opacity: face.clamp(0.0, 1.0),
            child: JourneyFaceUpCard(
              assetPath: card.assetPath,
              world: world,
            ),
          ),
        ],
      ),
    );
  }
}
