import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/coin_hint_ticker.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:flutter/cupertino.dart';

/// Coin stack in the bottom-left of a card / stack.
/// Bounce is driven by a shared [CoinHintTickerScope] (one ticker for all).
class CardCoinHint extends StatelessWidget {
  const CardCoinHint({
    super.key,
    required this.count,
    this.size = 12,
  });

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final theme = AppStyle.theme;
    final shown = count.clamp(1, 6);
    final bounce = CoinHintTickerScope.maybeOf(context);

    final stack = SizedBox(
      width: size + (shown - 1) * 3.5,
      height: size + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < shown; i++)
            Positioned(
              right: i * 3.5,
              top: (shown - 1 - i) * 1.2,
              child: Icon(
                coinIcon,
                size: size,
                color: theme.turnHighlight,
              ),
            ),
          if (count > 1)
            Positioned(
              right: -2,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xF216120F),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.turnHighlight.withValues(alpha: .7),
                  ),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: theme.textPrimary,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (bounce == null) return stack;

    return AnimatedBuilder(
      animation: bounce,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(bounce.value);
        return Transform.translate(
          offset: Offset(0, -2.5 * t),
          child: child,
        );
      },
      child: stack,
    );
  }
}
