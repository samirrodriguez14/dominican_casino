import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/theme_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlayingCard extends StatelessWidget {
  final PlayingCardModel playingCardModel;
  final double width;
  final VoidCallback? onTap;
  final bool isSelected;

  final Color? selectedBorderColor;
  final double selectedBorderWidth;

  const PlayingCard({
    super.key,
    required this.playingCardModel,
    this.width = 80,
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

    final height = width * 1.4;

    final sel = selectedBorderColor ?? AppColors.accentGreen;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),

          border: Border.all(
            color: isSelected ? sel : AppColors.cardBorder,
            width: isSelected ? selectedBorderWidth : 1,
          ),

          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: sel.withOpacity(0.35),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // if (isSelected)
              // Positioned.fill(
              //   child: Container(
              //     decoration: BoxDecoration(
              //       borderRadius: BorderRadius.circular(14),
              //       gradient: LinearGradient(
              //         begin: Alignment.topLeft,
              //         end: Alignment.bottomRight,
              //         colors: [
              //           sel.withOpacity(0.17),
              //           sel.withOpacity(0.18),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),

            // Optional: check badge
            // if (isSelected)
            //   Positioned(
            //     top: 8,
            //     right: 8,
            //     child: Container(
            //       width: 15,
            //       height: 15,
            //       decoration: BoxDecoration(
            //         color: sel,
            //         borderRadius: BorderRadius.circular(999),
            //         boxShadow: [
            //           BoxShadow(
            //             color: AppColors.shadow.withOpacity(0.25),
            //             blurRadius: 10,
            //             offset: const Offset(0, 6),
            //           ),
            //         ],
            //       ),
            //       child: const Icon(
            //         Icons.check,
            //         size: 14,
            //         color: AppColors.textPrimary,
            //       ),
            //     ),
            //   ),

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
        ? AppColors.suitRed
        : AppColors.suitBlack;
  }

