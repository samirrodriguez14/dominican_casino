import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/animated_move_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final highlightTurn = vm.isMyTurn;
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
                const cardWidth = 100.0;
                const selectedLift = 12.0;
                if (cards.isEmpty) {
                  return const SizedBox.shrink();
                }
                final count = cards.length;

                const idealGap = 12.0;

                final idealTotalWidth =
                    (count * cardWidth) + ((count - 1) * idealGap);

                // Compute actual gap
                double gap;
                if (idealTotalWidth <= 1200) {
                  // Spread across available width
                  gap = count == 1
                      ? 0
                      : (constraints.maxWidth - (count * cardWidth)) /
                            (count - 1);
                } else {
                  // Not enough room, overlap
                  gap = (constraints.maxWidth - cardWidth) / (count - 1);
                }

                gap = gap.clamp(50.0, 80);

                final totalWidth = cardWidth + ((count - 1) * gap);

                return SizedBox(
                  width: constraints.maxWidth,
                  height: 150,
                  child: Center(
                    child: SizedBox(
                      width: totalWidth,
                      height: 150,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (int i = 0; i < count; i++)
                            Positioned(
                              left: i * gap,
                              top: vm.selectedCard == cards[i]
                                  ? 0
                                  : selectedLift,
                              child: GestureDetector(
                                onTap: () => vm.selectCard(cards[i]),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  transform: vm.selectedCard == cards[i]
                                      ? Matrix4.translationValues(0, -12, 0)
                                      : Matrix4.identity(),
                                  child: AnimatedScale(
                                    scale: vm.isCardHidden(cards[i]) ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    child: AnimatedMoveCard(
                                      key: vm.keyForCard(cards[i].id),
                                      card: cards[i],
                                      faceUp: true,
                                      width: cardWidth,
                                    ),
                                    // PlayingCard(
                                    //   playingCardModel: ,
                                    //   width: cardWidth,
                                    //   isSelected: vm.selectedCard == cards[i],
                                    // ),
                                  ),
                                ),
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
        ],
      ),
    );
  }

  Widget _buildPlayControls(BuildContext context, GeneralGameViewModel vm) {
    final actions = vm.possiblePlayActions;
    final isMyTurn = vm.isMyTurn;

    return SizedBox(
      height: 42,
      child: actions.isEmpty || !vm.isMyTurn
          ? Center(child: _TurnIndicator(isMyTurn: isMyTurn))
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(actions.length, (index) {
                        final action = actions[index];
                        final isPrimary = index == 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _ActionChipButton(
                            label: _actionLabel(action),
                            icon: _actionIcon(action),
                            primary: isPrimary,
                            onTap: () => vm.performPlayAction(action),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _actionLabel(dynamic action) {
    final name = action.runtimeType.toString();

    switch (name) {
      case 'PlayCardAction':
        return 'Play';
      case 'TakeCardAction':
        return 'Take Card';
      case 'TakeStackAction':
        return 'Take Stack';
      case 'AddCardsAction':
        return 'Add';
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
        return CupertinoIcons.plus_circle_fill;
      default:
        return CupertinoIcons.sparkles;
    }
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
            isMyTurn ? "Your Turn" : "Opponent Turn",
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
      minSize: 0,
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
