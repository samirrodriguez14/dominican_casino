import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:dominican_casino/ui/animations/flight_layer.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:flutter/cupertino.dart';

/// Cosmetic gather → wash → square in [FlightLayer] space.
class ShuffleAnimator {
  static const int maxFlyers = 16;
  static const Duration flipDuration = Duration(milliseconds: 260);
  static const Duration shrinkDuration = Duration(milliseconds: 200);
  static const Duration gatherDuration = Duration(milliseconds: 380);
  static const Duration washHopDuration = Duration(milliseconds: 367);
  static const int washHops = 3;
  static const Duration squareDuration = Duration(milliseconds: 400);

  /// Wash — cards mix in random directions, still overlapping as a pile.
  static const double washRadiusX = 58;
  static const double washRadiusY = 24;

  static Future<void> play({
    required FlightLayerController layer,
    required TickerProvider vsync,
    required ShuffleRequest request,
    Future<void> Function()? onFlyersAttached,
    Future<void> Function()? onHidden,
    Future<void> Function()? onSquared,
  }) async {
    if (request.cards.isEmpty) {
      await onSquared?.call();
      return;
    }

    final center = layer.toLocal(request.center);
    final deckTarget = layer.toLocal(request.deckTarget);
    if (center == null || deckTarget == null) {
      await onSquared?.call();
      return;
    }

    final rng = math.Random();
    final picked = _pickCards(request.cards);
    final flyers = <_ShuffleFlyer>[];

    for (final source in picked) {
      final originLocal = layer.toLocal(source.origin);
      if (originLocal == null) continue;
      final controller = AnimationController(
        vsync: vsync,
        duration: gatherDuration,
      );
      final flyer = _ShuffleFlyer(
        begin: originLocal,
        end: originLocal,
        pos: originLocal,
        rotBegin: 0,
        rotEnd: 0,
        rotation: 0,
        controller: controller,
        width: source.width,
        targetWidth: request.targetCardWidth,
        faceUp: source.faceUp,
        card: source.card,
        onPhaseChange: layer.poke,
      );
      flyer.sprite = FlightSprite(
        listenable: controller,
        builder: (_) => flyer.build(),
      );
      layer.attach(flyer.sprite!);
      flyers.add(flyer);
    }

    if (flyers.isEmpty) {
      await onSquared?.call();
      return;
    }

    try {
      await WidgetsBinding.instance.endOfFrame;
      await onFlyersAttached?.call();
      await onHidden?.call();
      await WidgetsBinding.instance.endOfFrame;

      final needsFlip = flyers.any((f) => f.faceUp);
      if (needsFlip) {
        await _runFlip(flyers, vsync);
      }

      // Shrink all flyers to the same target size *before* motion begins.
      // During gather/wash/square the width stays constant.
      await _runPhase(
        flyers,
        shrinkDuration,
        (i, f) => f.pos,
        (i, f) => f.rotation,
        stagger: const Duration(milliseconds: 6),
        shrinkToTarget: true,
      );

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
      AppHaptics.selectionClick();

      await _runPhase(
        flyers,
        gatherDuration,
        (i, _) => _ellipsePoint(center, rng, spread: 0.55),
        (i, _) => _randRot(rng),
        stagger: const Duration(milliseconds: 8),
      );

      SoundService.instance.play(GameSound.shuffle);
      for (var hop = 0; hop < washHops; hop++) {
        await _runPhase(
          flyers,
          washHopDuration,
          (i, _) => _ellipsePoint(center, rng),
          (i, _) => _randRot(rng),
        );
      }

      AppHaptics.lightImpact();
      await _runPhase(
        flyers,
        squareDuration,
        (i, _) =>
            deckTarget + Offset(0, -i * ShuffleRequest.pileBackStep * 0.35),
        (i, _) => 0,
      );

      await onSquared?.call();
      await WidgetsBinding.instance.endOfFrame;
    } finally {
      layer.detachAll(flyers.map((f) => f.sprite).whereType<FlightSprite>());
      for (final flyer in flyers) {
        flyer.flipController?.dispose();
        flyer.controller.dispose();
      }
    }
  }

  static List<ShuffleCardSource> _pickCards(List<ShuffleCardSource> cards) {
    if (cards.length <= maxFlyers) return cards;
    final step = cards.length / maxFlyers;
    return List.generate(maxFlyers, (i) => cards[(i * step).floor()]);
  }

  static Future<void> _runFlip(
    List<_ShuffleFlyer> flyers,
    TickerProvider vsync,
  ) async {
    final futures = <Future<void>>[];
    for (final flyer in flyers) {
      if (!flyer.faceUp) continue;
      flyer.flipController = AnimationController(
        vsync: vsync,
        duration: flipDuration,
      );
      flyer.flipController!.addListener(flyer.onPhaseChange);
      futures.add(flyer.flipController!.forward());
    }
    await Future.wait(futures);
    for (final flyer in flyers) {
      flyer.faceUp = false;
    }
  }

  static Offset _ellipsePoint(
    Offset center,
    math.Random rng, {
    double spread = 1,
  }) {
    final t = rng.nextDouble() * math.pi * 2;
    final r = math.sqrt(rng.nextDouble()) * spread;
    return Offset(
      center.dx + r * washRadiusX * math.cos(t),
      center.dy + r * washRadiusY * math.sin(t),
    );
  }

  static double _randRot(math.Random rng) {
    return (rng.nextDouble() * 2 - 1) * 0.18;
  }

  static Future<void> _runPhase(
    List<_ShuffleFlyer> flyers,
    Duration duration,
    Offset Function(int i, _ShuffleFlyer f) endOf,
    double Function(int i, _ShuffleFlyer f) rotOf, {
    Duration stagger = Duration.zero,
    bool shrinkToTarget = false,
  }) async {
    final futures = <Future<void>>[];
    for (var i = 0; i < flyers.length; i++) {
      final flyer = flyers[i];
      flyer.begin = flyer.pos;
      flyer.end = endOf(i, flyer);
      flyer.rotBegin = flyer.rotation;
      flyer.rotEnd = rotOf(i, flyer);
      if (shrinkToTarget) {
        flyer.widthBegin = flyer.width;
        flyer.widthEnd = flyer.targetWidth;
      }
      flyer.controller.duration = duration;
      flyer.controller.reset();
      flyer.onPhaseChange();
      futures.add(
        Future<void>.delayed(stagger * i).then((_) async {
          await flyer.controller.forward();
          flyer.pos = flyer.end;
          flyer.rotation = flyer.rotEnd;
          if (shrinkToTarget) {
            flyer.width = flyer.targetWidth;
            flyer.widthBegin = 0;
            flyer.widthEnd = 0;
          }
        }),
      );
    }
    await Future.wait(futures);
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
    required this.targetWidth,
    required this.faceUp,
    required this.card,
    required this.onPhaseChange,
  });

  Offset begin;
  Offset end;
  Offset pos;
  double rotBegin;
  double rotEnd;
  double rotation;
  final AnimationController controller;
  double width;
  final double targetWidth;
  bool faceUp;
  final PlayingCardModel? card;
  final VoidCallback onPhaseChange;
  AnimationController? flipController;
  FlightSprite? sprite;
  double widthBegin = 0;
  double widthEnd = 0;

  Widget build() {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );
    final t = curved.value;
    final p = Offset.lerp(begin, end, t)!;
    final rot = lerpDouble(rotBegin, rotEnd, t)!;
    final drawWidth = widthBegin > 0
        ? lerpDouble(widthBegin, widthEnd, t)!
        : width;
    final height = drawWidth * 1.4;
    final flipT = flipController?.value ?? (faceUp ? 0.0 : 1.0);
    final showFace = flipT < 0.5 && faceUp && card != null;

    return Positioned(
      left: p.dx - drawWidth / 2,
      top: p.dy - height / 2,
      width: drawWidth,
      height: height,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: rot,
          child: showFace
              ? PlayingCard(
                  playingCardModel: card!,
                  width: drawWidth,
                  isSelected: false,
                )
              : PlayingCardBack(width: drawWidth),
        ),
      ),
    );
  }
}
