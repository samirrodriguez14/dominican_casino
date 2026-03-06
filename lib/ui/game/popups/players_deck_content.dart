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
    this.lastTakeId,
    this.extraPoints = 0,
  });

  final List<PlayingCardModel> cards;
  final String title;
  final double cardWidth;
  final double overlap;
  final double? maxHeight;
  final bool showCount;
  final String emptyText;

  final String? lastTakeId;
  final int extraPoints;

  @override
  Widget build(BuildContext context) {
    final h = cardWidth * 2;
    final hasExtraPoints = extraPoints > 0;
    final hasLastTake = lastTakeId != null && lastTakeId!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppStyle.theme.raisedSurfaceBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppStyle.theme.title),
                    if (hasLastTake || hasExtraPoints) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (hasLastTake) _metaChip(
                            'Last take: ${lastTakeId!}',
                          ),
                          if (hasExtraPoints) _metaChip(
                            'Extra points: $extraPoints',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (showCount)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('${cards.length}', style: AppStyle.theme.body),
                ),
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
                    alignment: Alignment.bottomCenter,
                    children: [
                      for (int i = 0; i < cards.length; i++)
                        Positioned(
                          left: i * (cardWidth - overlap),
                          top: cards[i].isSpecial ? 0 : 10,
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

  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppStyle.theme.background.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppStyle.theme.border.withValues(alpha: .35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppStyle.theme.muted,
        ),
      ),
    );
  }
}