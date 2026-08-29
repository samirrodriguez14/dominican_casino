import 'package:dominican_casino/game_control/game_engine/bs/bs_seat_layout.dart';
import 'package:dominican_casino/game_control/game_engine/bs/bs_state.dart';
import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/ui/general_game/game_status_sheet.dart';
import 'package:dominican_casino/ui/general_game/widgets/table_play_drop_zone.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/ui/widgets/player_score_avatar.dart';
import 'package:dominican_casino/ui/widgets/reaction_bubble.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// BS board: compact opponent stacks (avatar + count), center claim pile.
///
/// Seats go clockwise from the local player (bottom): left-bottom → left-top →
/// top → right-top → right-bottom. That matches turn order after [me].
class BsPlayingArea extends StatelessWidget {
  const BsPlayingArea({super.key});

  static const double _cardWidth = 72;
  static const double _topPad = 128;
  static const double _sideInset = 96.0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final seats = BsSeatLayout.fromOppIds(
      vm.oppIds,
      showOpenSeats: vm.showOpenSeats,
    );

    return Opacity(
      opacity: vm.showInGameControl ? 0.5 : 1,
      child: ListenableBuilder(
        listenable: vm.motion,
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: _topPad,
                    left: seats.hasLeft ? _sideInset : 0,
                    right: seats.hasRight ? _sideInset : 0,
                  ),
                  child: _BsCenterPile(cardWidth: _cardWidth),
                ),
              ),
              if (seats.top != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _BsCompactOpponent(
                      oppId: seats.top!,
                      speechSide: _SpeechSide.below,
                    ),
                  ),
                ),
              if (seats.hasLeft)
                Positioned(
                  left: 8,
                  top: _topPad,
                  bottom: 0,
                  child: Center(
                    child: _BsSideColumn(
                      topId: seats.leftTop,
                      bottomId: seats.leftBottom,
                      speechSide: _SpeechSide.end,
                    ),
                  ),
                ),
              if (seats.hasRight)
                Positioned(
                  right: 8,
                  top: _topPad,
                  bottom: 0,
                  child: Center(
                    child: _BsSideColumn(
                      topId: seats.rightTop,
                      bottomId: seats.rightBottom,
                      speechSide: _SpeechSide.start,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

enum _SpeechSide { start, end, below }

/// Left/right column: [topId] nearer the top of the screen, [bottomId] nearer
/// the local hand. Clockwise play hits [bottomId] before [topId] on the left,
/// and [topId] before [bottomId] on the right.
class _BsSideColumn extends StatelessWidget {
  const _BsSideColumn({
    required this.speechSide,
    this.topId,
    this.bottomId,
  });

  final String? topId;
  final String? bottomId;
  final _SpeechSide speechSide;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topId != null) _BsCompactOpponent(oppId: topId!, speechSide: speechSide),
        if (topId != null && bottomId != null) const SizedBox(height: 14),
        if (bottomId != null)
          _BsCompactOpponent(oppId: bottomId!, speechSide: speechSide),
      ],
    );
  }
}

class _BsCompactOpponent extends StatelessWidget {
  const _BsCompactOpponent({
    required this.oppId,
    required this.speechSide,
  });

  final String oppId;
  final _SpeechSide speechSide;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (oppId.isEmpty && !vm.showOpenSeats) {
      return const SizedBox.shrink();
    }

    final waiting = oppId.isEmpty;
    final cards = waiting
        ? const <PlayingCardModel>[]
        : (vm.gameState.hands[oppId] ?? []);
    final seat = waiting ? const GameSeatLook() : vm.seatLook(oppId);
    final name = waiting
        ? AppLocalizations.of(context).openSeat
        : ((vm.gameState.playersInfo[oppId] is Map
                ? (vm.gameState.playersInfo[oppId] as Map)['name'] as String?
                : null) ??
            'Rival');
    final score = waiting ? 0 : (vm.gameState.scores[oppId] ?? 0);
    final incoming = !waiting && vm.incomingReaction?.fromPid == oppId
        ? vm.incomingReaction
        : null;
    final highlight = !waiting && vm.isSeatTurn(oppId);
    final speech = waiting ? null : vm.bsSpeechFor(oppId);

    final speechTail = switch (speechSide) {
      _SpeechSide.end => ReactionBubbleTail.left,
      _SpeechSide.start => ReactionBubbleTail.right,
      _SpeechSide.below => ReactionBubbleTail.top,
    };

    final avatar = PlayerScoreAvatar(
      key: waiting ? null : vm.celebrationAvatarKeyForPid(oppId),
      avatarId: seat.avatarId,
      avatarAsset: seat.avatarAsset,
      defeatedAces: seat.defeatedAces,
      wearJourneyAccessories: seat.wearJourneyAccessories,
      name: name,
      score: score,
      pendingCoins: waiting ? 0 : vm.revealedPendingFor(oppId),
      size: 48,
      isTurn: highlight,
      isOpen: waiting,
      turnDeadline: waiting ? null : vm.turnDeadlineFor(oppId),
      turnTotal: vm.turnTotal,
      onPressed: waiting
          ? null
          : () {
              AppHaptics.mediumImpact();
              showGameStatusPopup(context, vm: vm);
            },
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                avatar,
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
                if (speechSide == _SpeechSide.end)
                  Positioned(
                    left: 56,
                    top: 4,
                    child: IgnorePointer(
                      child: SpeechBubblePopup(
                        message: speech?.$1,
                        messageId: '${oppId}_${speech?.$1}',
                        tail: speechTail,
                        emphasized: speech?.$2 ?? false,
                      ),
                    ),
                  ),
                if (speechSide == _SpeechSide.start)
                  Positioned(
                    right: 56,
                    top: 4,
                    child: IgnorePointer(
                      child: SpeechBubblePopup(
                        message: speech?.$1,
                        messageId: '${oppId}_${speech?.$1}',
                        tail: speechTail,
                        emphasized: speech?.$2 ?? false,
                      ),
                    ),
                  ),
              ],
            ),
            if (!waiting) ...[
              const SizedBox(height: 6),
              _HandStackBadge(
                count: cards.length,
                cardWidth: 32,
                handKey: vm.oppHandKeyForPid(oppId),
                cardIds: cards.map((c) => c.id).toList(),
                vm: vm,
                revealFace:
                    vm.gameState.round.roundStatus == RoundStatus.completed,
                faceCards: cards,
              ),
            ],
          ],
        ),
        if (speechSide == _SpeechSide.below)
          Positioned(
            top: 52,
            child: IgnorePointer(
              child: SpeechBubblePopup(
                message: speech?.$1,
                messageId: '${oppId}_${speech?.$1}',
                tail: speechTail,
                emphasized: speech?.$2 ?? false,
              ),
            ),
          ),
      ],
    );
  }
}

class _HandStackBadge extends StatelessWidget {
  const _HandStackBadge({
    required this.count,
    required this.cardWidth,
    required this.handKey,
    required this.cardIds,
    required this.vm,
    required this.revealFace,
    required this.faceCards,
  });

  final int count;
  final double cardWidth;
  final GlobalKey handKey;
  final List<String> cardIds;
  final GeneralGameViewModel vm;
  final bool revealFace;
  final List<PlayingCardModel> faceCards;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    if (count <= 0) {
      return SizedBox(key: handKey, width: cardWidth, height: cardWidth * 1.4);
    }

    final topId = cardIds.isNotEmpty ? cardIds.last : 'stack';
    final topFace = faceCards.isNotEmpty ? faceCards.last : null;

    return SizedBox(
      key: handKey,
      width: cardWidth + 10,
      height: cardWidth * 1.4 + 4,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 2; i++)
            Positioned(
              left: i * 3.0,
              top: (2 - i) * 2.0,
              child: Opacity(
                opacity: 0.55,
                child: PlayingCardBack(width: cardWidth - 2),
              ),
            ),
          FlightAwareCard(
            key: vm.keyForCard(topId, CardSlot.oppHand),
            motion: vm.motion,
            cardId: topId,
            width: cardWidth,
            child: revealFace && topFace != null
                ? PlayingCard(
                    playingCardModel: topFace,
                    isSelected: false,
                    width: cardWidth,
                  )
                : PlayingCardBack(width: cardWidth),
          ),
          Positioned(
            right: -4,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.surface.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.border.withValues(alpha: .7)),
              ),
              child: Text(
                '$count',
                style: theme.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BsCenterPile extends StatelessWidget {
  const _BsCenterPile({required this.cardWidth});

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final pile = vm.gameState.playingArea;
    final bs = vm.gameState.bsState;
    final revealing = bs?.phase == BsPhase.resolve ||
        (bs?.wasBluffing != null && bs!.lastPlayedCardIds.isNotEmpty);
    final revealIds = bs?.lastPlayedCardIds.toSet() ?? {};

    return TablePlayDropZone(
      key: vm.tableKey,
      child: Center(
        child: pile.isEmpty
            ? SizedBox(
                width: cardWidth,
                height: cardWidth * 1.4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppStyle.theme.border.withValues(alpha: .35),
                    ),
                  ),
                ),
              )
            : SizedBox(
                width: cardWidth + 16,
                height: cardWidth * 1.4 + 12,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < pile.length; i++)
                      Transform.translate(
                        offset: Offset(
                          (i % 3) * 1.5,
                          (i % 4) * -1.2,
                        ),
                        child: FlightAwareCard(
                          key: vm.keyForCard(pile[i].id, CardSlot.table),
                          motion: vm.motion,
                          cardId: pile[i].id,
                          width: cardWidth,
                          child: revealing && revealIds.contains(pile[i].id)
                              ? PlayingCard(
                                  playingCardModel: pile[i],
                                  isSelected: true,
                                  width: cardWidth,
                                )
                              : PlayingCardBack(width: cardWidth),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      child: Text(
                        '${pile.length}',
                        style: AppStyle.theme.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
