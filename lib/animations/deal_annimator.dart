import 'package:dominican_casino/ui/game/widgets/cards/playing_card_back.dart';
import 'package:flutter/cupertino.dart';

class CardMoveAnimator {
  static Future<void> animateCardMove({
    required BuildContext context,
    required TickerProvider vsync,
    required GlobalKey fromKey,
    required GlobalKey toKey,
    double cardWidth = 46,
    double cardHeight = 64,
    Duration duration = const Duration(milliseconds: 500),
    double beginRotation = 0.0,
  }) async {
    final overlay = Overlay.of(context);

    final fromBox = fromKey.currentContext?.findRenderObject() as RenderBox?;
    final toBox = toKey.currentContext?.findRenderObject() as RenderBox?;
    if (fromBox == null || toBox == null) return;

    final fromTopLeft = fromBox.localToGlobal(Offset.zero);
    final fromCenter = fromTopLeft + fromBox.size.center(Offset.zero);

    final toTopLeft = toBox.localToGlobal(Offset.zero);
    final toCenter = toTopLeft + toBox.size.center(Offset.zero);

    final controller = AnimationController(
      vsync: vsync,
      duration: duration,
    );

    final pos = Tween<Offset>(
      begin: fromCenter,
      end: toCenter,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );

    final scale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    final rot = Tween<double>(begin: beginRotation, end: 0).animate(
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
            child: IgnorePointer(
              child: Transform.rotate(
                angle: rot.value,
                child: Transform.scale(
                  scale: scale.value,
                  child: PlayingCardBack(width: cardWidth),
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

  static Future<void> animateExistingCard({
    required BuildContext context,
    required TickerProvider vsync,
    required GlobalKey cardKey,
    required GlobalKey toKey,
    required Widget overlayCard,
    Duration duration = const Duration(milliseconds: 500),
    double beginRotation = 0.0,
    VoidCallback? onAnimationStart,
    VoidCallback? onAnimationEnd,
  }) async {
    final overlay = Overlay.of(context);

    final cardBox = cardKey.currentContext?.findRenderObject() as RenderBox?;
    final toBox = toKey.currentContext?.findRenderObject() as RenderBox?;

    if (cardBox == null || toBox == null) return;

    final cardTopLeft = cardBox.localToGlobal(Offset.zero);
    final cardSize = cardBox.size;
    final toTopLeft = toBox.localToGlobal(Offset.zero);
    final toCenter = toTopLeft + toBox.size.center(Offset.zero);

    final start = cardTopLeft;
    final end = Offset(
      toCenter.dx - cardSize.width / 2,
      toCenter.dy - cardSize.height / 2,
    );

    final controller = AnimationController(
      vsync: vsync,
      duration: duration,
    );

    final pos = Tween<Offset>(
      begin: start,
      end: end,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );

    final rot = Tween<double>(
      begin: beginRotation,
      end: 0,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    final scale = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    onAnimationStart?.call();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: controller,
        builder: (_, _) {
          final p = pos.value;
          return Positioned(
            left: p.dx,
            top: p.dy,
            width: cardSize.width,
            height: cardSize.height,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: rot.value,
                child: Transform.scale(
                  scale: scale.value,
                  child: overlayCard,
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

    onAnimationEnd?.call();
  }
}