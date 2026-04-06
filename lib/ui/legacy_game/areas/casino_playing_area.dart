import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/ui/legacy_game/areas/opponent_area.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/legacy_game/game_screen.dart';
import 'package:dominican_casino/ui/legacy_game/popups/players_deck_content.dart';
import 'package:dominican_casino/ui/legacy_game/game_view_model.dart';
import 'package:dominican_casino/ui/cards/playing_area_stack.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PlayingArea extends StatefulWidget {
  const PlayingArea({super.key});
  @override
  State<StatefulWidget> createState() => PlayingAreaState();
}

class PlayingAreaState extends State<PlayingArea> {
  GameViewModel get vm => context.read<GameViewModel>();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: vm.canControlGame ? 0.5 : 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: const OpponentArea(),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: (vm.isController)
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    AppStyle.theme.dottedBox(
                      child: CardDeck(
                        back: true,
                        title: "Dealing",
                        cardWidth: 55,
                        cards: vm.g?.deck ?? [],
                        extraPoints: 0,
                        onTap: () {
                          GameScreenState.showGameStatusPopup(context, vm);
                        },
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      // horizontal: 12,
                      vertical: 18,
                    ),
                    child: _buildCardWrap(context, vm),
                  ),

                  //   ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppStyle.theme.dottedBox(
                      color: vm.lastTakeOpp ? AppStyle.theme.border : null,
                      child: CardDeck(
                        back: true,
                        title: "Opp's Deck",
                        cardWidth: 55,
                        cards: vm.oppCollectedCards,
                        extraPoints: vm.oppExtraPoints,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          showAppPopup(
                            context: context,
                            title: "Opponent's Collected Cards",
                            content: CollectedCardsStrip(
                              cards: vm.oppCollectedCards,
                            ),
                          );
                        },
                      ),
                    ),

                    AppStyle.theme.dottedBox(
                      color: vm.lastTakeMe ? AppStyle.theme.border : null,

                      child: CardDeck(
                        back: true,
                        title: 'My Deck',
                        cardWidth: 55,
                        cards: vm.myCollectedCards,
                        extraPoints: vm.myExtraPoints,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          showAppPopup(
                            context: context,
                            title: "My Collected Cards",
                            content: CollectedCardsStrip(
                              cards: vm.myCollectedCards,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrap(BuildContext context, GameViewModel vm) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        ...vm.playingAreaStacks.map((stack) {
          bool isSelected = vm.selectedStacks.contains(stack);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: (vm.canControlGame || !vm.isMyTurn)
                ? null
                : () => vm.selectStack(stack),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: isSelected
                  ? Matrix4.translationValues(0, -12, 0)
                  : Matrix4.identity(),
              child: PlayingAreaStack(stack: stack, isSelected: isSelected),
            ),
          );
        }),

        ...vm.playingAreaCards.map((c) {
          bool isSelected = vm.selectedCards.contains(c);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,

            onTap: (vm.canControlGame || !vm.isMyTurn)
                ? null
                : () => vm.selectCardToStack(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: isSelected
                  ? Matrix4.translationValues(0, -12, 0)
                  : Matrix4.identity(),
              child: PlayingCard(
                playingCardModel: c,
                isSelected: isSelected,
                width: 70,
              ),
            ),
          );
        }),
      ],
    );
  }
}
