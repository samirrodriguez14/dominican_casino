import 'dart:math' as math;

import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/animations/animated_move_card.dart';
import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:flutter/cupertino.dart';

/// Continuous overlay flights — same visual from lift-off to landing (no flash).
class CardFlightAnimator {
  static Future<void> flyAll({
    required BuildContext context,
    required TickerProvider vsync,
    required List<CardFlightRequest> flights,
    VoidCallback? onLanded,
    Duration perCard = const Duration(milliseconds: 420),
    Duration stagger = const Duration(milliseconds: 55),
  }) async {
    if (flights.isEmpty || !context.mounted) return;

    final overlay = Overlay.of(context);
    final entries = <_FlightEntry>[];

    // Mount every flyer at its origin immediately (covers the invisible source).
    for (final flight in flights) {
      Offset? begin = flight.fromGlobalCenter;
      begin ??= flight.fromKey != null ? _centerOf(flight.fromKey!) : null;
      if (begin == null) continue;

      final controller = AnimationController(vsync: vsync, duration: perCard);
      final entry = _FlightEntry(
        flight: flight,
        begin: begin,
        end: begin,
        controller: controller,
      );
      entry.overlayEntry = OverlayEntry(builder: (_) => entry.build());
      overlay.insert(entry.overlayEntry!);
      entries.add(entry);
    }

    if (entries.isEmpty) {
      onLanded?.call();
      return;
    }

    // Destination slots are laid out (invisible) — resolve end points.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    for (final entry in entries) {
      final end = entry.flight.toKey != null
          ? _centerOf(entry.flight.toKey!)
          : null;
      if (end != null) entry.end = end;
      entry.overlayEntry!.markNeedsBuild();
    }

    final futures = <Future<void>>[];
    var cardTicks = 0;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      futures.add(
        Future<void>.delayed(stagger * i).then((_) async {
          if (!context.mounted) return;
          final toDeck = entry.flight.to.type == ZoneType.playerDeck;
          if (entry.flight.hapticOnLaunch) {
            // Soft tick per card — deals and table collects both feel tactile.
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

    // Reveal destination under the overlay, then remove flyer (no blank frame).
    onLanded?.call();
    await WidgetsBinding.instance.endOfFrame;

    for (final entry in entries) {
      entry.overlayEntry?.remove();
      entry.controller.dispose();
    }
  }

  /// Deal/capture for cards that actually travel; soft tick for table slides.
  static GameSound _soundFor(CardFlightRequest flight) {
    if (flight.to.type == ZoneType.playerDeck) return GameSound.capture;
    if (flight.from.type == ZoneType.gameDeck ||
        flight.from.type == ZoneType.playerHand) {
      return GameSound.deal;
    }
    return GameSound.softCard;
  }

  static Offset? _centerOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }
}

class _FlightEntry {
  _FlightEntry({
    required this.flight,
    required this.begin,
    required this.end,
    required this.controller,
  });

  final CardFlightRequest flight;
  Offset begin;
  Offset end;
  final AnimationController controller;
  OverlayEntry? overlayEntry;

  Widget build() {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    final pos = Tween<Offset>(begin: begin, end: end).animate(curved);
    final widthAnim = Tween<double>(
      begin: flight.startWidth,
      end: flight.endWidth,
    ).animate(curved);

    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final p = pos.value;
        final width = widthAnim.value;
        final height = width * 1.4;
        Widget card;
        if (flight.flip) {
          final t = curved.value;
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
          child: IgnorePointer(
            child: SizedBox(width: width, height: height, child: card),
          ),
        );
      },
    );
  }
}
