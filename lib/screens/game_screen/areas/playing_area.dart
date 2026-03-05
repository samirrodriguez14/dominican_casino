import 'package:dominican_casino/screens/game_screen/widgets/playing_card_back.dart';
import 'package:dominican_casino/style/theme_data.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:dominican_casino/widgets/playing_area_stack.dart';
import 'package:dominican_casino/widgets/playing_card.dart';
import 'package:flutter/cupertino.dart';
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppStyles.surfaceBox(),
      child: Stack(
        alignment: vm.controlGame? Alignment.center:  Alignment.bottomRight,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Playing Area", style: AppStyles.title),
              const SizedBox(height: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 18,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ...vm.playingAreaStacks.map((stack) {
                          bool isSelected = vm.selectedStacks.contains(stack);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => vm.selectStack(stack),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              transform: isSelected
                                  ? Matrix4.translationValues(0, -12, 0)
                                  : Matrix4.identity(),
                              child: PlayingAreaStack(
                                stack: stack,
                                isSelected: isSelected,
                              ),
                            ),
                          );
                        }),

                        ...vm.playingAreaCards.map((c) {
                          bool isSelected = vm.selectedCards.contains(c);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,

                            onTap: () => vm.selectCardToStack(c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              transform: isSelected
                                  ? Matrix4.translationValues(0, -12, 0)
                                  : Matrix4.identity(),
                              child: PlayingCard(
                                playingCardModel: c,
                                isSelected: isSelected,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 70, maxWidth: 100),
            child: _buildDeckArea(vm),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckArea(RoomViewModel vm) {
    final g = vm.g;

    final remaining = g?.deck.length;
    final started = g?.started ?? false;
    final isController = vm.isController; 
    final canRedeal = vm.canRedeal;

    final canStart = vm.canStart;

    // Decide label/icon/handler in one place
    final String title = "Deck";
    final String subtitle = remaining == null ? "-" : "$remaining left";

    late final IconData actionIcon;
    late final String actionLabel;
    late final VoidCallback? onAction;

    if (!started) {
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
        actionLabel = isController ? "Waiting…" : "Locked";
        onAction = null;
      }
    }

    return _deckBox(
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      actionIcon: actionIcon,
      onAction: onAction,
      hasCards: remaining != 0,
    );
  }

  Widget _deckBox({
    required String title,
    required String subtitle,
    required IconData actionIcon,
    String? actionLabel,
    VoidCallback? onAction,
    bool enabled = true,
    bool hasCards = false,
  }) {
    final isEnabled = enabled && onAction != null;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isEnabled ? onAction : null,
      child: Opacity(
        opacity: isEnabled ? 1 : .35,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: AppStyles.raisedSurfaceBox(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PlayingCardBack(width: 32, height: 44, empty: !hasCards),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppStyles.title),
                  const SizedBox(height: 6),
                  Text(subtitle, style: AppStyles.body),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


}
