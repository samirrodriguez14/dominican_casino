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
class BsPlayingArea extends StatelessWidget {
  const BsPlayingArea({super.key});

  static const double _cardWidth = 72;
  static const double _topRowHeight = 110;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final seats = _BsSeatMap.from(vm);

    return Opacity(
      opacity: vm.showInGameControl ? 0.5 : 1,
      child: ListenableBuilder(
        listenable: vm.motion,
        builder: (context, _) {
          const sideInset = 78.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: _topRowHeight,
                    left: seats.left != null ? sideInset : 0,
                    right: seats.right != null ? sideInset : 0,
                  ),
                  child: _BsCenterPile(cardWidth: _cardWidth),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _topRowHeight,
                child: _BsTopRow(
                  top: seats.top,
                  extra: seats.topExtras,
                ),
              ),
              if (seats.left != null)
                Positioned(
                  left: 8,
                  top: _topRowHeight,
                  bottom: 0,
                  child: Center(
                    child: _BsCompactOpponent(oppId: seats.left!),
                  ),
                ),
              if (seats.right != null)
                Positioned(
                  right: 8,
                  top: _topRowHeight,
                  bottom: 0,
                  child: Center(
                    child: _BsCompactOpponent(oppId: seats.right!),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                top: _topRowHeight + 8,
                child: const _BsClaimBanner(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BsSeatMap {
  const _BsSeatMap({
    this.left,
    this.top,
    this.right,
    this.topExtras = const [],
  });

  final String? left;
  final String? top;
  final String? right;
  /// 5th / 6th opponents — sit to the right of [top].
  final List<String> topExtras;

  factory _BsSeatMap.from(GeneralGameViewModel vm) {
    final opps = vm.oppIds;
    final n = opps.length;
    String? open() => vm.showOpenSeats ? '' : null;

    // Seat order: left, top, right, then top-extras (5th, 6th).
    if (n == 0) {
      return _BsSeatMap(
        left: open(),
        top: open(),
        right: open(),
      );
    }
    if (n == 1) {
      return _BsSeatMap(top: opps[0], left: open(), right: open());
    }
    if (n == 2) {
      return _BsSeatMap(
        left: opps[0],
        top: opps[1],
        right: open(),
      );
    }
    if (n == 3) {
      return _BsSeatMap(
        left: opps[0],
        top: opps[1],
        right: opps[2],
      );
    }
    if (n == 4) {
      return _BsSeatMap(
        left: opps[0],
        top: opps[1],
        right: opps[2],
        topExtras: [opps[3]],
      );
    }
    // 5 opponents (6 players total)
    return _BsSeatMap(
      left: opps[0],
      top: opps[1],
      right: opps[2],
      topExtras: opps.sublist(3),
    );
  }
}

class _BsTopRow extends StatelessWidget {
  const _BsTopRow({required this.top, required this.extra});

  final String? top;
  final List<String> extra;

  @override
  Widget build(BuildContext context) {
    final seats = <String>[
      ?top,
      ...extra,
    ];
    if (seats.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < seats.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              _BsCompactOpponent(oppId: seats[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _BsCompactOpponent extends StatelessWidget {
  const _BsCompactOpponent({required this.oppId});

  final String oppId;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
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
            ),
            Positioned(
              top: -28,
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
          const SizedBox(height: 6),
          _HandStackBadge(
            count: cards.length,
            cardWidth: 36,
            handKey: vm.oppHandKey,
            cardIds: cards.map((c) => c.id).toList(),
            vm: vm,
            revealFace: vm.gameState.round.roundStatus == RoundStatus.completed,
            faceCards: cards,
          ),
        ],
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
          // Depth shadows
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

class _BsClaimBanner extends StatelessWidget {
  const _BsClaimBanner();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final bs = vm.gameState.bsState;
    if (bs == null) return const SizedBox.shrink();

    final theme = AppStyle.theme;
    String? text;

    if (bs.phase == BsPhase.challenge &&
        bs.lastClaimPid != null &&
        bs.lastClaimRank != null) {
      final name = _nameFor(vm, bs.lastClaimPid!);
      text = '$name plays ${bs.lastClaimCount} ${bs.lastClaimRank}s';
    } else if (bs.wasBluffing != null && bs.challengerPid != null) {
      final claimer = _nameFor(vm, bs.lastClaimPid ?? '');
      text = bs.wasBluffing!
          ? '$claimer was bluffing — they take the pile'
          : '$claimer was honest — challenger takes the pile';
    }

    if (text == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border.withValues(alpha: .65)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.turnHighlight,
            ),
          ),
        ),
      ),
    );
  }

  String _nameFor(GeneralGameViewModel vm, String pid) {
    if (pid.isEmpty) return 'Player';
    final info = vm.gameState.playersInfo[pid];
    if (info is Map && info['name'] is String) return info['name'] as String;
    return 'Player';
  }
}
