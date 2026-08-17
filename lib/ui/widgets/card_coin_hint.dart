import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:flutter/cupertino.dart';

/// Bouncing coin stack in the bottom-left of a card / stack.
class CardCoinHint extends StatefulWidget {
  const CardCoinHint({
    super.key,
    required this.count,
    this.size = 12,
  });

  final int count;
  final double size;

  @override
  State<CardCoinHint> createState() => _CardCoinHintState();
}

class _CardCoinHintState extends State<CardCoinHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    final theme = AppStyle.theme;
    final shown = widget.count.clamp(1, 6);
    final size = widget.size;

    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_bounce.value);
        return Transform.translate(
          offset: Offset(0, -2.5 * t),
          child: child,
        );
      },
      child: SizedBox(
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
                  shadows: [
                    Shadow(
                      color: CupertinoColors.black.withValues(alpha: .35),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            if (widget.count > 1)
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
                    '${widget.count}',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: theme.turnHighlight,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
