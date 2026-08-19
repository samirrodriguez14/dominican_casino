import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/ui/general_game/game_status_sheet.dart';
import 'package:dominican_casino/ui/general_game/simple/simple_casino_playing_area.dart';
import 'package:dominican_casino/ui/general_game/widgets/table_play_drop_zone.dart';
import 'package:dominican_casino/ui/widgets/player_score_avatar.dart';
import 'package:dominican_casino/ui/widgets/reaction_bubble.dart';
import 'package:dominican_casino/ui/widgets/take_hint_bounce.dart';
import 'package:dominican_casino/ui/widgets/winning_hand_wave.dart';
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

enum _TableSeat { left, top, right }

class _NewTresydosPlayingAreaState extends State<NewTresydosPlayingArea> {
  static const double _cardWidth = 72;

  /// Open chairs stay until Start. Filled friends sit where they will after kickoff.
  String? _seatFor(GeneralGameViewModel vm, _TableSeat seat) {
    final opps = vm.oppIds;
    final n = opps.length;
    final filled = switch (seat) {
      _TableSeat.left => n >= 2 ? opps[0] : null,
      _TableSeat.top => n == 0 ? null : (n == 1 ? opps[0] : opps[1]),
      _TableSeat.right => n >= 3 ? opps[2] : null,
    };
    if (filled != null) return filled;
    if (vm.showOpenSeats) return '';
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
          final topOpp = _seatFor(vm, _TableSeat.top);
          final leftOpp = _seatFor(vm, _TableSeat.left);
          final rightOpp = _seatFor(vm, _TableSeat.right);
          const sideInset = 78.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: SimpleOpponentRow.height,
                    left: leftOpp != null ? sideInset : 0,
                    right: rightOpp != null ? sideInset : 0,
                  ),
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
                  right: 8,
                  top: SimpleOpponentRow.height,
                  bottom: 0,
                  child: Center(
                    child: _CompactSideSeat(
                      oppId: rightOpp,
                      overlayAlign: Alignment.centerRight,
                    ),
                  ),
                ),
              if (leftOpp != null)
                Positioned(
                  left: 8,
                  top: SimpleOpponentRow.height,
                  bottom: 0,
                  child: Center(
                    child: _CompactSideSeat(
                      oppId: leftOpp,
                      overlayAlign: Alignment.centerLeft,
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
          TakeHintBounce(
            active: vm.needsTakeHint,
            slot: 0,
            child: AnimatedContainer(
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
            .sublist(0, vm.gameState.playingArea.length - 1)
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
          TakeHintBounce(
            active: vm.needsTakeHint,
            slot: 1,
            child: AnimatedContainer(
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
          ),
      ],
    );

    if (currentCard == null) return pile;
    return BoardDragHandle(
      source: BoardDragSource.tableCard(currentCard),
      enabled: vm.canPlayTurn && !vm.hasDropPending,
      feedbackWidth: _cardWidth,
      tableFeedbackWidth: _cardWidth,
      onTap: () {
        final card = vm.selectedCard;
        if (card != null && vm.canDropPlay(card)) {
          vm.playSelectedToTable();
          return;
        }
        vm.selectCardToTake(currentCard);
      },
      child: pile,
    );
  }
}

/// Side opponent: score avatar with a tight overlapped hand underneath.
class _CompactSideSeat extends StatelessWidget {
  const _CompactSideSeat({
    required this.oppId,
    required this.overlayAlign,
  });

  static const double cardWidth = 30;
  static const double overlap = 8;
  static const double avatarSize = 48;
  static const double winCardWidth = 50;
  static const double winOverlap = 18;

  final String oppId;
  final Alignment overlayAlign;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (oppId.isEmpty && !vm.showOpenSeats) {
      return const SizedBox.shrink();
    }

    final waiting = oppId.isEmpty;
    final highlightTurn = !waiting && vm.isSeatTurn(oppId);
    final cards = waiting ? const <PlayingCardModel>[] : (vm.gameState.hands[oppId] ?? []);
    final info = waiting
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(vm.gameState.playersInfo[oppId] ?? {});
    final celebrating = !waiting && vm.isCelebratingHand(oppId);
    const layoutW = _CompactSideSeat.cardWidth;
    const layoutOverlap = _CompactSideSeat.overlap;
    final visW = celebrating ? _CompactSideSeat.winCardWidth : layoutW;
    final visOverlap = celebrating ? _CompactSideSeat.winOverlap : layoutOverlap;
    final avatarId = info['avatarId'] as String?;
    final name = waiting
        ? AppLocalizations.of(context).openSeat
        : ((info['name'] as String?) ?? 'Rival');
    final score = waiting ? 0 : (vm.gameState.scores[oppId] ?? 0);
    final incoming = !waiting && vm.incomingReaction?.fromPid == oppId
        ? vm.incomingReaction
        : null;
    const layoutH = layoutW * 1.4;
    final visH = visW * 1.4;
    final layoutHandW = cards.isEmpty
        ? layoutW
        : layoutW + ((cards.length - 1) * layoutOverlap);
    final visHandW = cards.isEmpty
        ? visW
        : visW + ((cards.length - 1) * visOverlap);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            PlayerScoreAvatar(
              avatarId: avatarId,
              name: name,
              score: score,
              pendingCoins: waiting ? 0 : vm.revealedPendingFor(oppId),
              size: avatarSize,
              isTurn: highlightTurn,
              isOpen: waiting,
              turnDeadline: waiting ? null : vm.turnDeadlineFor(oppId),
              turnTotal: vm.turnTotal,
              onPressed: waiting
                  ? null
                  : () {
                      AppHaptics.mediumImpact();
                      showGameStatusPopup(context, vm: vm);
                    },
            ),
            Positioned(
              top: -36,
              child: IgnorePointer(
                child: ReactionBubblePopup(
                  emoji: incoming?.emoji,
                  reactionId: incoming?.id,
                  tail: ReactionBubbleTail.bottom,
                ),
              ),
            ),
          ],
        ),
        if (!waiting) ...[
          const SizedBox(height: 8),
          Offstage(
            offstage: vm.motion.isShuffling,
            child: SizedBox(
              width: layoutHandW,
              height: layoutH,
              child: OverflowBox(
                alignment: overlayAlign,
                minWidth: visHandW,
                maxWidth: visHandW,
                minHeight: visH,
                maxHeight: visH,
                child: SizedBox(
                  width: visHandW,
                  height: visH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (int i = 0; i < cards.length; i++)
                        Positioned(
                          left: i * visOverlap,
                          child: WinningHandWave(
                            active: celebrating,
                            index: i,
                            amplitude: 3,
                            child: FlightAwareCard(
                              key: vm.keyForCard(cards[i].id, CardSlot.oppHand),
                              motion: vm.motion,
                              cardId: cards[i].id,
                              width: visW,
                              child: vm.gameState.round.roundStatus ==
                                      RoundStatus.completed
                                  ? PlayingCard(
                                      playingCardModel: cards[i],
                                      isSelected: celebrating,
                                      width: visW,
                                    )
                                  : PlayingCardBack(width: visW),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
