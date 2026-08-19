import 'package:dominican_casino/game_control/game_engine/rummy/rummy_matcher.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/ui/general_game/hand_fan_layout.dart';
import 'package:dominican_casino/ui/general_game/widgets/table_play_drop_zone.dart';
import 'package:dominican_casino/ui/widgets/take_hint_bounce.dart';
import 'package:dominican_casino/ui/widgets/player_score_avatar.dart';
import 'package:dominican_casino/ui/widgets/winning_hand_wave.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:dominican_casino/view_models/games/rummy_box_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Rummy (Romir) board: draw/discard in the center + two dotted requirement
/// boxes at the top where the current player groups their 7 cards.
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
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    // Reserve space for the top opponent row.
                    top: 104,
                    left: leftOpp != null ? sideInset : 0,
                    right: rightOpp != null ? sideInset : 0,
                  ),
                  child: _buildTable(vm, shuffling),
                ),
              ),
              if (topOpp != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _RummyTopOpponentRow(
                    oppId: topOpp,
                  ),
                ),
              if (rightOpp != null)
                Positioned(
                  right: 8,
                  top: 104,
                  bottom: 0,
                  child: Center(
                    child: _RummySideSeat(
                      oppId: rightOpp,
                      align: Alignment.centerRight,
                    ),
                  ),
                ),
              if (leftOpp != null)
                Positioned(
                  left: 8,
                  top: 104,
                  bottom: 0,
                  child: Center(
                    child: _RummySideSeat(
                      oppId: leftOpp,
                      align: Alignment.centerLeft,
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
    // TablePlayDropZone uses StackFit.expand and needs bounded height.
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: TablePlayDropZone(
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Opacity(
            opacity: shuffling ? 0 : 1,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _requirementBox(vm, boxIndex: 0),
                  const SizedBox(width: 14),
                  _requirementBox(vm, boxIndex: 1),
                ],
              ),
            ),
          ),
        ),
      ],
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
    final cards = boxedIds.map((id) => byId[id]).whereType<PlayingCardModel>().toList();

    final label = requirement?.label ?? (boxIndex == 0 ? 'Box A' : 'Box B');
    final boxKey = boxIndex == 0 ? vm.rummyBoxAKey : vm.rummyBoxBKey;
    final satisfied = requirement != null &&
        RummyMatcher.matchesRequirement(requirement: requirement, cards: cards);

    const boxWidth = 180.0;
    const boxHeight = 148.0;

    final count = cards.length;
    final layout = RummyBoxLayout.forCount(count);
    final cardW = layout.cardWidth;
    final gap = layout.gap;
    final totalW = layout.totalWidthFor(count);
    final cardH = layout.cardHeight;

    final interactive = vm.canPlayTurn && !vm.hasDropPending;
    final rummyEnabled = interactive && vm.gameState.gameStatus == GameStatus.inProgress;
    final celebrating = vm.isCelebratingHand(vm.me);
    final draggingId = vm.draggingSource?.id;

    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: Container(
        key: boxKey,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: AppStyle.theme.dottedBox(
          color: AppStyle.theme.suitBlack,
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Center(
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
                            rummyEnabled: rummyEnabled,
                            celebrating: celebrating,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xF5F3ECE2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          satisfied
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          size: 12,
                          color: satisfied
                              ? const Color(0xFF2E8B57)
                              : AppStyle.theme.suitBlack.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            style: AppStyle.theme.caption.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
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
      ),
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
    required bool rummyEnabled,
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
        enabled: rummyEnabled && !vm.isAnimating,
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
      alignment: Alignment.center,
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
                : Matrix4.translationValues(0, 4, 0),
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

    final selected = currentCard != null && vm.selectedCards.contains(currentCard);
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
              transform: selected ? Matrix4.translationValues(0, -12, 0) : Matrix4.translationValues(0, 4, 0),
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

  static const double rowHeight = 104;
  static const double cardWidth = 54;
  static const double winGroupCardWidth = 44;

  final String oppId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (oppId.isEmpty && !vm.showOpenSeats) return const SizedBox.shrink();

    final waiting = oppId.isEmpty;
    final celebrating = !waiting && vm.isCelebratingHand(oppId);
    final showWinLayout = celebrating;

    final info = waiting
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(vm.gameState.playersInfo[oppId] ?? {});
    final avatarId = info['avatarId'] as String?;
    final name = waiting ? null : (info['name'] as String?) ?? 'Rival';
    final score = waiting ? 0 : (vm.gameState.scores[oppId] ?? 0) as int;
    final pendingCoins = waiting ? 0 : vm.revealedPendingFor(oppId);
    final highlightTurn = !waiting && vm.isSeatTurn(oppId);

    final cards = vm.gameState.hands[oppId] ?? const <PlayingCardModel>[];

    final rummy = vm.gameState.rummyState;
    List<PlayingCardModel> group(int idx) {
      if (!showWinLayout || rummy == null) return const [];
      final ids = idx == 0 ? rummy.boxAByPid[oppId] : rummy.boxBByPid[oppId];
      if (ids == null) return const [];
      final byId = {for (final c in cards) c.id: c};
      return ids.map((id) => byId[id]).whereType<PlayingCardModel>().toList();
    }

    final groupA = group(0);
    final groupB = group(1);

    return SizedBox(
      height: rowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Avatar + score.
          Positioned(
            top: 0,
            left: 0,
            child: PlayerScoreAvatar(
              key: waiting ? null : vm.celebrationAvatarKeyForPid(oppId),
              avatarId: avatarId,
              name: name,
              score: score,
              pendingCoins: pendingCoins,
              size: 48,
              isTurn: highlightTurn,
              isOpen: waiting,
              turnDeadline: waiting ? null : vm.turnDeadlineFor(oppId),
              turnTotal: vm.turnTotal,
            ),
          ),

          // Opponent hand — FlightAwareCard keys so deal/take/discard animate.
          if (!showWinLayout)
            Center(
              child: SizedBox(
                key: vm.oppHandKey,
                height: rowHeight,
                width: double.infinity,
                child: Offstage(
                  offstage: vm.motion.isShuffling,
                  child: cards.isEmpty
                      ? const SizedBox.shrink()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final count = cards.length;
                            final layout = HandFanLayout.fit(
                              count: count,
                              maxWidth: constraints.maxWidth,
                              preferredCardWidth: cardWidth,
                              minGap: 12.0,
                              maxGap: 34.0,
                              minCardWidth: 36.0,
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
                                        duration:
                                            const Duration(milliseconds: 280),
                                        curve: Curves.easeOutCubic,
                                        left: i * gap,
                                        top: (rowHeight - fanCardWidth * 1.4) /
                                            2,
                                        child: FlightAwareCard(
                                          key: vm.keyForCard(
                                            cards[i].id,
                                            CardSlot.oppHand,
                                          ),
                                          motion: vm.motion,
                                          cardId: cards[i].id,
                                          width: fanCardWidth,
                                          child: PlayingCardBack(
                                            width: fanCardWidth,
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
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final groupMaxW = (constraints.maxWidth - 10) / 2;
                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GroupFan(
                        cards: groupA,
                        width: winGroupCardWidth,
                        celebrating: true,
                        maxWidth: groupMaxW,
                      ),
                      const SizedBox(width: 10),
                      _GroupFan(
                        cards: groupB,
                        width: winGroupCardWidth,
                        celebrating: true,
                        maxWidth: groupMaxW,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _GroupFan extends StatelessWidget {
  const _GroupFan({
    required this.cards,
    required this.width,
    this.celebrating = false,
    this.maxWidth,
  });

  final List<PlayingCardModel> cards;
  final double width;
  final bool celebrating;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final scale = HandFanLayout.visualScale(celebrating: celebrating);
    final layout = HandFanLayout.fit(
      count: cards.length,
      maxWidth: maxWidth ?? width + (cards.length - 1) * 18,
      preferredCardWidth: width,
      minGap: 8.0,
      maxGap: 18.0,
      minCardWidth: width * 0.7,
      visualScale: scale,
    );
    final gap = layout.gap;
    final fanWidth = layout.cardWidth;
    final cardH = layout.cardHeight;
    final totalW = layout.totalWidth(cards.length);
    return SizedBox(
      width: totalW,
      height: cardH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < cards.length; i++)
            Positioned(
              left: i * gap,
              top: 0,
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: WinningHandWave(
                  active: celebrating,
                  index: i,
                  amplitude: 3,
                  child: PlayingCard(
                    playingCardModel: cards[i],
                    width: fanWidth,
                    isSelected: celebrating,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RummySideSeat extends StatelessWidget {
  const _RummySideSeat({required this.oppId, required this.align});

  final String oppId;
  final Alignment align;

  static const double sideCardWidth = 30;
  static const double sideOverlap = 8;
  static const double winCardWidth = 50;
  static const double maxHandWidth = 120;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (oppId.isEmpty && !vm.showOpenSeats) {
      return const SizedBox.shrink();
    }

    final waiting = oppId.isEmpty;
    final celebrating = !waiting && vm.isCelebratingHand(oppId);
    final showWinLayout = celebrating;

    final info = waiting
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(vm.gameState.playersInfo[oppId] ?? {});
    final avatarId = info['avatarId'] as String?;
    final name = waiting ? null : (info['name'] as String?) ?? 'Rival';
    final score = waiting ? 0 : (vm.gameState.scores[oppId] ?? 0) as int;
    final pendingCoins = waiting ? 0 : vm.revealedPendingFor(oppId);
    final highlightTurn = !waiting && vm.isSeatTurn(oppId);

    final cards = vm.gameState.hands[oppId] ?? const <PlayingCardModel>[];
    final rummy = vm.gameState.rummyState;

    List<PlayingCardModel> groupA() {
      if (!showWinLayout || rummy == null) return const [];
      final ids = rummy.boxAByPid[oppId] ?? const [];
      final byId = {for (final c in cards) c.id: c};
      return ids.map((id) => byId[id]).whereType<PlayingCardModel>().toList();
    }

    List<PlayingCardModel> groupB() {
      if (!showWinLayout || rummy == null) return const [];
      final ids = rummy.boxBByPid[oppId] ?? const [];
      final byId = {for (final c in cards) c.id: c};
      return ids.map((id) => byId[id]).whereType<PlayingCardModel>().toList();
    }

    final gA = groupA();
    final gB = groupB();

    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerScoreAvatar(
            key: waiting ? null : vm.celebrationAvatarKeyForPid(oppId),
            avatarId: avatarId,
            name: name,
            score: score,
            pendingCoins: pendingCoins,
            size: 48,
            isTurn: highlightTurn,
            isOpen: waiting,
            turnDeadline: waiting ? null : vm.turnDeadlineFor(oppId),
            turnTotal: vm.turnTotal,
          ),
          if (!waiting) const SizedBox(height: 8),
          if (showWinLayout)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: _GroupFan(
                    cards: gA,
                    width: winCardWidth,
                    celebrating: true,
                    maxWidth: maxHandWidth,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: _GroupFan(
                    cards: gB,
                    width: winCardWidth,
                    celebrating: true,
                    maxWidth: maxHandWidth,
                  ),
                ),
              ],
            )
          else
            if (cards.isNotEmpty)
              Offstage(
                offstage: vm.motion.isShuffling,
                child: SizedBox(
                  width: maxHandWidth,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final layout = HandFanLayout.fit(
                        count: cards.length,
                        maxWidth: constraints.maxWidth,
                        preferredCardWidth: sideCardWidth,
                        minGap: 4.0,
                        maxGap: sideOverlap,
                        minCardWidth: 24.0,
                      );
                      final gap = layout.gap;
                      final fanCardWidth = layout.cardWidth;
                      final fanW = layout.totalWidth(cards.length);
                      final handH = layout.cardHeight;
                      return Center(
                        child: SizedBox(
                          width: fanW,
                          height: handH,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (int i = 0; i < cards.length; i++)
                                AnimatedPositioned(
                                  key: ValueKey(cards[i].id),
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  left: i * gap,
                                  top: 0,
                                  child: FlightAwareCard(
                                    key: vm.keyForCard(
                                      cards[i].id,
                                      CardSlot.oppHand,
                                    ),
                                    motion: vm.motion,
                                    cardId: cards[i].id,
                                    width: fanCardWidth,
                                    child: PlayingCardBack(width: fanCardWidth),
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
        ],
      ),
    );
  }
}

