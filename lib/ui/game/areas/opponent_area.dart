import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/game/widgets/cards/playing_card_back.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class OpponentArea extends StatefulWidget {
  const OpponentArea({super.key});
  @override
  State<StatefulWidget> createState() => OpponentAreaState();
}

class OpponentAreaState extends State<OpponentArea> {
  bool get highlightTurn => context.select((GameViewModel vm) => vm.isOppTurn);
  String? get opp => context.select((GameViewModel vm) => vm.opp);
  Player? get oppInfo => context.select((GameViewModel vm) => vm.oppInfo);
  int get deckCount =>
      context.select((GameViewModel vm) => vm.oppHandCardsTotal);
  int get score => context.select((GameViewModel vm) => vm.oppScore);

  int get extraPoints =>
      context.select((GameViewModel vm) => vm.oppExtraPoints);
  List<PlayingCardModel> get collectedCards =>
      context.select((GameViewModel vm) => vm.oppCollectedCards);

  @override
  Widget build(BuildContext context) {
    bool opponentJoined = opp != null && opp != "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppStyle.theme.playerSectionBox(
        highlightColor: AppStyle.theme.turnHighlight,
        highlight: highlightTurn,
        joined: opponentJoined,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            opponentJoined
                ? "Opponent: ${oppInfo?.name}"
                : "Waiting for opponent...",
            style: AppStyle.theme.mutedText,
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 80, // reserve card height
            child: deckCount == 0
                ? const SizedBox()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      deckCount,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: PlayingCardBack(width: 55),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
