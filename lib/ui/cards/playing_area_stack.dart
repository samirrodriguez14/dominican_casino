import 'package:dominican_casino/game_control/casino_coin_bonuses.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Table stack. Incoming cards compact into the current width so the table
/// does not wrap; after they land the fan eases out in place.
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

  /// Motion controller — hides in-flight cards without a full board rebuild.
  final CardMotionController motion;

  /// Drag-merge preview cards (replaces [stack.cards] visually).
  final List<PlayingCardModel>? previewCards;

  /// Badge override e.g. `2+3→5`.
  final String? previewLabel;

  const PlayingAreaStack({
    super.key,
    required this.stack,
    required this.motion,
    this.isSelected = false,
    this.cardWidth = 59,
    this.overlap = 30,
    this.onTap,
    this.cardKeyFor,
    this.previewCards,
    this.previewLabel,
  });

  @override
  Widget build(BuildContext context) {
    final height = cardWidth * 1.4;
    final stackColor = stack.paired
        ? AppStyle.theme.cardBorder
        : AppStyle.theme.turnHighlight;
    final naturalStep = cardWidth - overlap;
    final baseN = stack.cards.isEmpty ? 1 : stack.cards.length;
    final cards = previewCards ?? stack.cards;
    final n = cards.length;
    final showTakePreview =
        previewCards == null && _casinoFamilyCoinHints(context);
    final takePreview =
        showTakePreview ? CasinoCoinBonuses.takePreviewForTableCount(n) : 0;
    final previewIndex = n > 0 ? n - 1 : -1;
    final badgeText = previewLabel == 'Choose'
        ? '${stack.paired ? "P" : ''} ${stack.stackValue}'.trim()
        : (previewLabel ??
              '${stack.paired ? "P" : ''} ${stack.stackValue}'.trim());

    return ListenableBuilder(
      listenable: motion.flightTick,
      builder: (context, _) {
        final inFlightN = cards.where(motion.isInFlightCard).length;
        final lockWidth = previewCards != null || inFlightN > 0;
        final settledN = previewCards != null
            ? baseN
            : (n - inFlightN).clamp(1, n);
        final totalWidth = settledN <= 1
            ? cardWidth
            : cardWidth + (settledN - 1) * naturalStep;
        final step = n <= 1
            ? 0.0
            : lockWidth
            ? (totalWidth - cardWidth) / (n - 1)
            : naturalStep;
        final landing = inFlightN > 0;
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
                border: isSelected || previewLabel != null
                    ? Border.all(
                        color: stackColor.withValues(alpha: 0.55),
                        width: 1.5,
                      )
                    : null,
                boxShadow: isSelected || previewLabel != null
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
                    AnimatedPositioned(
                      key: ValueKey(cards[i].id),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      left: i * step,
                      top: 0,
                      width: cardWidth,
                      height: height,
                      child: IgnorePointer(
                        ignoring: true,
                        child: FlightAwareCard(
                          key: previewCards == null
                              ? cardKeyFor?.call(cards[i])
                              : null,
                          motion: motion,
                          cardId: cards[i].id,
                          width: cardWidth,
                          child: PlayingCard(
                            playingCardModel: cards[i],
                            width: cardWidth,
                            isSelected: false,
                            extraCoinHint: i == previewIndex ? takePreview : 0,
                          ),
                        ),
                      ),
                    ),
                  if (!landing || previewLabel != null)
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
                          badgeText,
                          style: TextStyle(
                            color: AppStyle.theme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  if (isSelected && previewLabel == null)
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
      },
    );
  }
}

bool _casinoFamilyCoinHints(BuildContext context) {
  try {
    final vm = Provider.of<GeneralGameViewModel>(context, listen: false);
    return GameRegistry.isCasinoFamily(vm.gameState.gameMode);
  } on ProviderNotFoundException {
    return false;
  }
}
