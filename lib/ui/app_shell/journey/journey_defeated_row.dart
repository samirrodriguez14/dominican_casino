import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_board.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_face_card.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Bottom row: face-up defeated piles (a card lives here XOR in challengers).
class JourneyDefeatedRow extends StatelessWidget {
  const JourneyDefeatedRow({
    super.key,
    required this.snapshot,
    required this.dealPlan,
    this.sectionExpand = 1,
    this.defeatedDeal = 1,
    this.hidingCard,
    this.ghostCard,
    this.onDefeatedTap,
    this.onDefeatedPanStart,
    this.onDefeatedPanUpdate,
    this.onDefeatedPanEnd,
  });

  final JourneyDisplaySnapshot snapshot;
  final List<JourneyDealSlot> dealPlan;
  final double sectionExpand;
  final double defeatedDeal;
  final JourneyCardDef? hidingCard;
  /// Dragged card stays in-tree (ghosted) so pan gestures keep working.
  final JourneyCardDef? ghostCard;
  final ValueChanged<JourneyCardDef>? onDefeatedTap;
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
            ),
          ),
        ),
        const SizedBox(height: 8),
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
                      onDefeatedTap: onDefeatedTap,
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
    this.onDefeatedTap,
    this.onDefeatedPanStart,
    this.onDefeatedPanUpdate,
    this.onDefeatedPanEnd,
  });

  final JourneyWorldDef worldDef;
  final int landedCount;
  final JourneyCardDef? hidingCard;
  final JourneyCardDef? ghostCard;
  final ValueChanged<JourneyCardDef>? onDefeatedTap;
  final void Function(JourneyCardDef card, DragStartDetails details)?
      onDefeatedPanStart;
  final GestureDragUpdateCallback? onDefeatedPanUpdate;
  final GestureDragEndCallback? onDefeatedPanEnd;

  bool _same(JourneyCardDef? a, JourneyCardDef? b) =>
      a != null &&
      b != null &&
      a.world == b.world &&
      a.rank == b.rank;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(worldDef.world);
    // Keep ghostCard in the list so the pan detector isn't disposed mid-drag.
    final defeated = [
      for (final card in worldDef.defeatedCards)
        if (!_same(card, hidingCard)) card,
    ];
    final showCount = landedCount.clamp(0, defeated.length);
    final visible = defeated.take(showCount).toList();
    final top = visible.isNotEmpty ? visible.last : null;
    final draggingThis = _same(ghostCard, top);

    return AspectRatio(
      aspectRatio: homeCardAspect,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
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
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          if (visible.isNotEmpty)
            for (var i = 0; i < visible.length && i < 4; i++)
              Positioned(
                left: i * 2.8,
                top: i * 2.2,
                right: (visible.length.clamp(1, 4) - 1 - i) * 2.8,
                bottom: (visible.length.clamp(1, 4) - 1 - i) * 2.2,
                child: Opacity(
                  opacity: draggingThis && i == visible.length - 1 ? 0 : 1,
                  child: GestureDetector(
                    onTap: draggingThis
                        ? null
                        : () => onDefeatedTap?.call(visible[i]),
                    onPanStart: i == visible.length - 1 &&
                            top != null &&
                            onDefeatedPanStart != null
                        ? (details) => onDefeatedPanStart!(top, details)
                        : null,
                    onPanUpdate:
                        i == visible.length - 1 ? onDefeatedPanUpdate : null,
                    onPanEnd:
                        i == visible.length - 1 ? onDefeatedPanEnd : null,
                    child: JourneyFaceUpCard(
                      assetPath: visible[i].assetPath,
                      world: visible[i].world,
                      radius: 10,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
