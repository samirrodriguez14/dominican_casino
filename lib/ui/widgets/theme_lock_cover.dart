import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:flutter/cupertino.dart';

/// Dim overlay with a centered lock. Used on locked theme cards.
class ThemeLockCover extends StatelessWidget {
  const ThemeLockCover({
    super.key,
    this.coinCost,
    this.lockSize = 36,
    this.caption,
    this.mystery = false,
  });

  final int? coinCost;
  final double lockSize;
  final String? caption;
  /// Fully obscure the pack art (Journey sealed theme).
  final bool mystery;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: mystery ? const Color(0xF2141418) : const Color(0x6B000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.lock_fill,
              color: const Color(0xE6FFFFFF),
              size: lockSize,
            ),
            if (coinCost != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    coinIcon,
                    size: 14,
                    color: Color(0xE6FFFFFF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$coinCost',
                    style: const TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ] else if (caption != null) ...[
              const SizedBox(height: 8),
              Text(
                caption!,
                style: const TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
