import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/models/table_slot.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/animations/sliding_card_layout.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_area_stack.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/ui/general_game/hand_fan_layout.dart';
import 'package:dominican_casino/ui/general_game/widgets/table_play_drop_zone.dart';
import 'package:dominican_casino/ui/general_game/game_status_sheet.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_hint_pulse.dart';
import 'package:dominican_casino/ui/widgets/player_score_avatar.dart';
import 'package:dominican_casino/ui/widgets/reaction_bubble.dart';
import 'package:dominican_casino/ui/widgets/winning_hand_wave.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Casino board: opponent row, open table, and collected piles.
class SimpleCasinoPlayingArea extends StatefulWidget {
  const SimpleCasinoPlayingArea({super.key});

  @override
  State<SimpleCasinoPlayingArea> createState() =>
      _SimpleCasinoPlayingAreaState();
}

class _SimpleCasinoPlayingAreaState extends State<SimpleCasinoPlayingArea> {
  /// Open table cards — larger than the side piles so they stay readable.
  final double tableCardWidth = 72;
  static const double _pileCardWidth = 52;
  static const double _stackOverlap = 36;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    return Opacity(
      opacity: vm.showInGameControl ? 0.5 : 1,
      child: ListenableBuilder(
        listenable: vm.motion,
        builder: (context, _) {
          final shuffling = vm.motion.isShuffling;
          final holdExtras = vm.isAnimating || vm.motion.hasFlights;
          // Opponent row paints last so avatar / reaction bubbles sit above
          // the Opp collected pile instead of sliding under it.
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: SimpleOpponentRow.height,
                  ),
                  child: _buildTableRow(vm, shuffling, holdExtras),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _SimpleOpponentRowHost(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableRow(
    GeneralGameViewModel vm,
    bool shuffling,
    bool holdExtras,
  ) {
    final iAmDealer = vm.gameState.controllerId == vm.me;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: _pileCardWidth + 8,
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            alignment: iAmDealer ? Alignment.bottomCenter : Alignment.topCenter,
            child: Offstage(
              offstage: shuffling,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: iAmDealer ? 8 : 0,
                  top: iAmDealer ? 0 : 8,
                  left: 8,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  clipBehavior: Clip.none,
                  child: CardDeck(
                    key: vm.deckKey,
                    title: '',
                    showLabel: false,
                    cardWidth: _pileCardWidth,
                    cards: vm.gameState.deck,
                    extraPoints: 0,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          key: vm.tableKey,
          child: TablePlayDropZone(
            child: Offstage(
              offstage: shuffling,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const vPad = 12.0;
                  return SingleChildScrollView(
                    physics: vm.isBoardDragging
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: vPad),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - vPad * 2).clamp(
                          0.0,
                          double.infinity,
                        ),
                      ),
                      child: Center(
                        child: KeyedSubtree(
                          key: vm.tableContentKey,
                          child: _buildTableSlots(context, vm),
                        ),
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
                  clipBehavior: Clip.none,
                  child: Offstage(
                    offstage: shuffling,
                    child: TutorialPulse(
                      bounce: false,
                      targetKey: vm.oppDeckKey,
                      child: CardDeck(
                        key: vm.oppDeckKey,
                        title: 'Opp',
                        titleBelow: true,
                        showLabel: false,
                        cardWidth: _pileCardWidth,
                        cards: vm.oppCollectedCards,
                        extraPoints: vm.oppExtraPoints,
                        lastTakenCards: vm.oppLastTake,
                        lastCapturer: vm.gameState.lastTookCardId == vm.opp,
                        holdExtraReveal: holdExtras,
                        onTap: () {},
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
                  clipBehavior: Clip.none,
                  child: Offstage(
                    offstage: shuffling,
                    child: TutorialPulse(
                      bounce: false,
                      targetKey: vm.myDeckKey,
                      child: CardDeck(
                        key: vm.myDeckKey,
                        title: 'Mine',
                        titleBelow: true,
                        showLabel: false,
                        cardWidth: _pileCardWidth,
                        cards: vm.myCollectedCards,
                        extraPoints: vm.myExtraPoints,
                        lastTakenCards: vm.myLastTake,
                        lastCapturer: vm.gameState.lastTookCardId == vm.me,
                        holdExtraReveal: holdExtras,
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
              key: ValueKey(slot.layoutAnchor),
              width: tableCardWidth,
              child: _looseCard(vm, card),
            ),
            TableStackSlot(:final stack) => SlidingSlot(
              key: ValueKey(slot.layoutAnchor),
              width: _slotWidthForStack(vm, stack),
              child: _stackSlot(vm, stack),
            ),
          },
      ],
    );
  }

  double _slotWidthForStack(
    GeneralGameViewModel vm,
    PlayingAreaStackModel stack,
  ) {
    final settled = stack.cards
        .where((c) => !vm.motion.isInFlight(c.id))
        .length;
    final n = settled <= 0 ? 1 : settled;
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
      final tableKey = vm.keyForCard(card.id, CardSlot.table);
      face = Opacity(
        opacity: hidden ? 0 : 1,
        child: TutorialPulse(
          cardId: card.id,
          targetKey: tableKey,
          child: FlightAwareCard(
            key: tableKey,
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
        duration: vm.motion.hasFlights
            ? Duration.zero
            : const Duration(milliseconds: 150),
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
        duration: vm.motion.hasFlights
            ? Duration.zero
            : const Duration(milliseconds: 150),
        transform: isSelected || highlighted
            ? Matrix4.translationValues(0, -12, 0)
            : Matrix4.identity(),
        child: Opacity(
          opacity: hidden ? 0 : 1,
          child: AnimatedScale(
            duration: vm.motion.hasFlights
                ? Duration.zero
                : const Duration(milliseconds: 150),
            scale: isSelected || highlighted ? 1.06 : 1.0,
            child: TutorialPulse(
              stackId: stack.id,
              targetKey: vm.keyForStack(stack.id),
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
      ),
    );
  }
}

class _SimpleOpponentRowHost extends StatelessWidget {
  const _SimpleOpponentRowHost();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    return SimpleOpponentRow(
      oppId: vm.oppIds.isNotEmpty ? vm.oppIds.first : '',
    );
  }
}

class SimpleOpponentRow extends StatelessWidget {
  const SimpleOpponentRow({
    super.key,
    required this.oppId,
    this.avatarKeyOverride,
  });

  static const double height = 104;
  static const double cardWidth = 54;

  final String oppId;
  final GlobalKey? avatarKeyOverride;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (oppId.isEmpty && !vm.showOpenSeats) {
      return const SizedBox.shrink();
    }

    const cardWidth = SimpleOpponentRow.cardWidth;
    const rowHeight = SimpleOpponentRow.height;

    final highlightTurn =
        vm.gameState.round.roundStatus == RoundStatus.playing &&
        vm.gameState.currentTurnPlayerId == oppId;
    final celebrating = vm.isCelebratingHand(oppId);
    final cards = vm.gameState.hands[oppId] ?? [];

    return SizedBox(
      height: rowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Center(
            child: SizedBox(
              key: vm.oppHandKey,
              height: rowHeight,
              width: double.infinity,
              child: Offstage(
                offstage: vm.motion.isShuffling,
                child: LayoutBuilder(
                builder: (context, constraints) {
                  if (cards.isEmpty) return const SizedBox.shrink();
                  final count = cards.length;
                  final scale = HandFanLayout.visualScale(
                    celebrating: celebrating,
                    highlightTurn: highlightTurn,
                  );
                  final layout = HandFanLayout.fitOpponentTop(
                    count: count,
                    maxWidth: constraints.maxWidth,
                    cardWidth: cardWidth,
                    visualScale: scale,
                    celebrating: celebrating,
                  );
                  final gap = layout.gap;
                  final fanCardWidth = layout.cardWidth;
                  final totalWidth = layout.totalWidth(count);
                  return Center(
                    child: SizedBox(
                      width: totalWidth,
                      height: rowHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (int i = 0; i < count; i++)
                            AnimatedPositioned(
                              key: ValueKey(cards[i].id),
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              left: i * gap,
                              top: (rowHeight - fanCardWidth * 1.4) / 2,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 180),
                                scale: scale,
                                child: WinningHandWave(
                                  active: celebrating,
                                  index: i,
                                  amplitude: 3.5,
                                  child: FlightAwareCard(
                                  key: vm.keyForCard(
                                    cards[i].id,
                                    CardSlot.oppHand,
                                  ),
                                  motion: vm.motion,
                                  cardId: cards[i].id,
                                  width: fanCardWidth,
                                  child:
                                      vm.gameState.round.roundStatus ==
                                          RoundStatus.completed
                                      ? PlayingCard(
                                          playingCardModel: cards[i],
                                          isSelected: celebrating,
                                          width: fanCardWidth,
                                        )
                                      : PlayingCardBack(width: fanCardWidth),
                                ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OpponentScoreChip(
                    oppId: oppId,
                    avatarKey: avatarKeyOverride,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentScoreChip extends StatelessWidget {
  const _OpponentScoreChip({
    required this.oppId,
    required this.avatarKey,
  });

  final String oppId;
  final GlobalKey? avatarKey;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final waiting = oppId.isEmpty;
    final info = waiting
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(vm.gameState.playersInfo[oppId] ?? {});
    final avatarId = info['avatarId'] as String?;
    final name = waiting
        ? AppLocalizations.of(context).openSeat
        : ((info['name'] as String?) ?? 'Rival');
    final score = waiting ? 0 : (vm.gameState.scores[oppId] ?? 0);
    final incoming = !waiting && vm.incomingReaction?.fromPid == oppId
        ? vm.incomingReaction
        : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PlayerScoreAvatar(
          key: waiting ? null : (avatarKey ?? vm.oppScoreKey),
          avatarId: avatarId,
          name: name,
          score: score,
          pendingCoins: waiting ? 0 : vm.revealedPendingFor(oppId),
          isTurn: !waiting && vm.isSeatTurn(oppId),
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
          right: 68,
          top: 8,
          child: IgnorePointer(
            child: ReactionBubblePopup(
              emoji: incoming?.emoji,
              reactionId: incoming?.id,
              tail: ReactionBubbleTail.right,
            ),
          ),
        ),
      ],
    );
  }
}
