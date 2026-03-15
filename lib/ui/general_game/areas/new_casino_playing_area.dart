import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/game/popups/players_deck_content.dart';
import 'package:dominican_casino/ui/cards/playing_area_stack.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/general_game/areas/gen_opponent_area.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class NewCasinoPlayingArea extends StatefulWidget {
  const NewCasinoPlayingArea({super.key});
  @override
  State<NewCasinoPlayingArea> createState() => NewCasinoPlayingAreaState();
}

class NewCasinoPlayingAreaState extends State<NewCasinoPlayingArea> {
  GeneralGameViewModel get vm => context.read<GeneralGameViewModel>();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: (vm.inGameAction != InGameAction.noAction) ? 0.5 : 1,
      child: Column(
        children: [
          //OPP CARDS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: GenOpponentArea(key: vm.oppHandKey),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: (vm.inGameAction != InGameAction.noAction)
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    AppStyle.theme.dottedBox(
                      child: CardDeck(
                        key: vm.deckKey,
                        title: "Dealing",
                        cardWidth: 55,
                        cards: vm.gameState.deck,
                        extraPoints: 0,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

                //TABLE AREA PLAYING CARDS
                Expanded(
                  key: vm.tableKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      // horizontal: 12,
                      vertical: 18,
                    ),
                    child: _buildCardWrap(context, vm),
                  ),

                  //   ],
                ),
                //COLLECTED CARDS AREAS
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppStyle.theme.dottedBox(
                      child: CardDeck(
                        key: vm.oppDeckKey,
                        title: "Opp's Deck",
                        cardWidth: 55,
                        cards: vm.oppCollectedCards,
                        extraPoints: 0, //vm.oppExtraPoints,
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
                      child: CardDeck(
                        key: vm.myDeckKey,
                        title: 'My Deck',
                        cardWidth: 55,
                        cards: vm.myCollectedCards,
                        extraPoints: 0, // vm.myExtraPoints,
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

  Widget _buildCardWrap(BuildContext context, GeneralGameViewModel vm) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        ...vm.playingAreaStacks.map((stack) {
          bool isSelected = vm.selectedStacks.contains(stack);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => vm.selectStack(stack),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: isSelected
                  ? Matrix4.translationValues(0, -12, 0)
                  : Matrix4.identity(),
              child:
              Opacity(
                opacity: vm.stackContainsCardHidded(stack.cards) ? 0.0 : 1.0,
                child: 
               PlayingAreaStack(stack: stack, isSelected: isSelected),
            ),)
          );
        }),

        ...vm.playingAreaCards.map((c) {
          bool isSelected = vm.selectedCards.contains(c);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,

            onTap: () => vm.selectCardToStack(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: isSelected
                  ? Matrix4.translationValues(0, -12, 0)
                  : Matrix4.identity(),
              child: Opacity(
                opacity: vm.isCardHidden(c) ? 0.0 : 1.0,
                child: PlayingCard(
                  key: vm.keyForCard(c.id),

                  playingCardModel: c,
                  isSelected: isSelected,
                  width: 70,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
