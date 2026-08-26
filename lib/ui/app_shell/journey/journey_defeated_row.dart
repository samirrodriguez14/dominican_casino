import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_board.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_face_card.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Bottom row: face-up defeated royals stacked per kingdom (tap opens center carousel).
class JourneyDefeatedRow extends StatelessWidget {
  const JourneyDefeatedRow({
    super.key,
    required this.snapshot,
    required this.dealPlan,
    this.sectionExpand = 1,
    this.defeatedDeal = 1,
    this.hidingCard,
    this.ghostCard,
    this.onDefeatedStackTap,
    this.onDefeatedPanStart,
    this.onDefeatedPanUpdate,
    this.onDefeatedPanEnd,
  });

  final JourneyDisplaySnapshot snapshot;
  final List<JourneyDealSlot> dealPlan;
  final double sectionExpand;
  final double defeatedDeal;
  final JourneyCardDef? hidingCard;
  final JourneyCardDef? ghostCard;
  final ValueChanged<JourneyWorld>? onDefeatedStackTap;
  final void Function(JourneyCardDef card, DragStartDetails details)?
      onDefeatedPanStart;
  final GestureDragUpdateCallback? onDefeatedPanUpdate;
  final GestureDragEndCallback? onDefeatedPanEnd;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final labelOpacity = sectionExpand.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: labelOpacity,
          child: Text(
            'Defeated',
            textAlign: TextAlign.center,
            style: theme.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.muted,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < JourneyWorld.values.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _ExpandSlot(
                    expand: journeySlotExpand(sectionExpand, i),
                    child: _DefeatedPile(
                      worldDef: snapshot.worldOf(JourneyWorld.values[i]),
                      landedCount: JourneyBoard.defeatedLandedCount(
                        dealPlan,
                        defeatedDeal,
                        JourneyWorld.values[i],
                      ),
                      hidingCard: hidingCard,
                      ghostCard: ghostCard,
                      onStackTap: onDefeatedStackTap,
                      onDefeatedPanStart: onDefeatedPanStart,
                      onDefeatedPanUpdate: onDefeatedPanUpdate,
                      onDefeatedPanEnd: onDefeatedPanEnd,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
        transform: Matrix4.diagonal3Values(0.28 + 0.72 * t, 0.9 + 0.1 * t, 1),
        child: child,
      ),
    );
  }
}

class _DefeatedPile extends StatelessWidget {
  const _DefeatedPile({
    required this.worldDef,
    required this.landedCount,
    this.hidingCard,
    this.ghostCard,
    this.onStackTap,
    this.onDefeatedPanStart,
    this.onDefeatedPanUpdate,
    this.onDefeatedPanEnd,
  });

  final JourneyWorldDef worldDef;
  final int landedCount;
  final JourneyCardDef? hidingCard;
  final JourneyCardDef? ghostCard;
  final ValueChanged<JourneyWorld>? onStackTap;
  final void Function(JourneyCardDef card, DragStartDetails details)?
      onDefeatedPanStart;
  final GestureDragUpdateCallback? onDefeatedPanUpdate;
  final GestureDragEndCallback? onDefeatedPanEnd;

  static const _fanDx = 7.0;
  static const _fanDy = 5.5;
  static const _cardScale = 0.78;

  bool _same(JourneyCardDef? a, JourneyCardDef? b) =>
      a != null &&
      b != null &&
      a.world == b.world &&
      a.rank == b.rank;

  @override
  Widget build(BuildContext context) {
    if (!worldDef.unlocked) {
      return AspectRatio(
        aspectRatio: homeCardAspect,
        child: FractionallySizedBox(
          widthFactor: _cardScale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF1A1A1E),
              border: Border.all(color: const Color(0xFF2E2E34)),
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.lock_fill,
                color: Color(0x66FFFFFF),
                size: 14,
              ),
            ),
          ),
        ),
      );
    }

    final palette = journeyPaletteFor(worldDef.world);
    final defeated = [
      for (final card in worldDef.defeatedRoyals)
        if (!_same(card, hidingCard)) card,
    ];
    final showCount = landedCount.clamp(0, defeated.length);
    final visible = defeated.take(showCount).toList();
    final top = visible.isNotEmpty ? visible.last : null;
    final draggingThis = _same(ghostCard, top);
    final stackCount = visible.length.clamp(0, 3);

    return AspectRatio(
      aspectRatio: homeCardAspect,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardW = constraints.maxWidth * _cardScale;
          final cardH = cardW / homeCardAspect;
          return GestureDetector(
            onTap: visible.isEmpty
                ? null
                : () => onStackTap?.call(worldDef.world),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: cardW,
                  height: cardH,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: palette.cardBorder.withValues(alpha: .4),
                      ),
                      color: palette.background.withValues(alpha: .32),
                    ),
                    child: Center(
                      child: Text(
                        worldDef.world.suitSymbol,
                        style: TextStyle(
                          color: palette.accent.withValues(alpha: .22),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                if (visible.isNotEmpty)
                  for (var i = 0; i < stackCount; i++)
                    Positioned(
                      left: i * _fanDx,
                      top: i * _fanDy,
                      width: cardW,
                      height: cardH,
                      child: Opacity(
                        opacity: draggingThis && i == stackCount - 1 ? 0 : 1,
                        child: GestureDetector(
                          onTap: () => onStackTap?.call(worldDef.world),
                          onPanStart: i == stackCount - 1 &&
                                  top != null &&
                                  onDefeatedPanStart != null
                              ? (details) => onDefeatedPanStart!(top, details)
                              : null,
                          onPanUpdate:
                              i == stackCount - 1 ? onDefeatedPanUpdate : null,
                          onPanEnd:
                              i == stackCount - 1 ? onDefeatedPanEnd : null,
                          child: JourneyFaceUpCard(
                            assetPath: visible[i].avatarAssetPath,
                            world: visible[i].world,
                            radius: 8,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
