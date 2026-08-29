import 'package:dominican_casino/game_control/game_engine/rummy/rummy_matcher.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_state.dart';
import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/ui/general_game/game_status_sheet.dart';
import 'package:dominican_casino/ui/general_game/hand_fan_layout.dart';
import 'package:dominican_casino/ui/general_game/simple/simple_casino_playing_area.dart';
import 'package:dominican_casino/ui/general_game/widgets/table_play_drop_zone.dart';
import 'package:dominican_casino/ui/widgets/reaction_bubble.dart';
import 'package:dominican_casino/ui/widgets/take_hint_bounce.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/ui/widgets/player_score_avatar.dart';
import 'package:dominican_casino/ui/widgets/popup_circle_button.dart';
import 'package:dominican_casino/ui/widgets/winning_hand_wave.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:dominican_casino/view_models/games/rummy_box_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Rummy (Romir) board: opponent seats, draw/discard, and two requirement boxes.
class RummyPlayingArea extends StatefulWidget {
  const RummyPlayingArea({super.key});

  @override
  State<RummyPlayingArea> createState() => _RummyPlayingAreaState();
}

enum _TableSeat { left, top, right }

class _RummyPlayingAreaState extends State<RummyPlayingArea> {
  static const double _tableCardWidth = 72;

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
          const boxStripHeight = RummyBoxLayout.stripHeight;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: SimpleOpponentRow.height,
                    left: leftOpp != null ? sideInset : 0,
                    right: rightOpp != null ? sideInset : 0,
                    bottom: boxStripHeight,
                  ),
                  child: _buildTable(vm, shuffling),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: boxStripHeight,
                child: Opacity(
                  opacity: shuffling ? 0 : 1,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _boxDropSlot(vm, boxIndex: 0),
                          _boxDropSlot(vm, boxIndex: 1),
                        ],
                      ),
                      if (vm.hasRummyBoxedCards) _returnBoxesButton(vm),
                    ],
                  ),
                ),
              ),
              if (topOpp != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _RummyTopOpponentRow(oppId: topOpp),
                ),
              if (rightOpp != null)
                Positioned(
                  right: 8,
                  top: SimpleOpponentRow.height,
                  bottom: boxStripHeight,
                  child: Center(
                    child: _RummySideSeat(
                      oppId: rightOpp,
                      overlayAlign: Alignment.centerRight,
                    ),
                  ),
                ),
              if (leftOpp != null)
                Positioned(
                  left: 8,
                  top: SimpleOpponentRow.height,
                  bottom: boxStripHeight,
                  child: Center(
                    child: _RummySideSeat(
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

  Widget _buildTable(GeneralGameViewModel vm, bool shuffling) {
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

  Widget _requirementBox(GeneralGameViewModel vm, {required int boxIndex}) {
    final rummy = vm.gameState.rummyState;
    final contract = rummy?.contract;

    final requirement = contract == null || contract.requirements.length < 2
        ? null
        : contract.requirements[boxIndex];

    final pid = vm.me;
    final boxedIds = boxIndex == 0
        ? (rummy?.boxAByPid[pid] ?? const <String>[])
        : (rummy?.boxBByPid[pid] ?? const <String>[]);
    final hand = vm.gameState.hands[pid] ?? const <PlayingCardModel>[];
    final byId = {for (final c in hand) c.id: c};
    final cards = boxedIds
        .map((id) => byId[id])
        .whereType<PlayingCardModel>()
        .toList();

    final label = requirement?.label ?? (boxIndex == 0 ? 'Box A' : 'Box B');
    final satisfied =
        requirement != null &&
        RummyMatcher.matchesRequirement(requirement: requirement, cards: cards);

    const boxWidth = RummyBoxLayout.boxWidth;
    const boxHeight = RummyBoxLayout.boxHeight;

    final count = cards.length;
    final layout = RummyBoxLayout.forCount(count);
    final cardW = layout.cardWidth;
    final gap = layout.gap;
    final totalW = layout.totalWidthFor(count);
    final cardH = layout.cardHeight;

    final rummyOrganizeEnabled = vm.canOrganizeRummy;
    final celebrating = vm.isCelebratingHand(vm.me);
    final draggingId = vm.draggingSource?.id;
    const labelColor = Color(0xFF1A1612);
    const labelColorSatisfied = Color(0xFF1B5E3B);

    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: AppStyle.theme.dottedBox(
        color: AppStyle.theme.suitBlack,
        padding: const EdgeInsets.all(RummyBoxLayout.borderPad),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  width: totalW,
                  height: cardH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (int i = 0; i < count; i++)
                        _boxFanCard(
                          vm: vm,
                          card: cards[i],
                          index: i,
                          gap: gap,
                          totalW: totalW,
                          cardW: cardW,
                          cardH: cardH,
                          boxIndex: boxIndex,
                          draggingId: draggingId,
                          rummyOrganizeEnabled: rummyOrganizeEnabled,
                          celebrating: celebrating,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              right: 4,
              bottom: 2,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xF2EDE6DC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppStyle.theme.suitBlack.withValues(alpha: 0.14),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        satisfied
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        size: 14,
                        color: satisfied
                            ? const Color(0xFF2E8B57)
                            : AppStyle.theme.suitBlack.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          style: AppStyle.theme.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: satisfied ? labelColorSatisfied : labelColor,
                            letterSpacing: 0.15,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boxDropSlot(GeneralGameViewModel vm, {required int boxIndex}) {
    final boxKey = boxIndex == 0 ? vm.rummyBoxAKey : vm.rummyBoxBKey;
    return Expanded(
      child: KeyedSubtree(
        key: boxKey,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _requirementBox(vm, boxIndex: boxIndex),
          ),
        ),
      ),
    );
  }

  Widget _returnBoxesButton(GeneralGameViewModel vm) {
    return PopupCircleButton(
      size: 36,
      emphasized: true,
      icon: CupertinoIcons.arrow_down,
      onPressed: () {
        AppHaptics.selectionClick();
        vm.returnAllRummyBoxesToHand();
      },
    );
  }

  Widget _boxFanCard({
    required GeneralGameViewModel vm,
    required PlayingCardModel card,
    required int index,
    required double gap,
    required double totalW,
    required double cardW,
    required double cardH,
    required int boxIndex,
    required String? draggingId,
    required bool rummyOrganizeEnabled,
    required bool celebrating,
  }) {
    return AnimatedPositioned(
      key: ValueKey(card.id),
      duration: draggingId == card.id
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: index * gap,
      top: 0,
      child: BoardDragHandle(
        source: BoardDragSource.hand(card),
        enabled: rummyOrganizeEnabled && !vm.isAnimating,
        feedbackWidth: cardW,
        tableFeedbackWidth: GeneralGameViewModel.rummyHandCardWidth,
        onTap: () {},
        onHandReorder: (global) {
          final target = vm.hitTestDropTarget(
            global,
            source: BoardDragSource.hand(card),
          );
          if (target != null) {
            final leavingBox = switch (target.kind) {
              DropTargetKind.rummyBoxA => boxIndex != 0,
              DropTargetKind.rummyBoxB => boxIndex != 1,
              _ => true,
            };
            if (leavingBox) return;
          }
          final id = vm.draggingSource?.id;
          if (id == null) return;
          final rummy = vm.gameState.rummyState;
          if (rummy == null) return;
          final pid = vm.me;
          final list = boxIndex == 0
              ? rummy.boxAByPid[pid]
              : rummy.boxBByPid[pid];
          if (list == null || !list.contains(id)) return;
          final from = list.indexOf(id);
          if (from < 0) return;
          final to = _indexForBoxGlobalCenter(
            global,
            list.length,
            gap,
            totalW,
            boxIndex == 0 ? vm.rummyBoxAKey : vm.rummyBoxBKey,
          );
          if (to != from) vm.moveRummyBoxCardTo(boxIndex, from, to);
        },
        child: Opacity(
          opacity: vm.isDragHidden(card.id) ? 0 : 1,
          child: AnimatedScale(
            scale: celebrating ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: draggingId == card.id
                  ? Duration.zero
                  : const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              width: cardW,
              height: cardH,
              child: WinningHandWave(
                active: celebrating,
                index: index,
                amplitude: 3,
                child: FlightAwareCard(
                  key: vm.keyForCard(card.id, CardSlot.rummyBox),
                  motion: vm.motion,
                  cardId: card.id,
                  width: cardW,
                  child: PlayingCard(
                    playingCardModel: card,
                    width: cardW,
                    isSelected: celebrating,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _indexForBoxGlobalCenter(
    Offset globalCenter,
    int count,
    double gap,
    double totalW,
    GlobalKey boxKey,
  ) {
    if (count <= 0 || gap <= 0) return 0;
    final box = boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 0;
    final local = box.globalToLocal(globalCenter);
    final stackLeft = (box.size.width - totalW) / 2;
    final stackLocalX = local.dx - stackLeft;
    return (stackLocalX / gap).round().clamp(0, count - 1);
  }

  Widget _drawPile(GeneralGameViewModel vm) {
    final deckCard = vm.gameState.deck.isNotEmpty
        ? vm.gameState.deck.last
        : null;
    if (deckCard == null) return const SizedBox.shrink();

    final selected = vm.selectedCards.contains(deckCard);
    final hidden = vm.isDragHidden(deckCard.id);

    final pile = Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        IgnorePointer(
          child: CardDeck(
            key: vm.deckKey,
            title: '',
            showLabel: false,
            cardWidth: _tableCardWidth,
            cards: vm.gameState.deck,
            extraPoints: 0,
            onTap: () {},
          ),
        ),
        TakeHintBounce(
          active: vm.needsTakeHint,
          slot: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: selected
                ? Matrix4.translationValues(0, -12, 0)
                : Matrix4.translationValues(0, 0, 0),
            child: Opacity(
              opacity: hidden ? 0 : 1,
              child: FlightAwareCard(
                key: vm.keyForCard(deckCard.id, CardSlot.aux),
                motion: vm.motion,
                cardId: deckCard.id,
                width: _tableCardWidth,
                child: AnimatedScale(
                  scale: selected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: PlayingCardBack(width: _tableCardWidth),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return BoardDragHandle(
      source: BoardDragSource.deck(deckCard),
      enabled: vm.canPlayTurn && !vm.hasDropPending,
      feedbackWidth: _tableCardWidth,
      tableFeedbackWidth: _tableCardWidth,
      onTap: () => vm.selectCardToTake(deckCard),
      child: pile,
    );
  }

  Widget _discardPile(GeneralGameViewModel vm) {
    final currentCard = vm.playingAreaCards.isNotEmpty
        ? vm.playingAreaCards.last
        : null;
    final buried = vm.gameState.playingArea.length > 1
        ? vm.gameState.playingArea.sublist(
            0,
            vm.gameState.playingArea.length - 1,
          )
        : const <PlayingCardModel>[];

    final selected =
        currentCard != null && vm.selectedCards.contains(currentCard);
    final hidden = currentCard != null && vm.isDragHidden(currentCard.id);

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
            cardWidth: _tableCardWidth,
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
              transform: selected
                  ? Matrix4.translationValues(0, -12, 0)
                  : Matrix4.translationValues(0, -4, 0),
              child: Opacity(
                opacity: hidden ? 0 : 1,
                child: FlightAwareCard(
                  key: vm.keyForCard(currentCard.id, CardSlot.table),
                  motion: vm.motion,
                  cardId: currentCard.id,
                  width: _tableCardWidth,
                  child: PlayingCard(
                    playingCardModel: currentCard,
                    isSelected: selected,
                    width: _tableCardWidth,
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
      feedbackWidth: _tableCardWidth,
      tableFeedbackWidth: _tableCardWidth,
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

class _RummyTopOpponentRow extends StatelessWidget {
  const _RummyTopOpponentRow({required this.oppId});

  static const double cardWidth = SimpleOpponentRow.cardWidth;
  static const double winGroupCardWidth = 44;

  final String oppId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (oppId.isEmpty && !vm.showOpenSeats) return const SizedBox.shrink();

    final waiting = oppId.isEmpty;
    final celebrating = !waiting && vm.isCelebratingHand(oppId);
    final cards = waiting
        ? const <PlayingCardModel>[]
        : (vm.gameState.hands[oppId] ?? const <PlayingCardModel>[]);
    final groups = celebrating
        ? _rummyWinGroups(
            cards: cards,
            rummy: vm.gameState.rummyState,
            pid: oppId,
          )
        : (const <PlayingCardModel>[], const <PlayingCardModel>[]);

    const rowHeight = SimpleOpponentRow.height;
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
                    return Center(
                      key: oppId.isEmpty
                          ? null
                          : vm.oppHandKeyForPid(oppId),
                      child: _RummyOpponentFan(
                        cards: cards,
                        groupA: groups.$1,
                        groupB: groups.$2,
                        celebrating: celebrating,
                        highlightTurn: !waiting && vm.isSeatTurn(oppId),
                        maxWidth: constraints.maxWidth,
                        preferredCardWidth: cardWidth,
                        winCardWidth: winGroupCardWidth,
                        minGap: 16.0,
                        maxGap: 34.0,
                        winMinGap: 8.0,
                        winMaxGap: 18.0,
                        minCardWidth: 40.0,
                        rowHeight: rowHeight,
                        waveAmplitude: 3.5,
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
              child: _RummyOpponentAvatar(
                oppId: oppId,
                reactionTail: ReactionBubbleTail.right,
                reactionOffset: const Offset(-68, 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RummySideSeat extends StatelessWidget {
  const _RummySideSeat({required this.oppId, required this.overlayAlign});

  static const double cardWidth = 30;
  static const double overlap = 8;
  static const double avatarSize = 48;
  static const double winCardWidth = 50;
  static const double winOverlap = 18;
  static const double maxHandWidth = 120;

  final String oppId;
  final Alignment overlayAlign;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (oppId.isEmpty && !vm.showOpenSeats) {
      return const SizedBox.shrink();
    }

    final waiting = oppId.isEmpty;
    final celebrating = !waiting && vm.isCelebratingHand(oppId);
    final cards = waiting
        ? const <PlayingCardModel>[]
        : (vm.gameState.hands[oppId] ?? const <PlayingCardModel>[]);
    final groups = celebrating
        ? _rummyWinGroups(
            cards: cards,
            rummy: vm.gameState.rummyState,
            pid: oppId,
          )
        : (const <PlayingCardModel>[], const <PlayingCardModel>[]);
    const layoutH = cardWidth * 1.4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RummyOpponentAvatar(
          oppId: oppId,
          size: avatarSize,
          reactionTail: ReactionBubbleTail.bottom,
          reactionOffset: const Offset(0, -36),
        ),
        if (!waiting) ...[
          const SizedBox(height: 8),
          Offstage(
            offstage: vm.motion.isShuffling,
            child: SizedBox(
              key: vm.oppHandKeyForPid(oppId),
              width: maxHandWidth,
              height: layoutH,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (cards.isEmpty) return const SizedBox.shrink();
                  return _RummyOpponentFan(
                    cards: cards,
                    groupA: groups.$1,
                    groupB: groups.$2,
                    celebrating: celebrating,
                    highlightTurn: !waiting && vm.isSeatTurn(oppId),
                    maxWidth: constraints.maxWidth,
                    preferredCardWidth: cardWidth,
                    winCardWidth: winCardWidth,
                    minGap: 4.0,
                    maxGap: overlap,
                    winMinGap: 10.0,
                    winMaxGap: winOverlap,
                    minCardWidth: 24.0,
                    overflowAlign: overlayAlign,
                    waveAmplitude: 3,
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RummyOpponentAvatar extends StatelessWidget {
  const _RummyOpponentAvatar({
    required this.oppId,
    required this.reactionTail,
    required this.reactionOffset,
    this.size,
  });

  final String oppId;
  final ReactionBubbleTail reactionTail;
  final Offset reactionOffset;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final waiting = oppId.isEmpty;
    final invited = !waiting && vm.isPendingInviteSeat(oppId);
    final seat = waiting ? const GameSeatLook() : vm.seatLook(oppId);
    final l10n = AppLocalizations.of(context);
    final name = vm.opponentDisplayName(
      oppId,
      openLabel: l10n.openSeat,
      invitedFallback: l10n.invited,
    );
    final score = waiting || invited ? 0 : (vm.gameState.scores[oppId] ?? 0);
    final incoming = !waiting &&
            !invited &&
            vm.incomingReaction?.fromPid == oppId
        ? vm.incomingReaction
        : null;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        PlayerScoreAvatar(
          key: waiting ? null : vm.celebrationAvatarKeyForPid(oppId),
          avatarId: seat.avatarId,
          avatarAsset: seat.avatarAsset,
          defeatedAces: seat.defeatedAces,
          wearJourneyAccessories: seat.wearJourneyAccessories,
          name: name,
          score: score,
          pendingCoins: waiting ? 0 : vm.revealedPendingFor(oppId),
          size: size ?? 64,
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
          left: reactionOffset.dx > 0 ? reactionOffset.dx : null,
          right: reactionOffset.dx < 0 ? -reactionOffset.dx : null,
          top: reactionOffset.dy,
          child: IgnorePointer(
            child: ReactionBubblePopup(
              emoji: incoming?.emoji,
              reactionId: incoming?.id,
              tail: reactionTail,
            ),
          ),
        ),
      ],
    );
  }
}

/// Positions cards in one fan, then animates into two contract groups on a win.
class _RummyOpponentFan extends StatelessWidget {
  const _RummyOpponentFan({
    required this.cards,
    required this.groupA,
    required this.groupB,
    required this.celebrating,
    this.highlightTurn = false,
    required this.maxWidth,
    required this.preferredCardWidth,
    required this.winCardWidth,
    required this.minGap,
    required this.maxGap,
    required this.winMinGap,
    required this.winMaxGap,
    required this.minCardWidth,
    required this.waveAmplitude,
    this.rowHeight,
    this.overflowAlign,
  });

  final List<PlayingCardModel> cards;
  final List<PlayingCardModel> groupA;
  final List<PlayingCardModel> groupB;
  final bool celebrating;
  final bool highlightTurn;
  final double maxWidth;
  final double preferredCardWidth;
  final double winCardWidth;
  final double minGap;
  final double maxGap;
  final double winMinGap;
  final double winMaxGap;
  final double minCardWidth;
  final double waveAmplitude;
  final double? rowHeight;
  final Alignment? overflowAlign;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final split = celebrating && groupA.isNotEmpty && groupB.isNotEmpty;
    final scale = HandFanLayout.visualScale(
      celebrating: celebrating,
      highlightTurn: highlightTurn,
    );
    final faceUp =
        celebrating || vm.gameState.round.roundStatus == RoundStatus.completed;
    final plan = split ? _splitPlan(scale) : _singlePlan(celebrating, scale);

    final fan = SizedBox(
      width: plan.width,
      height: plan.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < cards.length; i++)
            if (plan.slots[cards[i].id] != null)
              _fanCard(
                vm: vm,
                card: cards[i],
                index: i,
                slot: plan.slots[cards[i].id]!,
                scale: scale,
                faceUp: faceUp,
              ),
        ],
      ),
    );

    if (overflowAlign != null) {
      return OverflowBox(
        alignment: overflowAlign!,
        minWidth: plan.width,
        maxWidth: plan.width,
        minHeight: plan.height,
        maxHeight: plan.height,
        child: fan,
      );
    }
    return fan;
  }

  Widget _fanCard({
    required GeneralGameViewModel vm,
    required PlayingCardModel card,
    required int index,
    required _CardSlot slot,
    required double scale,
    required bool faceUp,
  }) {
    return AnimatedPositioned(
      key: ValueKey(card.id),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      left: slot.left,
      top: slot.top,
      width: slot.width,
      height: slot.height,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: scale,
        child: WinningHandWave(
          active: celebrating || highlightTurn,
          index: index,
          amplitude: highlightTurn && !celebrating ? 5 : waveAmplitude,
          glow: celebrating,
          pulse: highlightTurn && !celebrating,
          period: highlightTurn && !celebrating
              ? const Duration(milliseconds: 1600)
              : const Duration(milliseconds: 1200),
          child: FlightAwareCard(
            key: vm.keyForCard(card.id, CardSlot.oppHand),
            motion: vm.motion,
            cardId: card.id,
            width: slot.width,
            child: faceUp
                ? PlayingCard(
                    playingCardModel: card,
                    isSelected: celebrating,
                    width: slot.width,
                  )
                : PlayingCardBack(width: slot.width),
          ),
        ),
      ),
    );
  }

  _FanPlan _singlePlan(bool expanding, double scale) {
    final layout = expanding
        ? HandFanLayout.fit(
            count: cards.length,
            maxWidth: maxWidth,
            preferredCardWidth: winCardWidth,
            minGap: winMinGap,
            maxGap: winMaxGap,
            minCardWidth: minCardWidth,
            visualScale: scale,
            lockCardSize: true,
            progressiveTighten: true,
            tightenPerPair: HandFanLayout.opponentTopTightenPerPair,
            widthMargin: HandFanLayout.opponentTopWidthMargin,
          )
        : HandFanLayout.fitOpponentTop(
            count: cards.length,
            maxWidth: maxWidth,
            cardWidth: preferredCardWidth,
            visualScale: scale,
            celebrating: celebrating,
          );
    final height = rowHeight ?? layout.cardHeight;
    final slots = <String, _CardSlot>{};
    for (int i = 0; i < cards.length; i++) {
      slots[cards[i].id] = _CardSlot(
        left: i * layout.gap,
        top: (height - layout.cardHeight) / 2,
        width: layout.cardWidth,
      );
    }
    return _FanPlan(
      slots: slots,
      width: layout.totalWidth(cards.length),
      height: height,
    );
  }

  _FanPlan _splitPlan(double scale) {
    // Side seats overflow toward the table so groups can keep win sizing.
    final budget = overflowAlign != null ? 280.0 : maxWidth;
    final groupMaxW = (budget - 10).clamp(0.0, budget) / 2;
    final layoutA = HandFanLayout.fit(
      count: groupA.length,
      maxWidth: groupMaxW,
      preferredCardWidth: winCardWidth,
      minGap: winMinGap,
      maxGap: winMaxGap,
      minCardWidth: minCardWidth,
      visualScale: scale,
    );
    final layoutB = HandFanLayout.fit(
      count: groupB.length,
      maxWidth: groupMaxW,
      preferredCardWidth: winCardWidth,
      minGap: winMinGap,
      maxGap: winMaxGap,
      minCardWidth: minCardWidth,
      visualScale: scale,
    );
    final widthA = layoutA.totalWidth(groupA.length);
    final widthB = layoutB.totalWidth(groupB.length);
    final height =
        rowHeight ??
        (layoutA.cardHeight > layoutB.cardHeight
            ? layoutA.cardHeight
            : layoutB.cardHeight);
    final totalW = widthA + 10 + widthB;
    final slots = <String, _CardSlot>{};
    for (int i = 0; i < groupA.length; i++) {
      slots[groupA[i].id] = _CardSlot(
        left: i * layoutA.gap,
        top: (height - layoutA.cardHeight) / 2,
        width: layoutA.cardWidth,
      );
    }
    for (int i = 0; i < groupB.length; i++) {
      slots[groupB[i].id] = _CardSlot(
        left: widthA + 10 + i * layoutB.gap,
        top: (height - layoutB.cardHeight) / 2,
        width: layoutB.cardWidth,
      );
    }
    return _FanPlan(slots: slots, width: totalW, height: height);
  }
}

class _CardSlot {
  const _CardSlot({required this.left, required this.top, required this.width});

  final double left;
  final double top;
  final double width;

  double get height => width * 1.4;
}

class _FanPlan {
  const _FanPlan({
    required this.slots,
    required this.width,
    required this.height,
  });

  final Map<String, _CardSlot> slots;
  final double width;
  final double height;
}

(List<PlayingCardModel>, List<PlayingCardModel>) _rummyWinGroups({
  required List<PlayingCardModel> cards,
  required RummyState? rummy,
  required String pid,
}) {
  if (rummy == null || cards.isEmpty) {
    return (const [], const []);
  }
  final byId = {for (final c in cards) c.id: c};
  List<PlayingCardModel> from(Map<String, List<String>> map) {
    final ids = map[pid] ?? const [];
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  final groupA = from(rummy.boxAByPid);
  final groupB = from(rummy.boxBByPid);
  if (groupA.isNotEmpty || groupB.isNotEmpty) {
    final used = {...groupA.map((c) => c.id), ...groupB.map((c) => c.id)};
    final leftover = [
      for (final c in cards)
        if (!used.contains(c.id)) c,
    ];
    if (leftover.isEmpty) return (groupA, groupB);
    if (groupB.isEmpty) return (groupA, leftover);
    return (groupA, [...groupB, ...leftover]);
  }

  final reqs = rummy.contract.requirements;
  if (reqs.length >= 2) {
    final n = reqs[0].count.clamp(0, cards.length);
    return (cards.sublist(0, n), cards.sublist(n));
  }
  return (cards, const []);
}
