import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/table_slot.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/animations/sliding_card_layout.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/general_game/popups/players_deck_content.dart';
import 'package:dominican_casino/ui/cards/playing_area_stack.dart';
import 'package:dominican_casino/ui/general_game/areas/gen_opponent_area.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class NewCasinoPlayingArea extends StatefulWidget {
  const NewCasinoPlayingArea({super.key});
  @override
  State<NewCasinoPlayingArea> createState() => NewCasinoPlayingAreaState();
}

class NewCasinoPlayingAreaState extends State<NewCasinoPlayingArea> {
  GeneralGameViewModel get vm => context.read<GeneralGameViewModel>();
  final double tableCardWidth = 60;
  static const double _stackOverlap = 30;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: vm.showInGameControl ? 0.5 : 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: GenOpponentArea(
              key: vm.oppHandKey,
              oppId: vm.oppIds.isNotEmpty ? vm.oppIds.first : "",
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: (vm.gameState.controllerId == vm.me)
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    AppStyle.theme.dottedBox(
                      child: Opacity(
                        opacity: vm.motion.isShuffling ? 0 : 1,
                        child: CardDeck(
                          key: vm.deckKey,
                          title: "Dealing",
                          cardWidth: tableCardWidth,
                          cards: vm.gameState.deck,
                          extraPoints: 0,
                          onTap: () {},
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  key: vm.tableKey,
                  child: Opacity(
                    opacity: vm.motion.isShuffling ? 0 : 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: _buildTableSlots(context, vm),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AppStyle.theme.dottedBox(
                            color: vm.gameState.lastTookCardId == vm.opp
                                ? AppStyle.theme.border
                                : null,
                            child: Opacity(
                              opacity: vm.motion.isShuffling ? 0 : 1,
                              child: CardDeck(
                                key: vm.oppDeckKey,
                                title: "Opp's Deck",
                                cardWidth: tableCardWidth,
                                cards: vm.oppCollectedCards,
                                extraPoints: vm.oppExtraPoints,
                                holdExtraReveal: vm.motion.hasFlights,
                                onTap: () {
                                  AppHaptics.selectionClick();
                                  SoundService.instance.play(
                                    GameSound.softCard,
                                  );
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
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AppStyle.theme.dottedBox(
                            color: vm.gameState.lastTookCardId == vm.me
                                ? AppStyle.theme.border
                                : null,
                            child: Opacity(
                              opacity: vm.motion.isShuffling ? 0 : 1,
                              child: CardDeck(
                                key: vm.myDeckKey,
                                title: 'My Deck',
                                cardWidth: tableCardWidth,
                                cards: vm.myCollectedCards,
                                extraPoints: vm.myExtraPoints,
                                holdExtraReveal: vm.motion.hasFlights,
                                onTap: () {
                                  AppHaptics.selectionClick();
                                  SoundService.instance.play(
                                    GameSound.softCard,
                                  );
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
                          ),
                        ),
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

  Widget _buildTableSlots(BuildContext context, GeneralGameViewModel vm) {
    final tableH = tableCardWidth * 1.4;
    final slots = vm.gameState.tableSlots;

    return SlidingCardLayout(
      itemHeight: tableH,
      spacing: 10,
      runSpacing: 10,
      slots: [
        for (final slot in slots)
          switch (slot) {
            TableCardSlot(:final card) => SlidingSlot(
              key: ValueKey(slot.orderKey),
              width: slot.widthFor(cardWidth: tableCardWidth),
              child: _looseCard(vm, card),
            ),
            TableStackSlot(:final stack) => SlidingSlot(
              key: ValueKey(slot.orderKey),
              width: slot.widthFor(
                cardWidth: tableCardWidth,
                overlap: _stackOverlap,
              ),
              child: _stackSlot(vm, stack),
            ),
          },
      ],
    );
  }

  Widget _looseCard(GeneralGameViewModel vm, PlayingCardModel card) {
    final isSelected = vm.selectedCards.contains(card);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => vm.selectCardToStack(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: isSelected
            ? Matrix4.translationValues(0, -12, 0)
            : Matrix4.identity(),
        child: FlightAwareCard(
          key: vm.keyForCard(card.id, CardSlot.table),
          card: card,
          inFlight: vm.motion.isInFlight(card.id),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: isSelected ? 1.06 : 1.0,
            child: PlayingCard(
              playingCardModel: card,
              isSelected: isSelected,
              width: tableCardWidth,
            ),
          ),
        ),
      ),
    );
  }

  Widget _stackSlot(GeneralGameViewModel vm, PlayingAreaStackModel stack) {
    final isSelected = vm.selectedStacks.contains(stack);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => vm.selectStack(stack),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: isSelected
            ? Matrix4.translationValues(0, -12, 0)
            : Matrix4.identity(),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: isSelected ? 1.06 : 1.0,
          child: KeyedSubtree(
            key: vm.keyForStack(stack.id),
            child: PlayingAreaStack(
              stack: stack,
              isSelected: isSelected,
              cardWidth: tableCardWidth,
              overlap: _stackOverlap,
              cardKeyFor: (c) => vm.keyForCard(c.id, CardSlot.inStack),
              cardInFlight: (c) => vm.motion.isInFlight(c.id),
            ),
          ),
        ),
      ),
    );
  }
}
