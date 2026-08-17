import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/ui/widgets/reaction_bubble.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class GenOpponentArea extends StatefulWidget {
  String oppId;
  GenOpponentArea({super.key, required this.oppId});
  @override
  State<StatefulWidget> createState() => GenOpponentAreaState();
}

class GenOpponentAreaState extends State<GenOpponentArea> {
  String? get opp => widget.oppId;

  @override
  Widget build(BuildContext context) {
    GeneralGameViewModel vm = context.read<GeneralGameViewModel>();
    bool highlightTurn =
        vm.gameState.round.roundStatus == .playing &&
        vm.gameState.currentTurnPlayerId == opp &&
        !vm.isAnimating;

    List<PlayingCardModel> collectedCards = vm.gameState.hands[opp] ?? [];

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppStyle.theme.dottedBox(
            color: highlightTurn
                ? AppStyle.theme.turnHighlight.withValues(alpha: 0.35)
                : null,
            child: SizedBox(
              height: 80,
              width: 80 * 3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cards = collectedCards;
                  const cardWidth = 50.0;

                  if (cards.isEmpty) return const SizedBox.shrink();

                  final count = cards.length;
                  final gap = count == 1
                      ? 0.0
                      : ((constraints.maxWidth - cardWidth) / (count - 1))
                            .clamp(12.0, 55.0);

                  final totalWidth = cardWidth + ((count - 1) * gap);

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Center(
                      child: SizedBox(
                        width: totalWidth,
                        height: 80,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (int i = 0; i < count; i++)
                              AnimatedPositioned(
                                key: ValueKey(cards[i].id),
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                left: i * gap,
                                child: FlightAwareCard(
                                  key: vm.keyForCard(
                                    cards[i].id,
                                    CardSlot.oppHand,
                                  ),
                                  card: cards[i],
                                  inFlight: vm.motion.isInFlight(cards[i].id),
                                  child:
                                      (vm.gameState.round.roundStatus ==
                                          .completed)
                                      ? PlayingCard(
                                          playingCardModel: cards[i],
                                          isSelected: false,
                                          width: cardWidth,
                                        )
                                      : PlayingCardBack(width: cardWidth),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: -4,
            bottom: -18,
            child: OpponentIdentityChip(oppId: opp ?? ''),
          ),
        ],
      ),
    );
  }
}

/// Avatar + name in the opponent hand contour. Incoming reactions pop as a bubble.
class OpponentIdentityChip extends StatelessWidget {
  const OpponentIdentityChip({super.key, required this.oppId});

  final String oppId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final theme = AppStyle.theme;
    final waiting = oppId.isEmpty;
    final info = waiting
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(vm.gameState.playersInfo[oppId] ?? {});
    final name = waiting ? 'Waiting...' : ((info['name'] as String?) ?? 'Rival');
    final avatarId = info['avatarId'] as String?;
    final score = waiting ? 0 : (vm.gameState.scores[oppId] ?? 0);
    final incoming = !waiting && vm.incomingReaction?.fromPid == oppId
        ? vm.incomingReaction
        : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.border.withValues(alpha: .55)),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: .28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerAvatarView(
                avatarId: avatarId,
                size: 28,
                showBorder: false,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 88),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$score',
                style: theme.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.turnHighlight,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 4,
          top: 40,
          child: ReactionBubblePopup(
            emoji: incoming?.emoji,
            reactionId: incoming?.id,
            tail: ReactionBubbleTail.top,
          ),
        ),
      ],
    );
  }
}
