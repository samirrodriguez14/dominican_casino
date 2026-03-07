import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlayingCard extends StatelessWidget {
  final PlayingCardModel playingCardModel;
  final double width;
  final double heightMultiplyer;
  final VoidCallback? onTap;
  final bool isSelected;

  final Color? selectedBorderColor;
  final double selectedBorderWidth;

  const PlayingCard({
    super.key,
    required this.playingCardModel,
    this.width = 80,
    this.heightMultiplyer = 1.4,
    this.onTap,
    required this.isSelected,
    this.selectedBorderColor,
    this.selectedBorderWidth = 2.4,
  });

  @override
  Widget build(BuildContext context) {
    final rank = playingCardModel.rank;
    final suit = _normalizeSuit(playingCardModel.suit);
    final suitColor = _suitColor(suit);

    final height = width * heightMultiplyer;

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
            width: isSelected ? selectedBorderWidth : 1,
          ),

          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: sel.withValues(alpha:(0.35)),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            BoxShadow(
              color: AppStyle.theme.background.withValues(alpha:(0.15)),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Stack(
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
                style: TextStyle(
                  fontSize: width * 0.50,
                  color: suitColor,
                ),
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
                    Text(suit, style: TextStyle(fontSize: 16, color: suitColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

