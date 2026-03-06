import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/game/widgets/cards/playing_card.dart';
import 'package:flutter/cupertino.dart';

class CollectedCardsStrip extends StatelessWidget {
  const CollectedCardsStrip({
    super.key,
    required this.cards,
    this.title = 'Collected Cards',
    this.cardWidth = 52,
    this.overlap = 16,
    this.maxHeight,
    this.showCount = true,
    this.emptyText = 'No cards collected yet.',
  });
  final List<PlayingCardModel> cards;
  final String title;
  final double cardWidth;
  final double overlap; // px overlap between cards
  final double? maxHeight;
  final bool showCount;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final h = cardWidth * 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppStyle.theme.raisedSurfaceBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(title, style: AppStyle.theme.title),
              const Spacer(),
              if (showCount) Text('${cards.length}', style: AppStyle.theme.body),
            ],
          ),
          const SizedBox(height: 10),

          if (cards.isEmpty)
            Text(emptyText, style: AppStyle.theme.body)
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight ?? (h + 12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: h,
                  width: cardWidth + (cards.length - 1) * (cardWidth - overlap),

                  child: Stack(
                    alignment:Alignment.bottomCenter,
                    children: [
                      for (int i = 0; i < cards.length; i++)
                        Positioned(
                          left: i * (cardWidth - overlap),
                          top: cards[i].isSpecial? 0:10,
                          child: PlayingCard(
                            playingCardModel: cards[i],
                            width: cardWidth,
                            isSelected: false,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
