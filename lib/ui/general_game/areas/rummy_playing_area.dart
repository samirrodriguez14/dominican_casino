import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/ui/general_game/widgets/table_play_drop_zone.dart';
import 'package:dominican_casino/ui/widgets/take_hint_bounce.dart';
import 'package:dominican_casino/ui/widgets/player_score_avatar.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
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
    final key = boxIndex == 0 ? vm.rummyBoxAKey : vm.rummyBoxBKey;

    const boxWidth = 180.0;
    const boxHeight = 135.0;
    const paddingTop = 8.0;

    final count = cards.length;
    final cardW = _tableCardWidth;
    final gap = count <= 1 ? 0.0 : ((boxWidth - cardW) / (count - 1)).clamp(8.0, 28.0);
    final totalW = cardW + (count <= 1 ? 0 : (count - 1) * gap);
    // Box cards should be visually smaller to avoid clipping at the bottom.
    const boxCardHeightMultiplier = 1.25;
    final cardH = cardW * boxCardHeightMultiplier;

    final interactive = vm.canPlayTurn && !vm.hasDropPending;
    final rummyEnabled = interactive && vm.gameState.gameStatus == GameStatus.inProgress;

    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: Container(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: AppStyle.theme.dottedBox(
          color: AppStyle.theme.suitBlack,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppStyle.theme.caption.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: paddingTop),
              SizedBox(
                height: boxHeight - paddingTop - 25,
                child: Center(
                  child: SizedBox(
                    width: totalW,
                    height: cardH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (int i = 0; i < count; i++)
                          Positioned(
                            left: i * gap,
                            top: 0,
                            child: BoardDragHandle(
                              source: BoardDragSource.hand(cards[i]),
                              enabled: rummyEnabled && !vm.isAnimating,
                              feedbackWidth: cardW,
                              tableFeedbackWidth: cardW,
                              onTap: () {},
                              onHandReorder: (global) {
                                final rummy = vm.gameState.rummyState;
                                if (rummy == null) return;
                                final draggingId = vm.draggingSource?.id;
                                if (draggingId == null) return;

                                final targetMap = boxIndex == 0
                                    ? rummy.boxAByPid
                                    : rummy.boxBByPid;
                                final list = targetMap[pid];
                                if (list == null || !list.contains(draggingId)) {
                                  return;
                                }

                                final renderBox = key.currentContext
                                    ?.findRenderObject() as RenderBox?;
                                if (renderBox == null || !renderBox.hasSize) {
                                  return;
                                }
                                final local = renderBox.globalToLocal(global);
                                if (local.dx < 0 ||
                                    local.dx > renderBox.size.width) {
                                  return;
                                }

                                final len = list.length;
                                if (len <= 1) return;

                                final rel = (local.dx / renderBox.size.width)
                                    .clamp(0.0, 0.9999);
                                final to = (rel * len).floor().clamp(0, len - 1);
                                final from = list.indexOf(draggingId);
                                if (from < 0 || from == to) return;

                                list.removeAt(from);
                                list.insert(to, draggingId);
                                vm.notifyListeners();
                              },
                              child: FlightAwareCard(
                                key: vm.keyForCard(cards[i].id, CardSlot.myHand),
                                motion: vm.motion,
                                cardId: cards[i].id,
                                width: cardW,
                                child: PlayingCard(
                                  playingCardModel: cards[i],
                                  width: cardW,
                                heightMultiplyer: boxCardHeightMultiplier,
                                  isSelected: false,
                                ),
                              ),
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

  final String oppId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (oppId.isEmpty && !vm.showOpenSeats) return const SizedBox.shrink();

    final winner = vm.gameState.gameStatus == GameStatus.gameOver
        ? vm.gameState.winnerId
        : null;
    final isWinner = winner != null && winner == oppId;

    final waiting = oppId.isEmpty;
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
      if (!isWinner || rummy == null) return const [];
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

          // Simple, compact card display.
          if (!isWinner)
            Center(
              child: SizedBox(
                width: cards.length <= 1
                    ? cardWidth
                    : cardWidth + ((cards.length - 1) * 18),
                height: rowHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int i = 0; i < cards.length; i++)
                      Positioned(
                        left: i * 18,
                        top: (rowHeight - cardWidth * 1.4) / 2,
                        child: PlayingCardBack(width: cardWidth),
                      ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Split the top-hand width into two side-by-side groups.
                  _GroupFan(cards: groupA, width: cardWidth / 2),
                  const SizedBox(width: 10),
                  _GroupFan(cards: groupB, width: cardWidth / 2),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupFan extends StatelessWidget {
  const _GroupFan({required this.cards, required this.width});

  final List<PlayingCardModel> cards;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    const overlap = 18.0;
    final cardH = width * 1.4;
    final totalW = width + (cards.length - 1) * overlap;
    return SizedBox(
      width: totalW,
      height: cardH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < cards.length; i++)
            Positioned(
              left: i * overlap,
              top: 0,
              child: PlayingCard(
                playingCardModel: cards[i],
                width: width,
                  isSelected: false,
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (oppId.isEmpty && !vm.showOpenSeats) {
      return const SizedBox.shrink();
    }

    final winner = vm.gameState.gameStatus == GameStatus.gameOver
        ? vm.gameState.winnerId
        : null;
    final isWinner = winner != null && winner == oppId;

    final waiting = oppId.isEmpty;
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
      if (!isWinner || rummy == null) return const [];
      final ids = rummy.boxAByPid[oppId] ?? const [];
      final byId = {for (final c in cards) c.id: c};
      return ids.map((id) => byId[id]).whereType<PlayingCardModel>().toList();
    }

    List<PlayingCardModel> groupB() {
      if (!isWinner || rummy == null) return const [];
      final ids = rummy.boxBByPid[oppId] ?? const [];
      final byId = {for (final c in cards) c.id: c};
      return ids.map((id) => byId[id]).whereType<PlayingCardModel>().toList();
    }

    final gA = groupA();
    final gB = groupB();

    final handH = sideCardWidth * 1.4;
    final fanW = cards.isEmpty
        ? sideCardWidth
        : sideCardWidth + ((cards.length - 1) * sideOverlap);

    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerScoreAvatar(
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
          if (isWinner)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: _GroupFan(cards: gA, width: sideCardWidth)),
                const SizedBox(height: 4),
                Center(child: _GroupFan(cards: gB, width: sideCardWidth)),
              ],
            )
          else
            if (cards.isNotEmpty)
              Center(
                child: SizedBox(
                  width: fanW,
                  height: handH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (int i = 0; i < cards.length; i++)
                        Positioned(
                          left: i * sideOverlap,
                          top: 0,
                          child: PlayingCardBack(width: sideCardWidth),
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

