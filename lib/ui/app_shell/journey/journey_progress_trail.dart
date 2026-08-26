import 'package:dominican_casino/models/journey_progress.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Compact four-kingdom trail with per-card milestones and an avatar token.
class JourneyProgressTrail extends StatelessWidget {
  const JourneyProgressTrail({
    super.key,
    required this.progress,
    required this.tokenStepIndex,
    this.activeWorld,
    this.tokenKey,
    this.height = 52,
  });

  final JourneyProgress progress;
  /// 0…15 — milestone the avatar token sits on.
  final int tokenStepIndex;
  final JourneyWorld? activeWorld;
  final GlobalKey? tokenKey;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final repo = context.watch<AppRepo>();
    final steps = progress.trailStepsCompleted;
    final fillT = steps / journeyTrailStepCount;
    final aces = progress.defeatedAceWorlds;
    final step = tokenStepIndex.clamp(0, journeyTrailStepCount - 1);
    final markerWorld = activeWorld ?? JourneyWorld.values[step ~/ 4];

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final pad = 10.0;
          final trackLeft = pad;
          final trackRight = w - pad;
          final trackW = trackRight - trackLeft;
          final tokenSize = 30.0;
          final tokenT = (step + 0.5) / journeyTrailStepCount;
          final tokenX = trackLeft + trackW * tokenT;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Track — fill reflects overall progress so far.
              Positioned(
                left: trackLeft,
                right: pad,
                top: height * 0.48,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: theme.textPrimary.withValues(alpha: .12),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fillT.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: theme.textPrimary.withValues(alpha: .38),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Milestones: 16 card ticks; every 4th is a kingdom gate.
              for (var i = 0; i < journeyTrailStepCount; i++)
                Positioned(
                  left: trackLeft +
                      trackW * ((i + 0.5) / journeyTrailStepCount) -
                      (i % 4 == 3 ? 5.5 : 2.5),
                  top: height * 0.48 - (i % 4 == 3 ? 5.5 : 2.5),
                  child: _MilestoneDot(
                    filled: i < steps,
                    kingdomGate: i % 4 == 3,
                    world: JourneyWorld.values[i ~/ 4],
                  ),
                ),
              // Kingdom icons — lock until entered.
              for (var wi = 0; wi < JourneyWorld.values.length; wi++)
                Positioned(
                  left: trackLeft +
                      trackW * ((wi + 0.5) / JourneyWorld.values.length) -
                      10,
                  bottom: 0,
                  width: 20,
                  child: _KingdomMarker(
                    world: JourneyWorld.values[wi],
                    unlocked: progress.hasEntered(JourneyWorld.values[wi]),
                    active: JourneyWorld.values[wi] == markerWorld,
                  ),
                ),
              // Avatar token
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                left: tokenX - tokenSize / 2,
                top: height * 0.48 - tokenSize / 2 - 2,
                width: tokenSize,
                height: tokenSize,
                child: KeyedSubtree(
                  key: tokenKey,
                  child: GestureDetector(
                    onTap: SoundService.wrapTap(() {
                      AppHaptics.lightImpact();
                      showJourneyAceAccessoriesPopup(
                        context,
                        avatarId: repo.player?.avatarId,
                        defeatedAces: aces,
                      );
                    }),
                    child: PlayerAvatarView(
                      avatarId: repo.player?.avatarId,
                      size: tokenSize,
                      showBorder: true,
                      showJourneyAces: true,
                      defeatedAces: aces,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MilestoneDot extends StatelessWidget {
  const _MilestoneDot({
    required this.filled,
    required this.kingdomGate,
    required this.world,
  });

  final bool filled;
  final bool kingdomGate;
  final JourneyWorld world;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(world);
    final size = kingdomGate ? 11.0 : 5.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? (kingdomGate ? palette.accent : palette.accentSecondary)
            : const Color(0xFF2A2A30),
        border: Border.all(
          color: filled
              ? palette.accent.withValues(alpha: .9)
              : const Color(0xFF3A3A42),
          width: kingdomGate ? 1.2 : 0.8,
        ),
      ),
    );
  }
}

class _KingdomMarker extends StatelessWidget {
  const _KingdomMarker({
    required this.world,
    required this.unlocked,
    required this.active,
  });

  final JourneyWorld world;
  final bool unlocked;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final palette = journeyPaletteFor(world);
    if (!unlocked) {
      return Icon(
        CupertinoIcons.lock_fill,
        size: 12,
        color: theme.muted.withValues(alpha: .55),
      );
    }
    return Text(
      world.suitSymbol,
      textAlign: TextAlign.center,
      style: theme.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: active ? palette.accent : theme.muted.withValues(alpha: .8),
      ),
    );
  }
}

/// Popup: avatar with Ace trophies — Ace card art when owned, lock (no suit) when not.
Future<void> showJourneyAceAccessoriesPopup(
  BuildContext context, {
  required String? avatarId,
  required Set<JourneyWorld> defeatedAces,
}) {
  final theme = AppStyle.theme;
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      const avatarSize = 96.0;
      const slot = 36.0;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.textPrimary.withValues(alpha: .14),
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .28),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Journey trophies',
                    style: theme.title.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Claim Aces on your Journey to fill each trophy slot.',
                    textAlign: TextAlign.center,
                    style: theme.mutedText,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: avatarSize + slot * 1.8,
                    height: avatarSize + slot * 1.8,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        PlayerAvatarView(
                          avatarId: avatarId,
                          size: avatarSize,
                          showBorder: true,
                          showJourneyAces: false,
                        ),
                        for (final world in JourneyWorld.values)
                          Positioned(
                            top: world == JourneyWorld.diamonds ? 0 : null,
                            bottom: world == JourneyWorld.hearts ? 0 : null,
                            left: world == JourneyWorld.spades ? 0 : null,
                            right: world == JourneyWorld.clubs ? 0 : null,
                            child: defeatedAces.contains(world)
                                ? _AceTrophyBadge(world: world, size: slot)
                                : _LockedTrophySlot(world: world, size: slot),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final world in JourneyWorld.values)
                        _AceTrophyLegend(
                          world: world,
                          owned: defeatedAces.contains(world),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    color: theme.textPrimary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: SoundService.wrapTap(
                      () => Navigator.of(ctx).pop(),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _AceTrophyBadge extends StatelessWidget {
  const _AceTrophyBadge({required this.world, required this.size});

  final JourneyWorld world;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(world);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surface,
        border: Border.all(
          color: palette.accent.withValues(alpha: .85),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          world.aceCardAssetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(color: palette.surface),
        ),
      ),
    );
  }
}

/// Locked trophy: no suit glyph — lock only.
class _LockedTrophySlot extends StatelessWidget {
  const _LockedTrophySlot({required this.world, required this.size});

  final JourneyWorld world;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(world);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1A1E),
        border: Border.all(
          color: palette.accent.withValues(alpha: .28),
          width: 1.2,
        ),
      ),
      child: Icon(
        CupertinoIcons.lock_fill,
        size: size * 0.42,
        color: palette.accent.withValues(alpha: .45),
      ),
    );
  }
}

class _AceTrophyLegend extends StatelessWidget {
  const _AceTrophyLegend({required this.world, required this.owned});

  final JourneyWorld world;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        owned
            ? _AceTrophyBadge(world: world, size: 28)
            : _LockedTrophySlot(world: world, size: 28),
        const SizedBox(height: 4),
        Text(
          owned ? 'Owned' : 'Locked',
          style: theme.caption.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: owned ? theme.textPrimary : theme.muted,
          ),
        ),
      ],
    );
  }
}
