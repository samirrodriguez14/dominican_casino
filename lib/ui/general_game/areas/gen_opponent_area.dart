import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class GenOpponentArea extends StatefulWidget {
  String oppId;
  GenOpponentArea({super.key, required this.oppId});
  @override
  State<StatefulWidget> createState() => GenOpponentAreaState();
}

class GenOpponentAreaState extends State<GenOpponentArea> {
  String? get opp => widget.oppId;

  @override
  Widget build(BuildContext context) {
    GeneralGameViewModel vm = context.read<GeneralGameViewModel>();
    bool highlightTurn =
        vm.gameState.round.roundStatus == .playing &&
        vm.gameState.currentTurnPlayerId == opp;
    bool opponentJoined = opp != null && opp != "";
    List<PlayingCardModel> collectedCards = vm.gameState.hands[opp] ?? [];
    String oppName = vm.gameState.playersInfo[opp]?['name'] ?? "";

    return Container(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            opponentJoined ? "Opponent: $oppName" : "Waiting for opponent...",
            style: AppStyle.theme.mutedText,
          ),
          const SizedBox(height: 8),

          AppStyle.theme.dottedBox(
            color: highlightTurn
                ? AppStyle.theme.turnHighlight.withValues(alpha: 0.35)
                : null,

            child: SizedBox(
              height: 80, // reserve card height
              width: 80 * 3,

              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cards = collectedCards;
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
                                child: AnimatedScale(
                                  scale: vm.isCardHidden(cards[i]) ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  child: (vm.gameState.round.roundStatus ==
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
