import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Four face-down world piles across the top of the Journey board.
class JourneyWorldPiles extends StatelessWidget {
  const JourneyWorldPiles({
    super.key,
    required this.snapshot,
    required this.activeWorld,
    required this.selectedCard,
    this.onWorldTap,
    this.onTopCardTap,
  });

  final JourneyDisplaySnapshot snapshot;
  final JourneyWorld activeWorld;
  final JourneyCardDef? selectedCard;
  final ValueChanged<JourneyWorld>? onWorldTap;
  final ValueChanged<JourneyCardDef>? onTopCardTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < JourneyWorld.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _WorldPile(
              worldDef: snapshot.worldOf(JourneyWorld.values[i]),
              active: JourneyWorld.values[i] == activeWorld,
              selectedCard: selectedCard,
              onWorldTap: onWorldTap,
              onTopCardTap: onTopCardTap,
            ),
          ),
        ],
      ],
    );
  }
}

class _WorldPile extends StatelessWidget {
  const _WorldPile({
    required this.worldDef,
    required this.active,
    required this.selectedCard,
    this.onWorldTap,
    this.onTopCardTap,
  });

  final JourneyWorldDef worldDef;
  final bool active;
  final JourneyCardDef? selectedCard;
  final ValueChanged<JourneyWorld>? onWorldTap;
  final ValueChanged<JourneyCardDef>? onTopCardTap;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(worldDef.world);
    final theme = AppStyle.theme;
    final pile = [
      for (final card in worldDef.pileCards)
        if (selectedCard == null ||
            card.world != selectedCard!.world ||
            card.rank != selectedCard!.rank)
          card,
    ];
    final depth = worldDef.unlocked ? pile.length.clamp(1, 3) : 3;
    final top = worldDef.unlocked ? worldDef.nextSelectable : null;
    final canPickTop = top != null && top.isSelectable;

    return GestureDetector(
      onTap: () {
        if (!worldDef.unlocked) {
          onWorldTap?.call(worldDef.world);
          return;
        }
        if (canPickTop) {
          onTopCardTap?.call(top);
        } else {
          onWorldTap?.call(worldDef.world);
        }
      },
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
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < depth; i++)
                          Positioned(
                            left: i * 2.5,
                            top: i * 2.0,
                            right: (depth - 1 - i) * 2.5,
                            bottom: (depth - 1 - i) * 2.0,
                            child: _FaceDownBack(
                              palette: palette,
                              dimmed: !worldDef.unlocked,
                              highlighted: active &&
                                  worldDef.unlocked &&
                                  i == depth - 1,
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
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${worldDef.world.suitSymbol} ${worldDef.world.label}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.caption.copyWith(
              color: active && worldDef.unlocked
                  ? palette.accent
                  : theme.muted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceDownBack extends StatelessWidget {
  const _FaceDownBack({
    required this.palette,
    this.dimmed = false,
    this.highlighted = false,
  });

  final JourneyWorldPalette palette;
  final bool dimmed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted
                ? palette.accent.withValues(alpha: .85)
                : palette.cardBorder.withValues(alpha: .65),
            width: highlighted ? 1.6 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .22),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.rectangle_fill_on_rectangle_angled_fill,
            size: 16,
            color: palette.accent.withValues(alpha: dimmed ? 0.25 : 0.4),
          ),
        ),
      ),
    );
  }
}
