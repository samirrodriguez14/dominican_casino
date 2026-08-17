import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:flutter/material.dart';

/// Table stack laid out at its final fanned width so flight destinations can
/// land on each card's offset slot (not a center pile that later spreads).
class PlayingAreaStack extends StatelessWidget {
  final PlayingAreaStackModel stack;

  /// If true, the stack container gets a glow + thicker border.
  final bool isSelected;

  /// Width of each card in the stack.
  final double cardWidth;

  /// Amount of overlap (in px) between cards when fully fanned.
  final double overlap;

  final VoidCallback? onTap;

  /// Per-card flight anchors — use [CardSlot.inStack] keys only.
  final GlobalKey Function(PlayingCardModel card)? cardKeyFor;

  /// Hide only the cards that are flying — never the whole stack.
  final bool Function(PlayingCardModel card)? cardInFlight;

  const PlayingAreaStack({
    super.key,
    required this.stack,
    this.isSelected = false,
    this.cardWidth = 59,
    this.overlap = 30,
    this.onTap,
    this.cardKeyFor,
    this.cardInFlight,
  });

  @override
  Widget build(BuildContext context) {
    final height = cardWidth * 1.4;
    final stackColor = stack.paired
        ? AppStyle.theme.cardBorder
        : AppStyle.theme.turnHighlight;
    final step = cardWidth - overlap;
    final n = stack.cards.length;
    final totalWidth = n <= 1 ? cardWidth : cardWidth + (n - 1) * step;
    final landing = stack.cards.any((c) => cardInFlight?.call(c) ?? false);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: totalWidth,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(
                    color: stackColor.withValues(alpha: 0.55),
                    width: 1.5,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: stackColor.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < n; i++)
                Positioned(
                  left: i * step,
                  top: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: FlightAwareCard(
                      key: cardKeyFor?.call(stack.cards[i]),
                      card: stack.cards[i],
                      inFlight: cardInFlight?.call(stack.cards[i]) ?? false,
                      child: PlayingCard(
                        playingCardModel: stack.cards[i],
                        width: cardWidth,
                        isSelected: false,
                      ),
                    ),
                  ),
                ),
              if (!landing)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: stackColor.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${stack.paired ? "P" : ''} ${stack.stackValue}',
                      style: TextStyle(
                        color: AppStyle.theme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              if (isSelected)
                Positioned(
                  bottom: -6,
                  right: -6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: stackColor.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      size: 12,
                      color: AppStyle.theme.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
