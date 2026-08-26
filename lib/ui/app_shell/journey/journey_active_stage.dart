import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_face_card.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Empty center hint when no challenger is focused.
class JourneyActiveStage extends StatelessWidget {
  const JourneyActiveStage({
    super.key,
    required this.hasAvailableChallenger,
    this.visible = true,
  });

  final bool hasAvailableChallenger;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Opacity(
      opacity: visible ? 1 : 0,
      child: Center(
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
      ),
    );
  }
}

/// One continuous card object: pile → flip → grow → rewards peel to the right.
class JourneyChallengerFocus extends StatelessWidget {
  const JourneyChallengerFocus({
    super.key,
    required this.card,
    required this.progress,
    required this.from,
    required this.to,
    required this.fromSize,
    required this.toSize,
    this.startsFaceUp = false,
    this.onChallenge,
    this.onDismiss,
  });

  final JourneyCardDef card;
  final double progress;
  final Offset from;
  final Offset to;
  final double fromSize;
  final double toSize;
  /// Defeated cards (and drag handoffs) are already face-up.
  final bool startsFaceUp;
  final VoidCallback? onChallenge;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    // 0–0.52: travel + flip + size up
    // 0.52–0.68: hold at final size
    // 0.68–1.0: rewards card peels out to the right
    final travel = Curves.easeInOutCubic.transform(
      (progress / 0.52).clamp(0.0, 1.0),
    );
    final peel = Curves.easeOutCubic.transform(
      ((progress - 0.68) / 0.32).clamp(0.0, 1.0),
    );
    final mid = Offset(
      (from.dx + to.dx) / 2,
      (from.dy < to.dy ? from.dy : to.dy) - 36,
    );
    final pos = _quad(from, mid, to, travel);
    final size = fromSize + (toSize - fromSize) * travel;
    final height = size / homeCardAspect;
    final faceAmount = startsFaceUp
        ? 1.0
        : Curves.easeOut.transform(
            ((travel - 0.32) / 0.28).clamp(0.0, 1.0),
          );
    final interactive = progress > 0.92;

    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - height / 2,
      width: size + 28 * peel,
      height: height + 20 * peel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Rewards peels from under the challenger toward the right.
          if (peel > 0.01)
            Positioned(
              left: 10 * peel,
              top: 10 * peel,
              width: size,
              height: height,
              child: Transform.rotate(
                angle: 0.14 * peel,
                child: Opacity(
                  opacity: peel,
                  child: Transform.scale(
                    scale: 0.94 + 0.02 * peel,
                    child: _RewardsFace(card: card),
                  ),
                ),
              ),
            ),
          // Front challenger — same object for the whole motion.
          Positioned(
            left: 0,
            top: 0,
            width: size,
            height: height,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateY((1 - faceAmount) * 1.55),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: (1.0 - faceAmount).clamp(0.0, 1.0),
                    child: JourneyFaceDownCard(world: card.world, radius: 14),
                  ),
                  Opacity(
                    opacity: faceAmount.clamp(0.0, 1.0),
                    child: _ChallengeFace(
                      card: card,
                      showChrome: travel > 0.78,
                      onChallenge: interactive ? onChallenge : null,
                      onDismiss: interactive ? onDismiss : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }
}

class _ChallengeFace extends StatelessWidget {
  const _ChallengeFace({
    required this.card,
    this.showChrome = true,
    this.onChallenge,
    this.onDismiss,
  });

  final JourneyCardDef card;
  final bool showChrome;
  final VoidCallback? onChallenge;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(card.world);
    final theme = AppStyle.theme;
    final isAce = card.rank == JourneyRank.ace;

    return DecoratedBox(
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
            Image.asset(
              card.avatarAssetPath,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, _, _) => Image.asset(
                card.assetPath,
                fit: BoxFit.cover,
              ),
            ),
            if (showChrome && onDismiss != null)
              Positioned(
                top: 8,
                right: 8,
                child: CupertinoButton(
                  padding: const EdgeInsets.all(6),
                  minimumSize: Size.zero,
                  onPressed: SoundService.wrapTap(onDismiss),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 28,
                    color: palette.text.withValues(alpha: .85),
                  ),
                ),
              ),
            if (showChrome)
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
                    padding: const EdgeInsets.fromLTRB(14, 32, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.title,
                          style: theme.title.copyWith(
                            fontSize: 20,
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
                          isAce ? 'World summary' : card.gameLabel,
                          style: theme.body.copyWith(
                            color: palette.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          borderRadius: BorderRadius.circular(12),
                          color: palette.accent.withValues(alpha: .95),
                          minimumSize: Size.zero,
                          onPressed: onChallenge == null
                              ? null
                              : SoundService.wrapTap(onChallenge),
                          child: Text(
                            isAce ? 'Claim' : 'Challenge',
                            style: TextStyle(
                              color: palette.background,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

class _RewardsFace extends StatelessWidget {
  const _RewardsFace({required this.card});

  final JourneyCardDef card;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(card.world);
    final theme = AppStyle.theme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.cardBorder.withValues(alpha: .75)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'On defeat',
              style: theme.title.copyWith(
                fontSize: 17,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.caption.copyWith(
                color: palette.text.withValues(alpha: .7),
              ),
            ),
            const SizedBox(height: 14),
            _RewardRow(
              icon: CupertinoIcons.person_crop_circle,
              label: 'Avatar unlock',
              palette: palette,
            ),
            const SizedBox(height: 12),
            _RewardRow(
              icon: CupertinoIcons.paintbrush,
              label: '${card.world.label} theme',
              palette: palette,
            ),
            const SizedBox(height: 12),
            _RewardRow(
              icon: CupertinoIcons.star,
              label: card.rank == JourneyRank.ace
                  ? 'Ace collected'
                  : 'Journey progress',
              palette: palette,
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
        Icon(icon, size: 16, color: palette.accent.withValues(alpha: .9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: palette.text.withValues(alpha: .92),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
