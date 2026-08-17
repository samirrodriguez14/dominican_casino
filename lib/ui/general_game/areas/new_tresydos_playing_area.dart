import 'dart:math' as math;

import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
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
    PlayingCardModel? currentDeckCard = vm.gameState.deck.isNotEmpty
        ? vm.gameState.deck.last
        : null;
    bool isSelected = vm.selectedCards.contains(currentCard);
    bool isSelectedDeck =
        vm.gameState.deck.isNotEmpty &&
        vm.selectedCards.contains(currentDeckCard);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 350,
          child: GenOpponentArea(
            oppId: vm.oppIds.isNotEmpty ? vm.oppIds[0] : "",
          ),
        ),
        Expanded(
          key: vm.tableKey,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                right: -145,
                child: SizedBox(
                  width: 350,
                  child: Transform.rotate(
                    angle: math.pi / 2,
                    child: GenOpponentArea(
                      oppId: vm.oppIds.length >= 2 ? vm.oppIds[1] : "",
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -145,
                child: SizedBox(
                  width: 350,
                  child: Transform.rotate(
                    angle: -math.pi / 2,
                    child: GenOpponentArea(
                      oppId: vm.oppIds.length >= 3 ? vm.oppIds[2] : "",
                    ),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AppStyle.theme.dottedBox(
                            child: Opacity(
                              opacity: vm.motion.isShuffling ? 0 : 1,
                              child: CardDeck(
                                key: vm.deckKey,
                                title: 'Deck',
                                showLabel: false,
                                cards: vm.gameState.deck,
                                cardWidth: cardWidth,
                                extraPoints: 0,
                                onTap: () {
                                  vm.selectCardToTake(
                                    vm.gameState.deck.isNotEmpty
                                        ? vm.gameState.deck[0]
                                        : null,
                                  );
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                          if (currentDeckCard != null && !vm.motion.isShuffling)
                            GestureDetector(
                              onTap: () => vm.selectCardToTake(currentDeckCard),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                transform: isSelectedDeck
                                    ? Matrix4.translationValues(0, -12, 0)
                                    : Matrix4.translationValues(0, 4, 0),
                                child: FlightAwareCard(
                                  key: vm.keyForCard(
                                    currentDeckCard.id,
                                    CardSlot.aux,
                                  ),
                                  card: currentDeckCard,
                                  inFlight:
                                      vm.motion.isInFlight(currentDeckCard.id),
                                  child: AnimatedScale(
                                    scale: isSelectedDeck ? 1.1 : 1.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: PlayingCardBack(width: cardWidth),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: vm.motion.isShuffling ? 0 : 1,
                            child: CardDeck(
                              title: 'Discard',
                              back: false,
                              showLabel: false,
                              cards: (vm.gameState.playingArea.length > 1)
                                  ? vm.gameState.playingArea
                                  : [],
                              cardWidth: cardWidth,
                              extraPoints: 0,
                              onTap: () => {},
                            ),
                          ),
                          if (currentCard != null && !vm.motion.isShuffling)
                            GestureDetector(
                              onTap: () => vm.selectCardToTake(currentCard),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                transform: isSelected
                                    ? Matrix4.translationValues(0, -12, 0)
                                    : Matrix4.translationValues(0, 4, 0),
                                child: FlightAwareCard(
                                  key: vm.keyForCard(
                                    currentCard.id,
                                    CardSlot.table,
                                  ),
                                  card: currentCard,
                                  inFlight:
                                      vm.motion.isInFlight(currentCard.id),
                                  child: AnimatedScale(
                                    scale: isSelected ? 1.1 : 1.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: PlayingCard(
                                      playingCardModel: currentCard,
                                      isSelected: isSelected,
                                      width: cardWidth,
                                    ),
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
