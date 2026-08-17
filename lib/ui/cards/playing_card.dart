import 'package:dominican_casino/game_control/casino_coin_bonuses.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/card_coin_hint.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayingCard extends StatelessWidget {
  final PlayingCardModel playingCardModel;
  final double width;
  final double heightMultiplyer;
  final VoidCallback? onTap;
  final bool isSelected;

  final Color? selectedBorderColor;
  final double selectedBorderWidth;

  /// Extra coin hint (e.g. take-size preview). Specials are automatic.
  final int extraCoinHint;

  /// Flight overlays skip hints so they do not mount extra bounce listeners.
  final bool showCoinHint;

  const PlayingCard({
    super.key,
    required this.playingCardModel,
    this.width = 80,
    this.heightMultiplyer = 1.4,
    this.onTap,
    required this.isSelected,
    this.selectedBorderColor,
    this.selectedBorderWidth = 2.4,
    this.extraCoinHint = 0,
    this.showCoinHint = true,
  });

  @override
  Widget build(BuildContext context) {
    final rank = playingCardModel.rank;
    final suit = _normalizeSuit(playingCardModel.suit);
    final suitColor = _suitColor(suit);
    final height = width * heightMultiplyer;
    final hintsEnabled = showCoinHint && _casinoCoinHintsEnabled(context);
    final specialCoins =
        hintsEnabled ? CasinoCoinBonuses.specialBonus(playingCardModel) : 0;
    final coinHint =
        hintsEnabled ? (extraCoinHint > 0 ? extraCoinHint : specialCoins) : 0;

    final sel = selectedBorderColor ?? AppStyle.theme.turnHighlight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppStyle.theme.cardBackground,
          borderRadius: BorderRadius.circular(14),

          border: Border.all(
            color: isSelected ? sel : AppStyle.theme.cardBorder,
            width: 1,
          ),

          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),

            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Top Left
            Positioned(
              top: 8,
              left: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rank,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: suitColor,
                    ),
                  ),
                  Text(suit, style: TextStyle(fontSize: 16, color: suitColor)),
                ],
              ),
            ),

            // Center Suit
            Center(
              child: Text(
                suit,
                style: TextStyle(fontSize: width * 0.50, color: suitColor),
              ),
            ),

            // Bottom Right (rotated 180°)
            Positioned(
              bottom: 8,
              right: 8,
              child: Transform.rotate(
                angle: 3.1416,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rank,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: suitColor,
                      ),
                    ),
                    Text(
                      suit,
                      style: TextStyle(fontSize: 16, color: suitColor),
                    ),
                  ],
                ),
              ),
            ),

            if (coinHint > 0)
              Positioned(
                bottom: 4,
                left: 4,
                child: CardCoinHint(
                  count: coinHint,
                  size: (width * 0.18).clamp(10, 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Coin markers are Casino / Casino Speed only (not Tres y Dos).
bool _casinoCoinHintsEnabled(BuildContext context) {
  try {
    final vm = Provider.of<GeneralGameViewModel>(context, listen: false);
    return GameRegistry.isCasinoFamily(vm.gameState.gameMode);
  } on ProviderNotFoundException {
    return false;
  }
}

/// Allows either "hearts" or "♥"
String _normalizeSuit(String suit) {
  switch (suit.toLowerCase()) {
    case 'hearts':
    case '♥':
      return '♥';
    case 'diamonds':
    case '♦':
      return '♦';
    case 'spades':
    case '♠':
      return '♠';
    case 'clubs':
    case '♣':
      return '♣';
    default:
      return suit;
  }
}

Color _suitColor(String suit) {
  return (suit == '♥' || suit == '♦')
      ? AppStyle.theme.suitRed
      : AppStyle.theme.suitBlack;
}
