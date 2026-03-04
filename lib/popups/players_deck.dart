import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/theme_data.dart';
import 'package:dominican_casino/widgets/playing_card.dart';
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
    final h = cardWidth * 1.4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppStyles.raisedSurfaceBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(title, style: AppStyles.title),
              const Spacer(),
              if (showCount)
                Text('${cards.length}', style: AppStyles.body),
            ],
          ),
          const SizedBox(height: 10),

          if (cards.isEmpty)
            Text(emptyText, style: AppStyles.body)
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxHeight ?? (h + 6),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: h,
                  width: cardWidth + (cards.length - 1) * (cardWidth - overlap),
                  child: Stack(
                    children: [
                      for (int i = 0; i < cards.length; i++)
                        Positioned(
                          left: i * (cardWidth - overlap),
                          top: 0,
                          child: PlayingCard(
                            playingCardModel: cards[i],
                            width: cardWidth,
                            // view-only
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