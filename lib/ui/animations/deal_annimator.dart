import 'package:flutter/cupertino.dart';

class CardMoveAnimator {
  static Future<void> animateCardMove({
    required BuildContext context,
    required TickerProvider vsync,
    required GlobalKey fromKey,
    required GlobalKey toKey,
    Widget? child,
    GlobalKey? existingCardKey,
    double? cardWidth,
    Duration duration = const Duration(milliseconds: 500),
    double beginRotation = 0.0,
  }) async {
    //  await Future.delayed(Duration(seconds: 1));
    // Determine which card widget to animate
    final animatedChild = existingCardKey != null
        ? (existingCardKey.currentWidget as Widget)
        : (child ?? const SizedBox.shrink());

    // Determine card dimensions
    final width = cardWidth ?? 46.0;
    if (child == null && existingCardKey == null) {
      return;
    }
    final overlay = Overlay.of(context);
    final cardHeight = width * 1.4;
    final fromBox = fromKey.currentContext?.findRenderObject() as RenderBox?;
    final toBox = toKey.currentContext?.findRenderObject() as RenderBox?;
    if (fromBox == null || toBox == null) return;

    final fromTopLeft = fromBox.localToGlobal(Offset.zero);
    final fromCenter = fromTopLeft + fromBox.size.center(Offset.zero);

    final toTopLeft = toBox.localToGlobal(Offset.zero);
    final toCenter = toTopLeft + toBox.size.center(Offset.zero);

    final controller = AnimationController(vsync: vsync, duration: duration);

    final pos = Tween<Offset>(
      begin: fromCenter,
      end: toCenter,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    final scale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    final rot = Tween<double>(
      begin: beginRotation,
      end: 0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: controller,
        builder: (_, _) {
          final p = pos.value;
          return Positioned(
            left: p.dx - width / 2,
            top: p.dy - cardHeight / 2,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: rot.value,
                child: Transform.scale(
                  scale: scale.value,
                  child: SizedBox(
                    width: width,
                    height: cardHeight,
                    child: animatedChild,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    overlay.insert(entry);
    await controller.forward();
    entry.remove();
    controller.dispose();
  }
}
