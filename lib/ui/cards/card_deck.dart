import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:flutter/cupertino.dart';

class CardDeck extends StatelessWidget {
  final List<PlayingCardModel> cards;
  final int extraPoints;
  final double cardWidth;
  final String title;
  final Function() onTap;

  const CardDeck({
    super.key,
    required this.cards,
    required this.cardWidth,
    required this.extraPoints,
    required this.title,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final deckCount = cards.length;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            children: [
              Text(title, style: AppStyle.theme.mutedText,),
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (extraPoints > 0)
                    ...List.generate(extraPoints, (i) {
                      return Column(
                        children: [
                          SizedBox(
                            height:
                                (deckCount / 3) + 8 + ((extraPoints - i) * 8),
                          ),
                          PlayingCard(
                            playingCardModel: cards[i],
                            isSelected: false,
                            width: 50,
                          ),
                        ],
                      );
                    }),

                  SizedBox(
                    width: cardWidth,
                    height: cardWidth * 1.5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: AppStyle.theme.surface,

                        // border: Border.all(
                        //   color: AppStyle.theme.surfaceRaised,
                        //   // width: 0.5,
                        // ),
                      ),
                      child: const Icon(CupertinoIcons.minus_circle_fill),
                    ),
                  ),
                  ...List.generate((deckCount / 8).ceil(), (i) {
                    return Column(
                      children: [
                        SizedBox(height: ((deckCount / 8).ceil() - i) * 2),
                        PlayingCardBack(width: cardWidth),
                      ],
                    );
                  }),
                  if (cards.isNotEmpty)
                    Padding(
                      padding: EdgeInsetsGeometry.only(top: cardWidth),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          // vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppStyle.theme.muted.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppStyle.theme.border.withValues(alpha: .35),
                          ),
                        ),
                        child: Text(
                          "x${cards.length}",
                          style: TextStyle(
                            fontSize: 10,
                            color: AppStyle.theme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
