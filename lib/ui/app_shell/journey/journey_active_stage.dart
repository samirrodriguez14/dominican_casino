import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Center stage: empty hint or selected challenger + rewards peek.
class JourneyActiveStage extends StatelessWidget {
  const JourneyActiveStage({
    super.key,
    required this.selected,
    required this.hasAvailableChallenger,
    this.onChallenge,
    this.onDismiss,
  });

  final JourneyCardDef? selected;
  final bool hasAvailableChallenger;
  final VoidCallback? onChallenge;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (selected == null) {
      return _EmptyHint(hasAvailableChallenger: hasAvailableChallenger);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: _ChallengeCard(
            card: selected!,
            onChallenge: onChallenge,
            onDismiss: onDismiss,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: _RewardsCard(card: selected!),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.hasAvailableChallenger});

  final bool hasAvailableChallenger;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.rectangle_stack,
              size: 36,
              color: theme.muted.withValues(alpha: .55),
            ),
            const SizedBox(height: 12),
            Text(
              hasAvailableChallenger
                  ? 'Select a challenger'
                  : 'Play more games to level up',
              textAlign: TextAlign.center,
              style: theme.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              hasAvailableChallenger
                  ? 'Tap the top card of an unlocked world pile.'
                  : 'Or replay a defeated challenger when available.',
              textAlign: TextAlign.center,
              style: theme.mutedText.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.card,
    this.onChallenge,
    this.onDismiss,
  });

  final JourneyCardDef card;
  final VoidCallback? onChallenge;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(card.world);
    final theme = AppStyle.theme;
    final isAce = card.rank == JourneyRank.ace;

    return GestureDetector(
      onTap: onDismiss,
      child: AspectRatio(
        aspectRatio: homeCardAspect,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: palette.accent.withValues(alpha: .8),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: .2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: .3),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: palette.surface),
                Image.asset(card.assetPath, fit: BoxFit.cover),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.background.withValues(alpha: 0),
                          palette.background.withValues(alpha: .92),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            card.title,
                            style: theme.title.copyWith(
                              fontSize: 18,
                              color: palette.text,
                            ),
                          ),
                          if (card.blurb.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              card.blurb,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.caption.copyWith(
                                color: palette.text.withValues(alpha: .8),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            isAce ? 'World summary' : card.preferredGame,
                            style: theme.body.copyWith(
                              color: palette.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (!isAce) ...[
                            const SizedBox(height: 10),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              borderRadius: BorderRadius.circular(12),
                              color: palette.accent.withValues(alpha: .95),
                              minimumSize: Size.zero,
                              onPressed: onChallenge == null
                                  ? null
                                  : SoundService.wrapTap(onChallenge),
                              child: Text(
                                'Challenge',
                                style: TextStyle(
                                  color: palette.background,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({required this.card});

  final JourneyCardDef card;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(card.world);
    final theme = AppStyle.theme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder.withValues(alpha: .7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'On defeat',
              style: theme.title.copyWith(
                fontSize: 14,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: 10),
            _RewardRow(
              icon: CupertinoIcons.person_crop_circle,
              label: 'Avatar',
              palette: palette,
            ),
            const SizedBox(height: 8),
            _RewardRow(
              icon: CupertinoIcons.paintbrush,
              label: '${card.world.label} theme',
              palette: palette,
            ),
            const SizedBox(height: 8),
            _RewardRow(
              icon: CupertinoIcons.star,
              label: card.rank == JourneyRank.ace ? 'Ace collected' : 'Progress',
              palette: palette,
            ),
            const Spacer(),
            Text(
              'Swipe for details later',
              style: theme.caption.copyWith(
                color: palette.text.withValues(alpha: .45),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final JourneyWorldPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: palette.accent.withValues(alpha: .85)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: palette.text.withValues(alpha: .9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
