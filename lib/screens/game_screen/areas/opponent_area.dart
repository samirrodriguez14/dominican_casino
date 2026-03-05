import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/screens/game_screen/decks/players_deck.dart';
import 'package:dominican_casino/screens/game_screen/widgets/playing_card_back.dart';
import 'package:dominican_casino/style/theme_data.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class OpponentArea extends StatefulWidget {
  const OpponentArea({super.key});
  @override
  State<StatefulWidget> createState() => OpponentAreaState();
}

class OpponentAreaState extends State<OpponentArea> {
  bool get highlightTurn => context.select((RoomViewModel vm) => vm.isOppTurn);
  String? get opp => context.select((RoomViewModel vm) => vm.opp);
  int get deckCount =>
      context.select((RoomViewModel vm) => vm.oppHandCardsTotal);
  int get extraPoints =>
      context.select((RoomViewModel vm) => vm.oppExtraPoints);
  List<PlayingCardModel> get collectedCards =>
      context.select((RoomViewModel vm) => vm.oppCollectedCards);

  @override
  Widget build(BuildContext context) {
    bool oppoentJoined = opp != null && opp != "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (oppoentJoined)
            ? AppColors.surface
            : AppColors.charcoal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlightTurn
              ? AppColors.accentGreen.withOpacity(0.75)
              : AppColors.surfaceAlt.withOpacity(0.55),
          width: highlightTurn ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            oppoentJoined
                ? "Opponent ($opp)"
                : "Waiting for opponent...",
            style: AppStyles.muted,
          ),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  deckCount,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: PlayingCardBack(),
                  ),
                ),
              ),
              PlayersDeck(cards: collectedCards, me: false, extraPoints: extraPoints,),
            ],
          ),
        ],
      ),
    );
  }
}
