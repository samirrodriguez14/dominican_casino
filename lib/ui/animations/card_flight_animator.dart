import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/animations/animated_move_card.dart';
import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:dominican_casino/ui/animations/flight_layer.dart';
import 'package:flutter/cupertino.dart';

/// Card flights in [FlightLayer] coordinates (same Stack as the board).
class CardFlightAnimator {
  static Future<void> flyAll({
    required FlightLayerController layer,
    required TickerProvider vsync,
    required List<CardFlightRequest> flights,
    VoidCallback? onLanded,
    VoidCallback? onLaunched,
    Duration perCard = const Duration(milliseconds: 400),
    Duration stagger = const Duration(milliseconds: 55),
  }) async {
    if (flights.isEmpty) {
      onLaunched?.call();
      return;
    }

    final entries = <_FlightEntry>[];

    try {
      for (final flight in flights) {
        Offset? begin;
        if (flight.fromGlobalCenter != null) {
          begin = layer.toLocal(flight.fromGlobalCenter!);
        }
        begin ??= layer.centerOf(flight.fromKey);
        if (begin == null) continue;

        final controller = AnimationController(vsync: vsync, duration: perCard);
        final entry = _FlightEntry(
          flight: flight,
          layer: layer,
          begin: begin,
          end: begin,
          startWidth: flight.startWidth,
          endWidth: flight.endWidth,
          controller: controller,
        );
        entry.sprite = FlightSprite(
          listenable: controller,
          builder: entry.build,
        );
        layer.attach(entry.sprite!);
        entries.add(entry);
      }

      // Drag overlay can detach now — flight sprites already sit at `begin`.
      onLaunched?.call();

      if (entries.isEmpty) {
        onLanded?.call();
        return;
      }

      // One frame so new slots exist; then move immediately and chase the
      // live destination so table reflow and the flyer stay in sync.
      await WidgetsBinding.instance.endOfFrame;
      for (final entry in entries) {
        entry.syncDestination();
      }

      final futures = <Future<void>>[];
      var cardTicks = 0;
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        futures.add(
          Future<void>.delayed(stagger * i).then((_) async {
            final toDeck = entry.flight.to.type == ZoneType.playerDeck;
            if (entry.flight.hapticOnLaunch) {
              if (toDeck) {
                AppHaptics.lightImpact();
              } else {
                AppHaptics.selectionClick();
              }
            }
            if (cardTicks < SoundService.cardTickMax) {
              SoundService.instance.playLayered(
                _soundFor(entry.flight),
                volume: cardTicks == 0 ? 1 : 0.7,
              );
              cardTicks++;
            }
            await entry.controller.forward();
          }),
        );
      }
      await Future.wait(futures);

      onLanded?.call();
      await WidgetsBinding.instance.endOfFrame;
    } finally {
      layer.detachAll([
        for (final e in entries)
          if (e.sprite != null) e.sprite!,
      ]);
      for (final entry in entries) {
        entry.controller.dispose();
      }
    }
  }

  static GameSound _soundFor(CardFlightRequest flight) {
    if (flight.to.type == ZoneType.playerDeck) return GameSound.capture;
    if (flight.from.type == ZoneType.gameDeck ||
        flight.from.type == ZoneType.playerHand) {
      return GameSound.deal;
    }
    return GameSound.softCard;
  }
}

class _FlightEntry {
  _FlightEntry({
    required this.flight,
    required this.layer,
    required this.begin,
    required this.end,
    required this.startWidth,
    required this.endWidth,
    required this.controller,
  });

  final CardFlightRequest flight;
  final FlightLayerController layer;
  Offset begin;
  Offset end;
  double startWidth;
  double endWidth;
  final AnimationController controller;
  FlightSprite? sprite;

  void syncDestination() {
    final live = layer.centerOf(flight.toKey);
    if (live != null) end = live;
    final measured = layer.widthOf(flight.toKey);
    if (measured != null && measured <= 130) endWidth = measured;
  }

  Widget build(BuildContext context) {
    syncDestination();
    final t = Curves.easeOutCubic.transform(controller.value);
    final p = Offset.lerp(begin, end, t) ?? begin;
    final width = lerpDouble(startWidth, endWidth, t) ?? startWidth;
    final height = width * 1.4;
    Widget card;
    if (flight.flip) {
      final angle = t * math.pi;
      card = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(angle),
        child: t < 0.5
            ? AnimatedMoveCard(
                card: flight.card,
                faceUp: flight.startFaceUp,
                width: width,
              )
            : Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: AnimatedMoveCard(
                  card: flight.card,
                  faceUp: flight.endFaceUp,
                  width: width,
                ),
              ),
      );
    } else {
      card = AnimatedMoveCard(
        card: flight.card,
        faceUp: flight.endFaceUp,
        width: width,
      );
    }

    return Positioned(
      left: p.dx - width / 2,
      top: p.dy - height / 2,
      width: width,
      height: height,
      child: IgnorePointer(child: card),
    );
  }
}
