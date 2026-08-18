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
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/ui/general_game/widgets/table_play_drop_zone.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
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
  final double tableCardWidth = 60;
  static const double _stackOverlap = 30;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    return Opacity(
      opacity: vm.showInGameControl ? 0.5 : 1,
      child: ListenableBuilder(
        listenable: vm.motion,
        builder: (context, _) {
          final shuffling = vm.motion.isShuffling;
          final holdExtras = vm.motion.hasFlights;
          return Column(
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
                          child: Offstage(
                            offstage: shuffling,
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
                      child: TablePlayDropZone(
                        child: Offstage(
                          offstage: shuffling,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const vPad = 18.0;
                              return SingleChildScrollView(
                                physics: vm.isBoardDragging
                                    ? const NeverScrollableScrollPhysics()
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                  vertical: vPad,
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: (constraints.maxHeight - vPad * 2)
                                        .clamp(0.0, double.infinity),
                                  ),
                                  child: Center(
                                    child: _buildTableSlots(context, vm),
                                  ),
                                ),
                              );
                            },
                          ),
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
                                child: Offstage(
                                  offstage: shuffling,
                                  child: CardDeck(
                                    key: vm.oppDeckKey,
                                    title: "Opp's Deck",
                                    cardWidth: tableCardWidth,
                                    cards: vm.oppCollectedCards,
                                    extraPoints: vm.oppExtraPoints,
                                    holdExtraReveal: holdExtras,
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
                                child: Offstage(
                                  offstage: shuffling,
                                  child: CardDeck(
                                    key: vm.myDeckKey,
                                    title: 'My Deck',
                                    cardWidth: tableCardWidth,
                                    cards: vm.myCollectedCards,
                                    extraPoints: vm.myExtraPoints,
                                    holdExtraReveal: holdExtras,
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
          );
        },
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
              width: _slotWidthForCard(vm, card),
              child: _looseCard(vm, card),
            ),
            TableStackSlot(:final stack) => SlidingSlot(
              key: ValueKey(slot.orderKey),
              width: _slotWidthForStack(vm, stack),
              child: _stackSlot(vm, stack),
            ),
          },
      ],
    );
  }

  double _slotWidthForCard(GeneralGameViewModel vm, PlayingCardModel card) {
    // Preview must not expand the slot — layout stays put until commit.
    return tableCardWidth;
  }

  double _slotWidthForStack(
    GeneralGameViewModel vm,
    PlayingAreaStackModel stack,
  ) {
    final n = stack.cards.length;
    if (n <= 1) return tableCardWidth;
    return tableCardWidth + (n - 1) * (tableCardWidth - _stackOverlap);
  }

  Widget _looseCard(GeneralGameViewModel vm, PlayingCardModel card) {
    final isSelected = vm.selectedCards.contains(card);
    final preview = vm.previewForTarget(cardId: card.id);
    final hidden = vm.isDragHidden(card.id);
    final highlighted =
        vm.dropHover?.target.card?.id == card.id ||
        vm.dropPending?.target.card?.id == card.id;

    final Widget face;
    if (preview != null) {
      // Keep the table GlobalKey on a sized box so hit-tests stay stable while
      // the provisional merge paints as a stack. [stack.cards] stays the
      // original single card so width is locked during preview.
      face = KeyedSubtree(
        key: vm.keyForCard(card.id, CardSlot.table),
        child: PlayingAreaStack(
          stack: PlayingAreaStackModel(
            id: 'preview_${card.id}',
            cards: [card],
            stackValue: preview.total,
            paired: false,
          ),
          motion: vm.motion,
          cardWidth: tableCardWidth,
          overlap: _stackOverlap,
          isSelected: true,
          previewCards: preview.previewCards,
          previewLabel: preview.label,
        ),
      );
    } else {
      face = Opacity(
        opacity: hidden ? 0 : 1,
        child: FlightAwareCard(
          key: vm.keyForCard(card.id, CardSlot.table),
          motion: vm.motion,
          cardId: card.id,
          width: tableCardWidth,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: isSelected || highlighted ? 1.06 : 1.0,
            child: PlayingCard(
              playingCardModel: card,
              isSelected: isSelected || highlighted,
              width: tableCardWidth,
            ),
          ),
        ),
      );
    }

    return BoardDragHandle(
      source: BoardDragSource.tableCard(card),
      enabled: vm.canPlayTurn && !vm.hasDropPending,
      feedbackWidth: tableCardWidth,
      tableFeedbackWidth: tableCardWidth,
      onTap: () => vm.selectCardToStack(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: isSelected || highlighted
            ? Matrix4.translationValues(0, -12, 0)
            : Matrix4.identity(),
        child: face,
      ),
    );
  }

  Widget _stackSlot(GeneralGameViewModel vm, PlayingAreaStackModel stack) {
    final isSelected = vm.selectedStacks.contains(stack);
    final preview = vm.previewForTarget(stackId: stack.id);
    final hidden = vm.isDragHidden(stack.id);
    final highlighted =
        vm.dropHover?.target.stack?.id == stack.id ||
        vm.dropPending?.target.stack?.id == stack.id;

    return BoardDragHandle(
      source: BoardDragSource.tableStack(stack),
      enabled: vm.canPlayTurn && !vm.hasDropPending,
      feedbackWidth: tableCardWidth,
      tableFeedbackWidth: tableCardWidth,
      onTap: () => vm.selectStack(stack),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: isSelected || highlighted
            ? Matrix4.translationValues(0, -12, 0)
            : Matrix4.identity(),
        child: Opacity(
          opacity: hidden ? 0 : 1,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: isSelected || highlighted ? 1.06 : 1.0,
            child: KeyedSubtree(
              key: vm.keyForStack(stack.id),
              child: PlayingAreaStack(
                stack: stack,
                isSelected: isSelected || highlighted,
                cardWidth: tableCardWidth,
                overlap: _stackOverlap,
                motion: vm.motion,
                cardKeyFor: (c) => vm.keyForCard(c.id, CardSlot.inStack),
                previewCards: preview?.previewCards,
                previewLabel: preview?.label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
