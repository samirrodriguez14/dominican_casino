import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class GenPlayerArea extends StatefulWidget {
  const GenPlayerArea({super.key});
  @override
  State<StatefulWidget> createState() => GenPlayerAreaState();
}

class GenPlayerAreaState extends State<GenPlayerArea> {
  GeneralGameViewModel get vm => context.read<GeneralGameViewModel>();

  final GlobalKey _fanKey = GlobalKey();
  double _fanGap = 50;
  static const double _cardWidth = 100.0;

  @override
  Widget build(BuildContext context) {
    final highlightTurn = vm.canPlayTurn;
    return Container(
      key: vm.myHandKey,
      decoration: AppStyle.theme.playerSectionBox(
        highlightColor: AppStyle.theme.turnHighlight,
        highlight: highlightTurn,
        joined: false,
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayControls(context, vm),

          const SizedBox(height: 10),

          SizedBox(
            height: 150,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cards = vm.myHandCards;
                const selectedLift = 12.0;
                if (cards.isEmpty) {
                  return const SizedBox.shrink();
                }
                final count = cards.length;

                const idealGap = 12.0;

                final idealTotalWidth =
                    (count * _cardWidth) + ((count - 1) * idealGap);

                // Compute actual gap
                double gap;
                if (idealTotalWidth <= 1200) {
                  // Spread across available width
                  gap = count == 1
                      ? 0
                      : (constraints.maxWidth - (count * _cardWidth)) /
                            (count - 1);
                } else {
                  // Not enough room, overlap
                  gap = (constraints.maxWidth - _cardWidth) / (count - 1);
                }

                gap = gap.clamp(50.0, 80);
                _fanGap = gap;

                final totalWidth = _cardWidth + ((count - 1) * gap);
                final draggingId = vm.draggingHandCard?.id;

                return SizedBox(
                  width: constraints.maxWidth,
                  height: 150,
                  child: Center(
                    child: DragTarget<PlayingCardModel>(
                      onWillAcceptWithDetails: (_) => !vm.isAnimating,
                      onAcceptWithDetails: (details) {
                        final from = cards.indexWhere(
                          (c) => c.id == details.data.id,
                        );
                        if (from < 0) return;
                        final to = _insertIndexFor(
                          globalOffset: details.offset,
                          count: count,
                        );
                        vm.reorderHand(from, to);
                      },
                      builder: (context, candidate, rejected) {
                        return SizedBox(
                          key: _fanKey,
                          width: totalWidth,
                          height: 150,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (int i = 0; i < count; i++)
                                AnimatedPositioned(
                                  key: ValueKey(cards[i].id),
                                  duration: draggingId == cards[i].id
                                      ? Duration.zero
                                      : const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  left: i * gap,
                                  top: vm.selectedCard == cards[i]
                                      ? 0
                                      : selectedLift,
                                  child: _HandDragCard(
                                    card: cards[i],
                                    cardWidth: _cardWidth,
                                    enabled: !vm.isAnimating,
                                    isSelected:
                                        vm.cardSelection.selectedCard ==
                                        cards[i],
                                    flightKey: vm.keyForCard(
                                      cards[i].id,
                                      CardSlot.myHand,
                                    ),
                                    motion: vm.motion,
                                    onTap: () => vm.selectCard(cards[i]),
                                    onDragStarted: () =>
                                        vm.beginHandDrag(cards[i]),
                                    onDragEnded: vm.endHandDrag,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Slot index from the feedback's top-left, relative to the fan stack.
  int _insertIndexFor({required Offset globalOffset, required int count}) {
    final box = _fanKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return count.clamp(0, count);
    final local = box.globalToLocal(globalOffset);
    final centerX = local.dx + _cardWidth / 2;
    if (_fanGap <= 0) return 0;
    return (centerX / _fanGap).round().clamp(0, count);
  }

  Widget _buildPlayControls(BuildContext context, GeneralGameViewModel vm) {
    final actions = vm.possiblePlayActions;
    final canPlay = vm.canPlayTurn;

    return SizedBox(
      height: 42,
      child: actions.isEmpty || !canPlay
          ? Center(child: _TurnIndicator(isMyTurn: canPlay))
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < actions.length; index++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: KeyedSubtree(
                              key: _widgetKeyForAction(vm, actions, index),
                              child: _ActionChipButton(
                                label: _actionLabel(actions[index]),
                                icon: _actionIcon(actions[index]),
                                primary: index == 0,
                                onTap: () =>
                                    vm.performPlayAction(actions[index]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Key _widgetKeyForAction(
    GeneralGameViewModel vm,
    List<dynamic> actions,
    int index,
  ) {
    final action = actions[index];
    final name = action.runtimeType.toString();

    // Assign each tutorial GlobalKey to at most one chip in this row.
    final isFirstAddAndTake =
        name == 'AddAndTakeAction' &&
        actions.indexWhere(
              (a) => a.runtimeType.toString() == 'AddAndTakeAction',
            ) ==
            index;
    if (isFirstAddAndTake) return vm.playButtonKey;

    final isFirstAdd =
        (name == 'AddCardsAction' ||
            name == 'AddCardStackAction' ||
            name == 'AddTableCardsAction') &&
        actions.indexWhere((a) {
              final n = a.runtimeType.toString();
              return n == 'AddCardsAction' ||
                  n == 'AddCardStackAction' ||
                  n == 'AddTableCardsAction';
            }) ==
            index;
    if (isFirstAdd) return vm.addButtonKey;

    final isFirstTakeStack =
        name == 'TakeStackAction' &&
        actions.indexWhere(
              (a) => a.runtimeType.toString() == 'TakeStackAction',
            ) ==
            index;
    if (isFirstTakeStack) return vm.takeStackButtonKey;

    final isFirstPlayish =
        (name == 'PlayCardAction' ||
            name == 'TakeCardAction' ||
            name == 'PairCardsAction') &&
        actions.indexWhere((a) {
              final n = a.runtimeType.toString();
              return n == 'PlayCardAction' ||
                  n == 'TakeCardAction' ||
                  n == 'PairCardsAction';
            }) ==
            index;
    if (isFirstPlayish) return vm.playButtonKey;

    return ValueKey('action_${name}_$index');
  }

  String _actionLabel(dynamic action) {
    final name = action.runtimeType.toString();

    switch (name) {
      case 'PlayCardAction':
        return 'Play';
      case 'TakeCardAction':
        return 'Take';
      case 'TakeStackAction':
        return 'Take Stack';
      case 'AddCardsAction':
        return 'Add';
      case 'PairCardsAction':
        return 'Pair';
      case 'PairTableCardsAction':
        return 'Pair Table';
      case 'AddAndPairCardsAction':
        return 'Add & Pair';
      case 'AddAndTakeAction':
        return 'Add & Take';
      case 'PairAndTakeCardsAction':
        return 'Pair & Take';
      default:
        return name.replaceAll('Action', '');
    }
  }

  IconData _actionIcon(dynamic action) {
    final name = action.runtimeType.toString();

    switch (name) {
      case 'PlayCardAction':
        return CupertinoIcons.arrow_up_circle_fill;
      case 'TakeCardAction':
        return CupertinoIcons.arrow_down_circle_fill;
      case 'TakeStackAction':
        return CupertinoIcons.square_stack_3d_up_fill;
      case 'AddCardsAction':
      case 'AddCardStackAction':
      case 'AddTableCardsAction':
        return CupertinoIcons.plus_circle_fill;
      case 'PairCardsAction':
      case 'PairTableCardsAction':
        return CupertinoIcons.link;
      default:
        return CupertinoIcons.sparkles;
    }
  }
}

class _HandDragCard extends StatelessWidget {
  const _HandDragCard({
    required this.card,
    required this.cardWidth,
    required this.enabled,
    required this.isSelected,
    required this.flightKey,
    required this.motion,
    required this.onTap,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  final PlayingCardModel card;
  final double cardWidth;
  final bool enabled;
  final bool isSelected;
  final GlobalKey flightKey;
  final CardMotionController motion;
  final VoidCallback onTap;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  @override
  Widget build(BuildContext context) {
    // Keep [flightKey] inside the selection lift so overlay flights start on the
    // painted card — not the un-lifted layout slot under LongPressDraggable.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: isSelected
          ? Matrix4.translationValues(0, -12, 0)
          : Matrix4.identity(),
      child: FlightAwareCard(
        key: flightKey,
        motion: motion,
        cardId: card.id,
        child: LongPressDraggable<PlayingCardModel>(
          data: card,
          maxSimultaneousDrags: enabled ? 1 : 0,
          hapticFeedbackOnStart: true,
          onDragStarted: onDragStarted,
          onDragEnd: (_) => onDragEnded(),
          onDraggableCanceled: (_, _) => onDragEnded(),
          feedback: Opacity(
            opacity: 0.92,
            child: PlayingCard(
              playingCardModel: card,
              width: cardWidth,
              isSelected: true,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: PlayingCard(
              playingCardModel: card,
              width: cardWidth,
              isSelected: isSelected,
            ),
          ),
          child: GestureDetector(
            onTap: onTap,
            child: PlayingCard(
              playingCardModel: card,
              width: cardWidth,
              isSelected: isSelected,
            ),
          ),
        ),
      ),
    );
  }
}

class _TurnIndicator extends StatelessWidget {
  const _TurnIndicator({required this.isMyTurn});

  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMyTurn
            ? AppStyle.theme.turnHighlight.withValues(alpha: .18)
            : AppStyle.theme.suitBlack,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMyTurn ? CupertinoIcons.hand_raised_fill : CupertinoIcons.clock,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isMyTurn
                ? AppLocalizations.of(context).yourTurn
                : AppLocalizations.of(context).opponentTurn,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bgColor = primary
        ? AppStyle.theme.turnHighlight
        : AppStyle.theme.surface;

    final fgColor = primary
        ? CupertinoColors.white
        : AppStyle.theme.textPrimary;

    final borderColor = primary
        ? AppStyle.theme.turnHighlight
        : AppStyle.theme.muted.withValues(alpha: 0.22);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: primary
              ? [
                  BoxShadow(
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                    color: AppStyle.theme.turnHighlight.withValues(alpha: 0.22),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
