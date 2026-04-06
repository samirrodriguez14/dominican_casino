import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/general_game/areas/gen_opponent_area.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class NewTresydosPlayingArea extends StatefulWidget {
  const NewTresydosPlayingArea({super.key});

  @override
  State<StatefulWidget> createState() => NewTresydosPlayingAreaState();
}

class NewTresydosPlayingAreaState extends State<NewTresydosPlayingArea> {
  GeneralGameViewModel get vm => context.read<GeneralGameViewModel>();
  final double cardWidth = 60;
  @override
  Widget build(BuildContext context) {
    PlayingCardModel? currentCard = vm.playingAreaCards.isNotEmpty
        ? vm.playingAreaCards.last
        : null;
    bool isSelected = vm.selectedCards.contains(currentCard);
    bool isSelectedDeck = vm.selectedCards.contains(vm.gameState.deck[0]);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 350, child: GenOpponentArea()),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Positioned(
              //   right: -140,
              //   child: SizedBox(
              //     width: 350,
              //     child: Transform.rotate(
              //       angle: math.pi / 2,
              //       child: GenOpponentArea(),
              //     ),
              //   ),
              // ),
              // Positioned(
              //   left: -140,
              //   child: SizedBox(
              //     width: 350,
              //     child: Transform.rotate(
              //       angle: -math.pi / 2,
              //       child: GenOpponentArea(),
              //     ),
              //   ),
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppStyle.theme.dottedBox(
                        color: isSelectedDeck ? AppStyle.theme.border : null,
                        child: CardDeck(
                          title: 'Deck',
                          cards: vm.gameState.deck,
                          cardWidth: cardWidth,
                          extraPoints: 0,
                          onTap: () {
                            vm.selectCardToTake(vm.gameState.deck[0]);
                            setState(() {
                              
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: .end,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (vm.gameState.playingArea.length > 1)
                            CardDeck(
                              title: 'Discard',
                              back: false,
                              cards: vm.gameState.playingArea,
                              cardWidth: cardWidth,
                              extraPoints: 0,
                              onTap: () => {},
                            ),
                          if (currentCard != null)
                            GestureDetector(
                              onTap: () => vm.selectCardToTake(currentCard),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                transform: isSelected
                                    ? Matrix4.translationValues(0, -12, 0)
                                    : Matrix4.identity(),
                                child: Opacity(
                                  opacity: vm.isCardHidden(currentCard)
                                      ? 0.0
                                      : 1.0,
                                  child: PlayingCard(
                                    key: vm.keyForCard(currentCard.id),
                                    playingCardModel: currentCard,
                                    isSelected: isSelected,
                                    width: cardWidth,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
