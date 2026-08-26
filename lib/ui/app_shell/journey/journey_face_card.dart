import 'dart:ui' show ImageFilter;

import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter/cupertino.dart';

/// Shared face-down Journey card — same object look for peek, deck, and flights.
class JourneyFaceDownCard extends StatelessWidget {
  const JourneyFaceDownCard({
    super.key,
    required this.world,
    this.dimmed = false,
    this.highlighted = false,
    this.radius = 12,
    this.showSuit = true,
    this.shadow = true,
  });

  final JourneyWorld world;
  final bool dimmed;
  final bool highlighted;
  final double radius;
  final bool showSuit;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(world);
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: highlighted
                ? palette.accent.withValues(alpha: .85)
                : palette.cardBorder.withValues(alpha: .7),
            width: highlighted ? 1.6 : 1.15,
          ),
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: .28),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: showSuit
            ? Center(
                child: Text(
                  world.suitSymbol,
                  style: TextStyle(
                    color: palette.suitSymbol.withValues(alpha: .62),
                    fontSize: 22,
                    height: 1,
                  ),
                ),
              )
            : Center(
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

/// Face-up challenger art — transparent cutout on a world-colored card back.
class JourneyFaceUpCard extends StatelessWidget {
  const JourneyFaceUpCard({
    super.key,
    required this.assetPath,
    required this.world,
    this.radius = 12,
    this.useTransparentAvatar = true,
  });

  final String assetPath;
  final JourneyWorld world;
  final double radius;
  /// When true, [assetPath] is treated as a cutout over [palette.surface].
  final bool useTransparentAvatar;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(world);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: palette.accent.withValues(alpha: .55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .28),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: ColoredBox(
          color: palette.surface,
          child: Image.asset(
            assetPath,
            fit: useTransparentAvatar ? BoxFit.contain : BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, _, _) => Center(
              child: Text(
                world.suitSymbol,
                style: TextStyle(
                  color: palette.suitSymbol.withValues(alpha: .5),
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Locked challenger: blurred avatar under a lock (next unlock tease).
class JourneyLockedChallengerCard extends StatelessWidget {
  const JourneyLockedChallengerCard({
    super.key,
    required this.assetPath,
    required this.world,
    this.highlighted = false,
    this.radius = 12,
    this.shadow = true,
    this.lockSize = 22,
  });

  final String assetPath;
  final JourneyWorld world;
  final bool highlighted;
  final double radius;
  final bool shadow;
  final double lockSize;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(world);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: highlighted
              ? palette.accent.withValues(alpha: .85)
              : palette.cardBorder.withValues(alpha: .7),
          width: highlighted ? 1.6 : 1.15,
        ),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .28),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: palette.surface),
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Opacity(
                opacity: 0.72,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      world.suitSymbol,
                      style: TextStyle(
                        color: palette.suitSymbol.withValues(alpha: .45),
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ColoredBox(color: palette.background.withValues(alpha: .38)),
            Center(
              child: Icon(
                CupertinoIcons.lock_fill,
                size: lockSize,
                color: const Color(0xE6FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Staggered left→right reveal for board section slots (not dealt from the deck).
double journeySlotExpand(double expand, int index, {int count = 4}) {
  final start = (index / count) * 0.62;
  final end = (start + 0.38).clamp(0.0, 1.0);
  if (expand <= start) return 0;
  if (expand >= end) return 1;
  return Curves.easeOutCubic.transform((expand - start) / (end - start));
}
