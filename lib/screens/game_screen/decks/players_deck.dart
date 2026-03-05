import 'package:dominican_casino/layouts/app_popup.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/popups/players_deck.dart';
import 'package:dominican_casino/screens/game_screen/widgets/playing_card_back.dart';
import 'package:dominican_casino/screens/game_screen/widgets/playing_card_extra_points.dart';
import 'package:dominican_casino/style/theme_data.dart';
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
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.mediumImpact();
        _showPlayersDeckPopup(context, cards, me: me);
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: AppStyles.raisedSurfaceBox(),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (extraPoints > 0)
                 PlayingCardExtraPoints( height: 30, width: 14, total: extraPoints,),

                PlayingCardBack(height: 40, width: 35, empty: deckCount == 0),
              ],
            ),
            Text("$deckCount"),
          ],
        ),
      ),
    );
  }

  void _showPlayersDeckPopup(
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
