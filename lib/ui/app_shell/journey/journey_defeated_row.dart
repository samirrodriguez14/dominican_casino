import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Bottom row: four defeated slots (one per world).
class JourneyDefeatedRow extends StatelessWidget {
  const JourneyDefeatedRow({
    super.key,
    required this.snapshot,
    this.onDefeatedTap,
  });

  final JourneyDisplaySnapshot snapshot;
  final ValueChanged<JourneyCardDef>? onDefeatedTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Defeated',
          textAlign: TextAlign.center,
          style: theme.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.muted,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < JourneyWorld.values.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _DefeatedSlot(
                    worldDef: snapshot.worldOf(JourneyWorld.values[i]),
                    onDefeatedTap: onDefeatedTap,
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

class _DefeatedSlot extends StatelessWidget {
  const _DefeatedSlot({required this.worldDef, this.onDefeatedTap});

  final JourneyWorldDef worldDef;
  final ValueChanged<JourneyCardDef>? onDefeatedTap;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(worldDef.world);
    final defeated = worldDef.defeatedCards;

    return AspectRatio(
      aspectRatio: homeCardAspect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: palette.cardBorder.withValues(alpha: .45),
            width: 1.2,
          ),
          color: palette.background.withValues(alpha: .35),
        ),
        child: defeated.isEmpty
            ? Center(
                child: Text(
                  worldDef.world.suitSymbol,
                  style: TextStyle(
                    color: palette.accent.withValues(alpha: .28),
                    fontSize: 18,
                  ),
                ),
              )
            : Stack(
                children: [
                  for (var i = 0; i < defeated.length && i < 3; i++)
                    Positioned(
                      left: i * 3.0,
                      top: i * 2.5,
                      right: (defeated.length.clamp(1, 3) - 1 - i) * 3.0,
                      bottom: (defeated.length.clamp(1, 3) - 1 - i) * 2.5,
                      child: GestureDetector(
                        onTap: () => onDefeatedTap?.call(defeated[i]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            defeated[i].assetPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
