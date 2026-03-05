import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/screens/game/decks/players_deck.dart';
import 'package:dominican_casino/screens/game/widgets/cards/playing_card_back.dart';
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
  int get score => context.select((RoomViewModel vm) => vm.oppScore);

  int get extraPoints =>
      context.select((RoomViewModel vm) => vm.oppExtraPoints);
  List<PlayingCardModel> get collectedCards =>
      context.select((RoomViewModel vm) => vm.oppCollectedCards);

  @override
  Widget build(BuildContext context) {
    bool opponentJoined = opp != null && opp != "";
    final pillColor = highlightTurn
        ? AppColors.accentGreen.withOpacity(0.75)
        : AppColors.surfaceAlt.withOpacity(0.55);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppStyle.theme.playerSectionBox(
        highlightColor: AppColors.accentGreen,
        highlight: highlightTurn,
        joined: opponentJoined,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    opponentJoined ? "Id ($opp)" : "Waiting for opponent...",
                    style: AppStyle.theme.mutedText,
                  ),
                ),
              ),

              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: pillColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: pillColor),
                    ),
                    child: Text(
                      "Opp score: $score",
                      style: AppStyle.theme.mutedText.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text("", style: AppStyle.theme.mutedText),
                ),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.topRight,
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
              PlayersDeck(
                cards: collectedCards,
                me: false,
                extraPoints: extraPoints,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
