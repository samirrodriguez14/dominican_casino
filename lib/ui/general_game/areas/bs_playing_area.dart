import 'dart:math' as math;

import 'package:dominican_casino/game_control/game_engine/bs/bs_seat_layout.dart';
import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
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
        if (topId != null && bottomId != null) const SizedBox(height: 44),
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
    final invited = !waiting && vm.isPendingInviteSeat(oppId);
    final cards = waiting || invited
        ? const <PlayingCardModel>[]
        : (vm.gameState.hands[oppId] ?? []);
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
    final highlight = !waiting && !invited && vm.isSeatTurn(oppId);
    final speech = waiting || invited ? null : vm.bsSpeechFor(oppId);

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
              Offstage(
                offstage: vm.motion.isShuffling,
                child: _TurnStackBounce(
                  active: highlight,
                  child: _HandStackBadge(
                    count: cards.length,
                    cardWidth: 32,
                    handKey: vm.oppHandKeyForPid(oppId),
                    cardIds: cards.map((c) => c.id).toList(),
                    vm: vm,
                    revealFace:
                        vm.gameState.round.roundStatus == RoundStatus.completed,
                    faceCards: cards,
                  ),
                ),
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

/// Occasional hop on the active seat's card stack (matches local hand pulse).
class _TurnStackBounce extends StatefulWidget {
  const _TurnStackBounce({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_TurnStackBounce> createState() => _TurnStackBounceState();
}

class _TurnStackBounceState extends State<_TurnStackBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  /// Must match [_TurnHaloState._periodMs] and hand pulse.
  static const _periodMs = 1600;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _periodMs),
    );
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant _TurnStackBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Main hop (softer), then a smaller settle bounce that ends at rest.
  double _softDoubleBounce(double local) {
    double arc(double x) {
      if (x <= 0 || x >= 1) return 0;
      return math.sin(x * math.pi);
    }

    if (local < 0.62) return arc(local / 0.62) * 0.7;
    return arc((local - 0.62) / 0.38) * 0.28;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Wall-clock phase locks to avatar halo pulse.
        final t =
            (DateTime.now().millisecondsSinceEpoch % _periodMs) / _periodMs;
        const bounceEnd = 0.5;
        final hop = t >= bounceEnd
            ? 0.0
            : _softDoubleBounce((t / bounceEnd).clamp(0.0, 1.0)) * 4.0;
        return Transform.translate(offset: Offset(0, -hop), child: child);
      },
      child: widget.child,
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
    final verdict = vm.bsRevealVerdict;
    final revealing = vm.bsClaimCardsRevealed;
    final gathering = vm.bsPileGathering;
    final showClaimFan = revealing || gathering;
    final shuffling = vm.motion.isShuffling;
    final readyToDeal =
        vm.gameState.round.roundStatus == RoundStatus.readyToDeal;
    // Shoe is only for the undealt deck after shuffle. During play we need
    // per-card [CardSlot.table] keys so hand → pile flights can land.
    final showShoe = !showClaimFan && readyToDeal && pile.isNotEmpty;

    final Widget body;
    if (showShoe && pile.isNotEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CardDeck(
              key: vm.deckKey,
              title: '',
              showLabel: false,
              cardWidth: cardWidth,
              cards: pile,
              extraPoints: 0,
              onTap: () {},
            ),
            const SizedBox(height: 4),
            Text(
              '${pile.length}',
              style: AppStyle.theme.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      final revealIds =
          vm.gameState.bsState?.lastPlayedCardIds.toSet() ?? const <String>{};
      final claimed = showClaimFan
          ? pile.where((c) => revealIds.contains(c.id)).toList()
          : const <PlayingCardModel>[];
      final older = showClaimFan
          ? pile.where((c) => !revealIds.contains(c.id)).toList()
          : pile;

      final revealWidth = cardWidth * 1.28;
      final claimCount = claimed.isEmpty ? 1 : claimed.length;
      final fanStep = revealWidth * 0.42;
      final revealSpan = revealWidth + (claimCount - 1) * fanStep;

      body = Center(
        child: pile.isEmpty
            ? SizedBox(
                key: vm.deckKey,
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
            : AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: showClaimFan && !gathering
                      ? revealSpan.clamp(cardWidth + 16, 280)
                      : cardWidth + 16,
                  height: showClaimFan && !gathering
                      ? revealWidth * 1.4 + 56
                      : cardWidth * 1.4 + 12,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Older pile stays face-down underneath.
                      for (var i = 0; i < older.length; i++)
                        Transform.translate(
                          offset: Offset(
                            (i % 3) * 1.5,
                            (i % 4) * -1.2 +
                                (showClaimFan && !gathering ? 18 : 0),
                          ),
                          child: FlightAwareCard(
                            key: vm.keyForCard(older[i].id, CardSlot.table),
                            motion: vm.motion,
                            cardId: older[i].id,
                            width: cardWidth,
                            child: PlayingCardBack(width: cardWidth),
                          ),
                        ),
                      // Last claim: fan open face-up, or tuck face-down into pile.
                      for (var i = 0; i < claimed.length; i++)
                        TweenAnimationBuilder<double>(
                          key: ValueKey(
                            '${gathering ? 'gather' : 'reveal'}_${claimed[i].id}',
                          ),
                          tween: Tween(
                            begin: gathering ? 1 : 0,
                            end: gathering ? 0 : 1,
                          ),
                          duration: Duration(
                            milliseconds: gathering ? 420 : 420,
                          ),
                          curve: gathering
                              ? Curves.easeInCubic
                              : Curves.easeOutBack,
                          builder: (context, t, _) {
                            final mid = (claimed.length - 1) / 2.0;
                            final dx = (i - mid) * fanStep * t;
                            final width =
                                cardWidth + (revealWidth - cardWidth) * t;
                            final showFace = t > 0.42;
                            return Transform.translate(
                              offset: Offset(dx, -8.0 * t),
                              child: Transform.scale(
                                scale: 0.86 + 0.14 * t,
                                child: FlightAwareCard(
                                  key: vm.keyForCard(
                                    claimed[i].id,
                                    CardSlot.table,
                                  ),
                                  motion: vm.motion,
                                  cardId: claimed[i].id,
                                  width: width,
                                  child: showFace
                                      ? PlayingCard(
                                          playingCardModel: claimed[i],
                                          isSelected: true,
                                          width: width,
                                        )
                                      : PlayingCardBack(width: width),
                                ),
                              ),
                            );
                          },
                        ),
                      if (!showClaimFan || gathering)
                        Positioned(
                          bottom: 0,
                          child: Text(
                            '${pile.length}',
                            style: AppStyle.theme.caption.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (verdict != null)
                        Positioned(
                          top: -36,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _BsRevealBanner(
                              message: verdict.$1,
                              bluffing: verdict.$2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      );
    }

    // Keep keys mounted (Offstage) so shuffle can still land on the shoe.
    return TablePlayDropZone(
      key: vm.tableKey,
      child: Offstage(
        offstage: shuffling,
        child: body,
      ),
    );
  }
}

class _BsRevealBanner extends StatelessWidget {
  const _BsRevealBanner({
    required this.message,
    required this.bluffing,
  });

  final String message;
  final bool bluffing;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final accent = bluffing ? theme.warning : theme.success;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -10),
            child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.background, width: 2),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.title.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: theme.background,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
