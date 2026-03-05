import 'dart:math' as math;
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class DealAnimator {
  static Future<void> dealFromDeck({
    required BuildContext context,
    required TickerProvider vsync,
    required GlobalKey deckKey,
    required GlobalKey targetKey,
    required int count,
    double cardWidth = 46,
    double cardHeight = 64,
    Duration duration = const Duration(milliseconds: 600),
    Duration perCardDelay = const Duration(milliseconds: 150),
  }) async {
    final overlay = Overlay.of(context);

    final deckBox = deckKey.currentContext?.findRenderObject() as RenderBox?;
    final targetBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (deckBox == null || targetBox == null) return;

    final deckTopLeft = deckBox.localToGlobal(Offset.zero);
    final deckCenter = deckTopLeft + deckBox.size.center(Offset.zero);

    final targetTopLeft = targetBox.localToGlobal(Offset.zero);
    final targetCenter = targetTopLeft + targetBox.size.center(Offset.zero);

    Offset targetFor(int i) {
      // small spread so the 4 dealt cards don’t all land on the exact same pixel
      final spread = math.min(18.0, cardWidth * 0.45);
      final startX = targetCenter.dx - ((count - 1) * spread) / 2;
      final x = startX + i * spread;
      final y = targetCenter.dy;
      return Offset(x, y);
    }

    final futures = <Future<void>>[];

    for (int i = 0; i < count; i++) {
      final controller = AnimationController(vsync: vsync, duration: duration);

      final start = deckCenter;
      final end = targetFor(i);

      final pos = Tween<Offset>(begin: start, end: end).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );

      final scale = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );

      final rot = Tween<double>(
        begin: (i.isEven ? -0.10 : 0.10),
        end: 0,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => AnimatedBuilder(
          animation: controller,
          builder: (_, _) {
            final p = pos.value;
            return Positioned(
              left: p.dx - cardWidth / 2,
              top: p.dy - cardHeight / 2,
              child: Transform.rotate(
                angle: rot.value,
                child: Transform.scale(
                  scale: scale.value,
                  child: _CardBack(width: cardWidth, height: cardHeight),
                ),
              ),
            );
          },
        ),
      );

      overlay.insert(entry);

      futures.add(() async {
        await Future.delayed(perCardDelay * i);
        await controller.forward();
        controller.dispose();
        entry.remove();
      }());
    }

    await Future.wait(futures);
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppStyle.theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppStyle.theme.surfaceAlt, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        'DC',
        style: TextStyle(
          color: AppStyle.theme.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}