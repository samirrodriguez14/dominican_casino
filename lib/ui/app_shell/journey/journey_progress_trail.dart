import 'dart:math' as math;

import 'package:dominican_casino/models/journey_progress.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_motion.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
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
    this.tokenScale = 1,
    this.onAvatarTap,
    this.height = 52,
  });

  final JourneyProgress progress;
  /// 0…15 — milestone the avatar token sits on.
  final int tokenStepIndex;
  final JourneyWorld? activeWorld;
  final GlobalKey? tokenKey;
  /// Bubble scale for eat/spit pulse (1 = idle).
  final double tokenScale;
  /// When set, replaces the default trophies-popup open.
  final VoidCallback? onAvatarTap;
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
                child: Transform.scale(
                  scale: tokenScale,
                  child: KeyedSubtree(
                    key: tokenKey,
                    child: GestureDetector(
                      onTap: SoundService.wrapTap(() {
                        AppHaptics.lightImpact();
                        if (onAvatarTap != null) {
                          onAvatarTap!();
                          return;
                        }
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
                        wearJourneyAccessories: repo.wearJourneyAccessories,
                      ),
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

/// Popup: avatar with Ace trophies — Ace card art when owned, lock when not.
///
/// When [sourceKey] is set, opens/closes with eat/spit fly-to that target and
/// calls [onSourcePulse] near swallow/spit. Otherwise uses a simple fade/scale.
Future<void> showJourneyAceAccessoriesPopup(
  BuildContext context, {
  required String? avatarId,
  required Set<JourneyWorld> defeatedAces,
  GlobalKey? sourceKey,
  VoidCallback? onSourcePulse,
  JourneyWorld? revealWorld,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x00000000),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (ctx, _, _) => _JourneyTrophiesOverlay(
        avatarId: avatarId,
        defeatedAces: defeatedAces,
        sourceKey: sourceKey,
        onSourcePulse: onSourcePulse,
        revealWorld: revealWorld,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

class _JourneyTrophiesOverlay extends StatefulWidget {
  const _JourneyTrophiesOverlay({
    required this.avatarId,
    required this.defeatedAces,
    required this.onClose,
    this.sourceKey,
    this.onSourcePulse,
    this.revealWorld,
  });

  final String? avatarId;
  final Set<JourneyWorld> defeatedAces;
  final GlobalKey? sourceKey;
  final VoidCallback? onSourcePulse;
  final JourneyWorld? revealWorld;
  final VoidCallback onClose;

  @override
  State<_JourneyTrophiesOverlay> createState() =>
      _JourneyTrophiesOverlayState();
}

class _JourneyTrophiesOverlayState extends State<_JourneyTrophiesOverlay>
    with TickerProviderStateMixin {
  static const _openDuration = Duration(milliseconds: 520);
  static const _closeDuration = Duration(milliseconds: 480);
  static const _revealDuration = Duration(milliseconds: 640);

  /// 0 = fully open (spit), 1 = eaten into source.
  late final AnimationController _eat;
  late final AnimationController _reveal;
  late final AnimationController _fade;

  bool _closing = false;
  bool _pulsed = false;
  bool _revealStarted = false;
  bool _dismissed = false;

  bool get _useFly => widget.sourceKey != null;

  @override
  void initState() {
    super.initState();
    _eat = AnimationController(vsync: this, duration: _openDuration);
    _reveal = AnimationController(vsync: this, duration: _revealDuration);
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _eat.addListener(_onEatTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _eat.removeListener(_onEatTick);
    _eat.dispose();
    _reveal.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _onEatTick() {
    if (!_useFly || _pulsed) return;
    final eat = _eat.value;
    // Spit open (eat 1→0): pulse as the card leaves the avatar.
    // Eat close (eat 0→1): pulse as the card is swallowed.
    if (!_closing && eat < 0.88) {
      _pulsed = true;
      widget.onSourcePulse?.call();
      AppHaptics.mediumImpact();
    } else if (_closing && eat >= 0.88) {
      _pulsed = true;
      widget.onSourcePulse?.call();
      AppHaptics.mediumImpact();
    }
  }

  Future<void> _open() async {
    if (!mounted) return;
    SoundService.instance.playLayered(GameSound.softCard);
    if (_useFly) {
      _eat.value = 1;
      _fade.value = 1;
      _pulsed = false;
      await _eat.animateTo(0, curve: Curves.easeInOutCubic);
    } else {
      _eat.value = 0;
      await _fade.forward();
    }
    if (!mounted) return;
    _maybeStartReveal();
  }

  void _maybeStartReveal() {
    if (_revealStarted || widget.revealWorld == null) return;
    _revealStarted = true;
    AppHaptics.lightImpact();
    _reveal.forward(from: 0);
  }

  Future<void> _dismiss() async {
    if (_closing || _dismissed) return;
    _closing = true;
    _pulsed = false;
    SoundService.instance.playLayered(GameSound.softCard);
    if (_useFly) {
      _eat.duration = _closeDuration;
      await _eat.animateTo(1, curve: Curves.easeInOutCubic);
    } else {
      await _fade.reverse();
    }
    if (!mounted) return;
    _dismissed = true;
    widget.onClose();
  }

  Offset? _sourceCenter(Size stage) {
    final key = widget.sourceKey;
    if (key == null) return null;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) return null;
    final global = box.localToGlobal(box.size.center(Offset.zero));
    return overlayBox.globalToLocal(global);
  }

  bool _isOwned(JourneyWorld world) {
    if (!widget.defeatedAces.contains(world)) return false;
    if (widget.revealWorld == world) {
      return _reveal.value >= 0.98;
    }
    return true;
  }

  double _revealT(JourneyWorld world) {
    if (widget.revealWorld != world) {
      return widget.defeatedAces.contains(world) ? 1 : 0;
    }
    return Curves.easeOutBack.transform(_reveal.value.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    const avatarSize = 96.0;
    const slot = 36.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_eat, _reveal, _fade]),
      builder: (context, _) {
        final size = MediaQuery.sizeOf(context);
        final eat = _useFly ? _eat.value : 0.0;
        final source = _sourceCenter(size);
        final delta = (_useFly && source != null)
            ? JourneyTableLayout.flyToTargetDelta(
                eat: eat,
                stage: size,
                targetCenter: source,
              )
            : Offset.zero;
        // Spit open uses the "closing" scale curve (grow from tiny);
        // eat-in uses the open curve (shrink into source).
        final scale = _useFly
            ? JourneyTimeline.gameScale(eat: eat, closing: !_closing)
            : (0.88 + 0.12 * Curves.easeOutBack.transform(_fade.value));
        final barrierAlpha = _useFly
            ? (0.45 * (1.0 - eat).clamp(0.0, 1.0))
            : (0.45 * _fade.value);
        final cardOpacity = _useFly
            ? (eat < 0.92 ? 1.0 : 0.0)
            : _fade.value;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _dismiss();
          },
          child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: SoundService.wrapTap(_dismiss),
                child: ColoredBox(
                  color: CupertinoColors.black.withValues(alpha: barrierAlpha),
                ),
              ),
            ),
            Center(
              child: Opacity(
                opacity: cardOpacity,
                child: Transform.translate(
                  offset: delta,
                  child: Transform.scale(
                    scale: math.max(0.03, scale),
                    alignment: Alignment.center,
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
                              color: CupertinoColors.black.withValues(
                                alpha: .28,
                              ),
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
                                      avatarId: widget.avatarId,
                                      size: avatarSize,
                                      showBorder: true,
                                      showJourneyAces: false,
                                    ),
                                    for (final world in JourneyWorld.values)
                                      Positioned(
                                        top: world == JourneyWorld.diamonds
                                            ? 0
                                            : null,
                                        bottom: world == JourneyWorld.hearts
                                            ? 0
                                            : null,
                                        left: world == JourneyWorld.spades
                                            ? 0
                                            : null,
                                        right: world == JourneyWorld.clubs
                                            ? 0
                                            : null,
                                        child: _TrophyCornerSlot(
                                          world: world,
                                          size: slot,
                                          owned: _isOwned(world),
                                          revealT: _revealT(world),
                                          revealing:
                                              widget.revealWorld == world,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  for (final world in JourneyWorld.values)
                                    _AceTrophyLegend(
                                      world: world,
                                      owned: _isOwned(world),
                                      revealT: _revealT(world),
                                      revealing: widget.revealWorld == world,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 10,
                                ),
                                color: theme.textPrimary.withValues(
                                  alpha: .12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                onPressed: SoundService.wrapTap(_dismiss),
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
                  ),
                ),
              ),
            ),
          ],
        ),
        );
      },
    );
  }
}

class _TrophyCornerSlot extends StatelessWidget {
  const _TrophyCornerSlot({
    required this.world,
    required this.size,
    required this.owned,
    required this.revealT,
    required this.revealing,
  });

  final JourneyWorld world;
  final double size;
  final bool owned;
  final double revealT;
  final bool revealing;

  @override
  Widget build(BuildContext context) {
    if (!revealing) {
      return owned
          ? _AceTrophyBadge(world: world, size: size)
          : _LockedTrophySlot(world: world, size: size);
    }
    // Cross-fade lock → badge with a scale pop.
    final t = revealT.clamp(0.0, 1.0);
    final pop = 0.85 + 0.25 * Curves.easeOutBack.transform(t);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: (1.0 - t).clamp(0.0, 1.0),
            child: _LockedTrophySlot(world: world, size: size),
          ),
          Opacity(
            opacity: t,
            child: Transform.scale(
              scale: pop,
              child: _AceTrophyBadge(world: world, size: size),
            ),
          ),
        ],
      ),
    );
  }
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
  const _AceTrophyLegend({
    required this.world,
    required this.owned,
    this.revealT = 1,
    this.revealing = false,
  });

  final JourneyWorld world;
  final bool owned;
  final double revealT;
  final bool revealing;

  static const _cardW = 36.0;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final showOwned = revealing ? revealT >= 0.98 : owned;
    final t = revealing ? revealT.clamp(0.0, 1.0) : (owned ? 1.0 : 0.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _cardW,
          height: _cardW / homeCardAspect,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1.0 - t).clamp(0.0, 1.0),
                child: _AceLegendCard(world: world, owned: false),
              ),
              Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: revealing
                      ? (0.85 + 0.25 * Curves.easeOutBack.transform(t))
                      : 1,
                  child: _AceLegendCard(world: world, owned: true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          showOwned ? 'Owned' : 'Locked',
          style: theme.caption.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: showOwned ? theme.textPrimary : theme.muted,
          ),
        ),
      ],
    );
  }
}

class _AceLegendCard extends StatelessWidget {
  const _AceLegendCard({required this.world, required this.owned});

  final JourneyWorld world;
  final bool owned;

  static const _cardW = 36.0;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(world);
    final h = _cardW / homeCardAspect;
    return Container(
      width: _cardW,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: owned ? palette.surface : const Color(0xFF1A1A1E),
        border: Border.all(
          color: owned
              ? palette.accent.withValues(alpha: .85)
              : palette.accent.withValues(alpha: .28),
          width: 1.2,
        ),
        boxShadow: owned
            ? [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .28),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: owned
          ? Image.asset(
              world.aceCardAssetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(color: palette.surface),
            )
          : Icon(
              CupertinoIcons.lock_fill,
              size: 14,
              color: palette.accent.withValues(alpha: .45),
            ),
    );
  }
}
