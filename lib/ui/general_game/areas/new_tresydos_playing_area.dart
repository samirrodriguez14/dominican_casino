import 'dart:math' as math;

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/ui/general_game/simple/simple_casino_playing_area.dart';
import 'package:dominican_casino/ui/general_game/widgets/table_play_drop_zone.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Tres y Dos board: opponent row, draw pile, and discard — same chrome as Casino.
class NewTresydosPlayingArea extends StatefulWidget {
  const NewTresydosPlayingArea({super.key});

  @override
  State<NewTresydosPlayingArea> createState() => _NewTresydosPlayingAreaState();
}

class _NewTresydosPlayingAreaState extends State<NewTresydosPlayingArea> {
  static const double _cardWidth = 72;

  /// Empty seats stay visible only while still waiting for players to join.
  String? _oppAt(GeneralGameViewModel vm, int index) {
    if (index < vm.oppIds.length) return vm.oppIds[index];
    if (vm.gameState.gameStatus == GameStatus.waitingForPlayers) return '';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    return Opacity(
      opacity: vm.showInGameControl ? 0.5 : 1,
      child: ListenableBuilder(
        listenable: vm.motion,
        builder: (context, _) {
          final shuffling = vm.motion.isShuffling;
          final topOpp = _oppAt(vm, 0);
          final rightOpp = _oppAt(vm, 1);
          final leftOpp = _oppAt(vm, 2);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: SimpleOpponentRow.height),
                  child: _buildTableRow(vm, shuffling),
                ),
              ),
              if (topOpp != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SimpleOpponentRow(oppId: topOpp),
                ),
              if (rightOpp != null)
                Positioned(
                  right: -120,
                  child: SizedBox(
                    width: 280,
                    child: Transform.rotate(
                      angle: math.pi / 2,
                      child: SimpleOpponentRow(oppId: rightOpp),
                    ),
                  ),
                ),
              if (leftOpp != null)
                Positioned(
                  left: -120,
                  child: SizedBox(
                    width: 280,
                    child: Transform.rotate(
                      angle: -math.pi / 2,
                      child: SimpleOpponentRow(oppId: leftOpp),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableRow(GeneralGameViewModel vm, bool shuffling) {
    return TablePlayDropZone(
      key: vm.tableKey,
      child: Offstage(
        offstage: shuffling,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _drawPile(vm),
              const SizedBox(width: 16),
              _discardPile(vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawPile(GeneralGameViewModel vm) {
    final deckCard = vm.gameState.deck.isNotEmpty
        ? vm.gameState.deck.last
        : null;
    final selected =
        deckCard != null && vm.selectedCards.contains(deckCard);
    final hidden = deckCard != null && vm.isDragHidden(deckCard.id);

    final pile = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IgnorePointer(
          child: CardDeck(
            key: vm.deckKey,
            title: '',
            showLabel: false,
            cardWidth: _cardWidth,
            cards: vm.gameState.deck,
            extraPoints: 0,
            onTap: () {},
          ),
        ),
        if (deckCard != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: selected
                ? Matrix4.translationValues(0, -12, 0)
                : Matrix4.translationValues(0, 4, 0),
            child: Opacity(
              opacity: hidden ? 0 : 1,
              child: FlightAwareCard(
                key: vm.keyForCard(deckCard.id, CardSlot.aux),
                motion: vm.motion,
                cardId: deckCard.id,
                width: _cardWidth,
                child: AnimatedScale(
                  scale: selected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: PlayingCardBack(width: _cardWidth),
                ),
              ),
            ),
          ),
      ],
    );

    if (deckCard == null) return pile;
    return BoardDragHandle(
      source: BoardDragSource.deck(deckCard),
      enabled: vm.canPlayTurn && !vm.hasDropPending,
      feedbackWidth: _cardWidth,
      tableFeedbackWidth: _cardWidth,
      onTap: () => vm.selectCardToTake(deckCard),
      child: pile,
    );
  }

  Widget _discardPile(GeneralGameViewModel vm) {
    final currentCard = vm.playingAreaCards.isNotEmpty
        ? vm.playingAreaCards.last
        : null;
    final buried = vm.gameState.playingArea.length > 1
        ? vm.gameState.playingArea
        : const <PlayingCardModel>[];
    final selected =
        currentCard != null && vm.selectedCards.contains(currentCard);
    final hidden = currentCard != null && vm.isDragHidden(currentCard.id);
    final highlighted =
        vm.dropHover?.target.card?.id == currentCard?.id ||
        vm.dropPending?.target.card?.id == currentCard?.id;

    final pile = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IgnorePointer(
          child: CardDeck(
            title: '',
            back: false,
            showLabel: false,
            cards: buried,
            cardWidth: _cardWidth,
            extraPoints: 0,
            onTap: () {},
          ),
        ),
        if (currentCard != null)
          AnimatedContainer(
            duration: vm.motion.hasFlights
                ? Duration.zero
                : const Duration(milliseconds: 150),
            transform: selected || highlighted
                ? Matrix4.translationValues(0, -12, 0)
                : Matrix4.translationValues(0, 4, 0),
            child: Opacity(
              opacity: hidden ? 0 : 1,
              child: FlightAwareCard(
                key: vm.keyForCard(currentCard.id, CardSlot.table),
                motion: vm.motion,
                cardId: currentCard.id,
                width: _cardWidth,
                child: AnimatedScale(
                  scale: selected || highlighted ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: PlayingCard(
                    playingCardModel: currentCard,
                    isSelected: selected || highlighted,
                    width: _cardWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (currentCard == null) return pile;
    return BoardDragHandle(
      source: BoardDragSource.tableCard(currentCard),
      enabled: vm.canPlayTurn && !vm.hasDropPending,
      feedbackWidth: _cardWidth,
      tableFeedbackWidth: _cardWidth,
      onTap: () => vm.selectCardToTake(currentCard),
      child: pile,
    );
  }
}
