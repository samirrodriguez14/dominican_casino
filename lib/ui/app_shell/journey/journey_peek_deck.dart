import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Small stacked deck peeking from the corner — four world ace backs.
class JourneyPeekDeck extends StatelessWidget {
  const JourneyPeekDeck({
    super.key,
    required this.onTap,
    this.progress = 0,
  });

  final VoidCallback onTap;
  final double progress;

  static const _peekAngle = 0.18;
  static const _cardRadius = 14.0;

  @override
  Widget build(BuildContext context) {
    const worlds = JourneyWorld.values;
    final scale = 1 - (progress * 0.15);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomLeft,
        child: AspectRatio(
          aspectRatio: homeCardAspect,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < worlds.length; i++)
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(i * 4.0, -i * 3.0),
                    child: Transform.rotate(
                      angle: _peekAngle * (i - 1.5) * 0.35,
                      child: _PeekCard(world: worlds[i], index: i),
                    ),
                  ),
                ),
              Positioned(
                left: 6,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Journey',
                      style: TextStyle(
                        color: Color(0xF0FFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
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

class _PeekCard extends StatelessWidget {
  const _PeekCard({required this.world, required this.index});

  final JourneyWorld world;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(world);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(JourneyPeekDeck._cardRadius),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: .75),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(JourneyPeekDeck._cardRadius - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.4 + index * 0.08,
              child: Image.asset(
                journeyAceAsset(world),
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: Text(
                world.suitSymbol,
                style: TextStyle(
                  color: palette.suitSymbol.withValues(alpha: .85),
                  fontSize: 18,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
