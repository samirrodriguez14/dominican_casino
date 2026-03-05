import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/style/theme_data.dart';
import 'package:dominican_casino/widgets/playing_card.dart';
import 'package:flutter/material.dart';

class PlayingAreaStack extends StatelessWidget {
  final PlayingAreaStackModel stack;

  /// If true, the stack container gets a glow + thicker border.
  final bool isSelected;

  /// Width of each card in the stack.
  final double cardWidth;

  /// Amount of overlap (in px) between cards.
  final double overlap;

  final VoidCallback? onTap;

  const PlayingAreaStack({
    super.key,
    required this.stack,
    this.isSelected = false,
    this.cardWidth = 52,
    this.overlap = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = cardWidth * 1.4;
    final stackColor = stack.paired
        ? AppColors.cerulean
        : (AppColors.accentGreen);
    // Total width for N overlapped cards
    final totalWidth = stack.cards.isEmpty
        ? cardWidth
        : cardWidth + (stack.cards.length - 1) * (cardWidth - overlap);

    final badgeColor = stackColor;

    // Selection visuals for the whole stack

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        width: totalWidth,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.separator,
          borderRadius: BorderRadius.circular(14),
          // border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: stackColor.withOpacity(0.60),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Cards (overlapped)
            for (int i = 0; i < stack.cards.length; i++)
              Positioned(
                left: i * (cardWidth - overlap),
                top: 0,
                child: IgnorePointer(
                  ignoring: true,
                  child: PlayingCard(
                    playingCardModel: stack.cards[i],
                    width: cardWidth,
                    isSelected:
                        false, // selection is shown on the stack container
                  ),
                ),
              ),

            // Value badge
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  '${stack.paired ? "P" : ''} ${stack.stackValue}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            // Optional: small selected badge for extra clarity
            if (isSelected)
              Positioned(
                bottom: -8,
                right: -8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: stackColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
