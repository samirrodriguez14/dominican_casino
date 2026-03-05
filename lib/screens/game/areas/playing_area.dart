import 'package:dominican_casino/screens/game/widgets/cards/playing_card_back.dart';
import 'package:dominican_casino/style/theme_data.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:dominican_casino/screens/game/widgets/cards/playing_area_stack.dart';
import 'package:dominican_casino/screens/game/widgets/cards/playing_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PlayingArea extends StatefulWidget {
  const PlayingArea({super.key});
  @override
  State<StatefulWidget> createState() => PlayingAreaState();
}

class PlayingAreaState extends State<PlayingArea> {
  RoomViewModel get vm => context.read<RoomViewModel>();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: vm.controlGame ? Alignment.center : Alignment.bottomRight,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          // decoration: AppStyles.premiumGameTable(),
          child: Opacity(
            opacity: vm.controlGame ? 0.5 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Playing Area", style: AppStyles.theme.body),
                        Text(
                          'Last Take: ${vm.lastTookCard}',
                          style: AppStyles.theme.body,
                        ),
                      ],
                    ),
                    if (vm.anySelected)
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            vm.cancelSelection();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.xmark_circle_fill, size: 15),
                              Text("selection", style: AppStyles.theme.body),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 18,
                    ),
                    child: _buildCardWrap(context, vm),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: vm.controlGame ? Alignment.center : Alignment.bottomRight,
          child: Padding(padding: EdgeInsets.all(8), child: _buildDeckArea(vm)),
        ),
      ],
    );
  }

  Widget _buildCardWrap(BuildContext context, RoomViewModel vm) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        ...vm.playingAreaStacks.map((stack) {
          bool isSelected = vm.selectedStacks.contains(stack);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: vm.controlGame ? null : () => vm.selectStack(stack),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: isSelected
                  ? Matrix4.translationValues(0, -12, 0)
                  : Matrix4.identity(),
              child: PlayingAreaStack(stack: stack, isSelected: isSelected),
            ),
          );
        }),

        ...vm.playingAreaCards.map((c) {
          bool isSelected = vm.selectedCards.contains(c);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,

            onTap: vm.controlGame ? null : () => vm.selectCardToStack(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: isSelected
                  ? Matrix4.translationValues(0, -12, 0)
                  : Matrix4.identity(),
              child: PlayingCard(playingCardModel: c, isSelected: isSelected),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDeckArea(RoomViewModel vm) {
    final g = vm.g;

    final remaining = g?.deck.length;
    final started = g?.started ?? false;
    final isController = vm.isController;
    final canRedeal = vm.canRedeal;

    final canStart = vm.canStart;

    final String subtitle = remaining == null ? "-" : "$remaining";

    late final IconData actionIcon;
    late final String actionLabel;
    late final VoidCallback? onAction;

    if (g == null) {
      actionIcon = CupertinoIcons.lock_circle_fill;
      actionLabel = "Deleted";
      onAction = null;
    } else if (!started) {
      if (canStart) {
        actionIcon = CupertinoIcons.play_circle_fill;
        actionLabel = "Start";
        onAction = () => vm.startGame();
      } else {
        actionIcon = CupertinoIcons.lock_circle_fill;
        actionLabel = isController ? "Waiting…" : "Locked";
        onAction = null;
      }
    } else {
      if (canRedeal) {
        actionIcon = CupertinoIcons.refresh_circled_solid;
        actionLabel = "Redeal";
        onAction = (vm.canStartNextRound)
            ? () => vm.startNextRound()
            : () => vm.redealSameRound();
      } else {
        actionIcon = CupertinoIcons.lock_circle_fill;
        actionLabel = "Waiting…";
        onAction = null;
      }
    }

    return _deckBox(
      subtitle: subtitle,
      actionLabel: actionLabel,
      actionIcon: actionIcon,
      onAction: onAction,
      isEnabled: vm.controlGame,
      hasCards: remaining != 0,
    );
  }

  Widget _deckBox({
    required String subtitle,
    required IconData actionIcon,
    String actionLabel = "",
    VoidCallback? onAction,
    required bool isEnabled,
    bool hasCards = false,
  }) {
    final actionEnbled = isEnabled && onAction != null;
    final double cardWidth = isEnabled ? 70 : 32;
    final double cardHeight = isEnabled ? 100 : 44;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: actionEnbled
          ? () async {
              onAction();
            }
          : (actionLabel == "Deleted")
          ? () async {
              await vm.leaveGame();
              if (mounted) context.go('/lobby');
            }
          : null,
      child: Opacity(
        opacity: actionEnbled ? 1 : .8,
        child: Container(
          padding: EdgeInsets.all((isEnabled) ? 12 : 2),
          decoration: AppStyles.theme.raisedSurfaceBox(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PlayingCardBack(
                    width: cardWidth,
                    height: cardHeight,
                    empty: !hasCards,
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppStyles.theme.mutedText),
                ],
              ),
              if (isEnabled) SizedBox(width: 8),

              if (isEnabled)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(actionIcon, size: cardWidth),
                    Text(actionLabel, style: AppStyles.theme.title),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
