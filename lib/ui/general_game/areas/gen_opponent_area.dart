import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class GenOpponentArea extends StatefulWidget {
  const GenOpponentArea({super.key});
  @override
  State<StatefulWidget> createState() => GenOpponentAreaState();
}

class GenOpponentAreaState extends State<GenOpponentArea> {
  bool get highlightTurn =>
      context.select((GeneralGameViewModel vm) => !vm.isMyTurn);
  String? get opp => context.select((GeneralGameViewModel vm) => vm.opp);
  // Player? get oppInfo => context.select((GeneralGameViewModel vm) => vm.oppInfo);
  int get deckCount =>
      context.select((GeneralGameViewModel vm) => vm.oppHandCard.length);
  int get score => context.select((GeneralGameViewModel vm) => 0);

  int get extraPoints => context.select((GeneralGameViewModel vm) => 0);
  List<PlayingCardModel> get collectedCards =>
      context.select((GeneralGameViewModel vm) => vm.oppCollectedCards);

  @override
  Widget build(BuildContext context) {
    GeneralGameViewModel vm = context.read<GeneralGameViewModel>();

    bool opponentJoined = opp != null && opp != "";

    return Container(
      // width: double.infinity,
      padding: const EdgeInsets.all(12),
      // decoration: AppStyle.theme.playerSectionBox(
      //   highlightColor: AppStyle.theme.turnHighlight,
      //   highlight: highlightTurn,
      //   joined: opponentJoined,
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            opponentJoined ? "Opponent: ..." : "Waiting for opponent...",
            style: AppStyle.theme.mutedText,
          ),
          const SizedBox(height: 8),

          AppStyle.theme.dottedBox(
            child: SizedBox(
              height: 80, // reserve card height
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cards = vm.oppHandCard;
                  const cardWidth = 50.0;

                  if (cards.isEmpty) return const SizedBox.shrink();

                  final count = cards.length;
                  final gap = count == 1
                      ? 0.0
                      : ((constraints.maxWidth - cardWidth) / (count - 1))
                            .clamp(12.0, 55.0);

                  final totalWidth = cardWidth + ((count - 1) * gap);

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: 80,
                    child: Center(
                      child: SizedBox(
                        width: totalWidth,
                        height: 80,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (int i = 0; i < count; i++)
                              Positioned(
                                left: i * gap,
                                child: Opacity(
                                  opacity: vm.isCardHidden(cards[i])
                                      ? 0.0
                                      : 1.0,
                                  child:
                                      (vm.gameState.round.roundStatus ==
                                          .completed)
                                      ? PlayingCard(
                                          playingCardModel: cards[i],
                                          isSelected: false,
                                          width: cardWidth,
                                        )
                                      : PlayingCardBack(width: cardWidth),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
