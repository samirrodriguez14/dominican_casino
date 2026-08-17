import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Cosmetic gather → wash → square overlay. Not the CardMoveEvent flight path.
class ShuffleAnimator {
  static const int maxFlyers = 24;
  static const Duration gatherDuration = Duration(milliseconds: 380);
  static const Duration washHopDuration = Duration(milliseconds: 367);
  static const int washHops = 3;
  static const Duration squareDuration = Duration(milliseconds: 400);

  static Future<void> play({
    required BuildContext context,
    required TickerProvider vsync,
    required ShuffleRequest request,
    Future<void> Function()? onSquared,
  }) async {
    if (!context.mounted) {
      await onSquared?.call();
      return;
    }
    if (request.sources.isEmpty) {
      await onSquared?.call();
      return;
    }

    final rng = math.Random();
    final overlay = Overlay.of(context);
    final flyers = <_ShuffleFlyer>[];

    final counts = _allocate(request.sources.map((s) => s.count).toList());
    for (var s = 0; s < request.sources.length; s++) {
      final source = request.sources[s];
      for (var i = 0; i < counts[s]; i++) {
        final origin =
            source.origin +
            Offset(rng.nextDouble() * 6 - 3, rng.nextDouble() * 6 - 3 - i * 1.1);
        final controller = AnimationController(
          vsync: vsync,
          duration: gatherDuration,
        );
        final flyer = _ShuffleFlyer(
          begin: origin,
          end: origin,
          pos: origin,
          rotBegin: 0,
          rotEnd: 0,
          rotation: 0,
          controller: controller,
          width: request.cardWidth,
        );
        flyer.overlayEntry = OverlayEntry(builder: (_) => flyer.build());
        overlay.insert(flyer.overlayEntry!);
        flyers.add(flyer);
      }
    }

    if (flyers.isEmpty) {
      await onSquared?.call();
      return;
    }

    try {
      var cardTicks = 0;
      for (var i = 0; i < flyers.length; i++) {
        if (cardTicks >= SoundService.cardTickMax) break;
        if (i % 4 != 0) continue;
        SoundService.instance.playLayered(
          GameSound.softCard,
          volume: cardTicks == 0 ? 1 : 0.65,
        );
        cardTicks++;
      }
      HapticFeedback.selectionClick();

      await _runPhase(
        flyers,
        gatherDuration,
        (i, _) => _ellipsePoint(request.center, rng, spread: 0.55),
        (i, _) => _randRot(rng),
        stagger: const Duration(milliseconds: 8),
      );

      if (context.mounted) {
        SoundService.instance.play(GameSound.shuffle);
        for (var hop = 0; hop < washHops; hop++) {
          if (!context.mounted) break;
          await _runPhase(
            flyers,
            washHopDuration,
            (i, _) => _ellipsePoint(request.center, rng),
            (i, _) => _randRot(rng),
          );
        }
      }

      if (context.mounted) {
        HapticFeedback.lightImpact();
        await _runPhase(
          flyers,
          squareDuration,
          (i, _) => request.deckTarget + Offset(0, -i * 0.6),
          (i, _) => 0,
        );
      }

      await onSquared?.call();
      await WidgetsBinding.instance.endOfFrame;
    } finally {
      _dispose(flyers);
    }
  }

  static List<int> _allocate(List<int> pileCounts) {
    final out = List<int>.filled(pileCounts.length, 0);
    final total = pileCounts.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return out;

    var used = 0;
    for (var i = 0; i < pileCounts.length; i++) {
      if (pileCounts[i] <= 0) continue;
      out[i] = math.max(1, (maxFlyers * pileCounts[i] / total).round());
      used += out[i];
    }

    var i = 0;
    while (used > maxFlyers) {
      if (out[i] > 1) {
        out[i]--;
        used--;
      }
      i = (i + 1) % out.length;
    }
    return out;
  }

  static Offset _ellipsePoint(
    Offset center,
    math.Random rng, {
    double spread = 1,
  }) {
    final t = rng.nextDouble() * math.pi * 2;
    final r = math.sqrt(rng.nextDouble()) * spread;
    return Offset(
      center.dx + r * 100 * math.cos(t),
      center.dy + r * 70 * math.sin(t),
    );
  }

  static double _randRot(math.Random rng) {
    return (rng.nextDouble() * 2 - 1) * 0.26;
  }

  static Future<void> _runPhase(
    List<_ShuffleFlyer> flyers,
    Duration duration,
    Offset Function(int i, _ShuffleFlyer f) endOf,
    double Function(int i, _ShuffleFlyer f) rotOf, {
    Duration stagger = Duration.zero,
  }) async {
    final futures = <Future<void>>[];
    for (var i = 0; i < flyers.length; i++) {
      final flyer = flyers[i];
      flyer.begin = flyer.pos;
      flyer.end = endOf(i, flyer);
      flyer.rotBegin = flyer.rotation;
      flyer.rotEnd = rotOf(i, flyer);
      flyer.controller.duration = duration;
      flyer.controller.reset();
      flyer.overlayEntry?.markNeedsBuild();
      futures.add(
        Future<void>.delayed(stagger * i).then((_) async {
          await flyer.controller.forward();
          flyer.pos = flyer.end;
          flyer.rotation = flyer.rotEnd;
        }),
      );
    }
    await Future.wait(futures);
  }

  static void _dispose(List<_ShuffleFlyer> flyers) {
    for (final flyer in flyers) {
      flyer.overlayEntry?.remove();
      flyer.controller.dispose();
    }
  }
}

class _ShuffleFlyer {
  _ShuffleFlyer({
    required this.begin,
    required this.end,
    required this.pos,
    required this.rotBegin,
    required this.rotEnd,
    required this.rotation,
    required this.controller,
    required this.width,
  });

  Offset begin;
  Offset end;
  Offset pos;
  double rotBegin;
  double rotEnd;
  double rotation;
  final AnimationController controller;
  final double width;
  OverlayEntry? overlayEntry;

  Widget build() {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final t = curved.value;
        final p = Offset.lerp(begin, end, t)!;
        final rot = lerpDouble(rotBegin, rotEnd, t)!;
        final height = width * 1.4;
        return Positioned(
          left: p.dx - width / 2,
          top: p.dy - height / 2,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: rot,
              child: PlayingCardBack(width: width),
            ),
          ),
        );
      },
    );
  }
}
