import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/game/popups/players_deck_content.dart';
import 'package:dominican_casino/ui/game/widgets/cards/playing_card_back.dart';
import 'package:dominican_casino/ui/game/widgets/cards/playing_card_extra_points.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class PlayersDeck extends StatelessWidget {
  final List<PlayingCardModel> cards;
  final bool me;
  final int extraPoints;
  const PlayersDeck({
    super.key,
    required this.cards,
    required this.me,
    required this.extraPoints,
  });
  @override
  Widget build(BuildContext context) {
    final deckCount = cards.length;
    return GestureDetector(
      // padding: EdgeInsets.zero,
      onTap: () {
        HapticFeedback.mediumImpact();
        showPlayersDeckPopup(context, cards, me: me);
      },
      child: Container(
        padding: const EdgeInsets.all(0),
        // decoration: AppStyle.theme.raisedSurfaceBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (extraPoints > 0 && me)
                  PlayingCardExtraPoints(
                    me: me,
                    height: 24,
                    width: 50,
                    total: extraPoints,
                  ),
                PlayingCardBack( width: 55, empty: deckCount == 0),
                if (extraPoints > 0 && !me)
                  PlayingCardExtraPoints(
                    me: me,
                    height: 24,
                    width: 50,
                    total: extraPoints,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void showPlayersDeckPopup(
    BuildContext context,
    List<PlayingCardModel> cards, {
    bool me = true,
  }) {
    showAppPopup(
      context: context,
      title: "${me ? "My" : "Opponent's"} Collected Cards",
      content: CollectedCardsStrip(cards: cards),
    );
  }
}
