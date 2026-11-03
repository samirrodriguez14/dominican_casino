import 'package:barajando/models/playing_card_model.dart';
import 'package:barajando/ui/cards/playing_card.dart';
import 'package:barajando/ui/cards/playing_card_back.dart';
import 'package:flutter/cupertino.dart';

class AnimatedMoveCard extends StatelessWidget {
  final PlayingCardModel card;
  final bool faceUp;
  final double width;

  const AnimatedMoveCard({
    super.key,
    required this.card,
    required this.faceUp,
    this.width = 46,
  });

  @override
  Widget build(BuildContext context) {
    if (!faceUp) {
      return PlayingCardBack(width: width);
    }

    return PlayingCard(
      playingCardModel: card,
      isSelected: false,
      width: width,
      showCoinHint: false,
    );
  }
}