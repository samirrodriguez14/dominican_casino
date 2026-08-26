import 'dart:math' as math;

import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter/cupertino.dart';

/// Timeline for the kingdom theme unlock ceremony (0 → 1).
///
/// 0.00–0.55 shake + scale · 0.55 boom · 0.55–1.00 reveal
class JourneyThemeUnlockTimeline {
  const JourneyThemeUnlockTimeline(this.t);

  final double t;

  static const shakeEnd = 0.55;
  static const boomAt = 0.55;
  static const revealEnd = 1.0;

  bool get pastBoom => t >= boomAt;

  /// Accelerating shake: frequency rises over the shake window.
  double get shakeRadians {
    if (t >= shakeEnd) return 0;
    final u = (t / shakeEnd).clamp(0.0, 1.0);
    final freq = 8 + 28 * u * u;
    final amp = 0.035 + 0.055 * u;
    return math.sin(u * freq * math.pi * 2) * amp;
  }

  /// Steady grow during shake, punch at boom, settle.
  double get scale {
    if (t < shakeEnd) {
      final u = t / shakeEnd;
      return 1.0 + 0.08 * Curves.easeIn.transform(u);
    }
    final after = ((t - boomAt) / (1 - boomAt)).clamp(0.0, 1.0);
    if (after < 0.18) {
      final punch = Curves.easeOut.transform(after / 0.18);
      return 1.08 + 0.12 * punch;
    }
    final settle = Curves.easeOut.transform(((after - 0.18) / 0.82).clamp(0.0, 1.0));
    return 1.20 - 0.12 * settle;
  }

  double get lockOpacity {
    if (t < boomAt) return 1;
    final fade = ((t - boomAt) / 0.18).clamp(0.0, 1.0);
    return (1.0 - Curves.easeIn.transform(fade)).clamp(0.0, 1.0);
  }

  double get revealAmount {
    if (t < boomAt) return 0;
    return Curves.easeOutCubic.transform(
      ((t - boomAt) / (1 - boomAt)).clamp(0.0, 1.0),
    );
  }

  /// Call unlock/equip when the boom hits.
  bool get shouldApplyTheme => t >= boomAt;
}

/// Dark sealed pad used during the ceremony overlay.
class JourneySealedPad extends StatelessWidget {
  const JourneySealedPad({
    super.key,
    this.active = false,
    this.lockSize = 20,
  });

  final bool active;
  final double lockSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1A1A1E),
        border: Border.all(
          color: active ? const Color(0xFF4A4A52) : const Color(0xFF2E2E34),
          width: active ? 1.4 : 1.1,
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.lock_fill,
          color: const Color(0x99FFFFFF),
          size: lockSize,
        ),
      ),
    );
  }
}

/// Kingdom face revealed after the lock breaks.
class JourneyThemeRevealFace extends StatelessWidget {
  const JourneyThemeRevealFace({
    super.key,
    required this.world,
    this.active = true,
  });

  final JourneyWorld world;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(world);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: palette.background,
        border: Border.all(
          color: active ? palette.accent : palette.cardBorder,
          width: active ? 1.6 : 1.1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surface,
            palette.background,
          ],
        ),
      ),
      child: Center(
        child: Text(
          world.suitSymbol,
          style: TextStyle(
            color: palette.accent,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Applies shake / scale / lock-break / reveal to a pile slot.
class JourneyThemeUnlockTransform extends StatelessWidget {
  const JourneyThemeUnlockTransform({
    super.key,
    required this.timeline,
    required this.child,
  });

  final JourneyThemeUnlockTimeline timeline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: timeline.shakeRadians,
      child: Transform.scale(
        scale: timeline.scale,
        child: child,
      ),
    );
  }
}
