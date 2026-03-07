import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/ui/game/popups/button_instructions.dart';
import 'package:dominican_casino/ui/game/widgets/action_icon_button.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:dominican_casino/ui/game/widgets/cards/playing_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class PlayerArea extends StatefulWidget {
  const PlayerArea({super.key});
  @override
  State<StatefulWidget> createState() => PlayerAreaState();
}

class PlayerAreaState extends State<PlayerArea> {
  RoomViewModel get vm => context.read<RoomViewModel>();

  @override
  Widget build(BuildContext context) {
    final highlightTurn = vm.currentTurn;
    return Container(
      decoration: AppStyle.theme.playerSectionBox(
        highlightColor: AppStyle.theme.turnHighlight,
        highlight: highlightTurn,
        joined: false,
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: highlightTurn ? 1 : 0.8,
            child: _buildPlayControls(context, vm),
          ),
          const SizedBox(height: 10),
          Opacity(
            opacity:1,
            child: SizedBox(
              height: 150,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: vm.pHandCards.map((c) {
                          final isSelected = vm.selectedCard == c;
                          return Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: GestureDetector(
                              onTap: () => vm.selectCard(c),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                transform: isSelected
                                    ? Matrix4.translationValues(0, -12, 0)
                                    : Matrix4.identity(),
                                child: PlayingCard(
                                  playingCardModel: c,
                                  width: 90,
                                  isSelected: isSelected,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),

      // Floating deck: outside the player area box (top edge)
    );
  }

  Widget _buildPlayControls(BuildContext context, RoomViewModel vm) {
    return Row(
      children: [
        ActionControlButton(
          icon: CupertinoIcons.square_arrow_up_fill,
          label: "Play",
          enabled: vm.canPlay(),
          onTap: () {
            vm.performPlayOnTable();
          },
        ),
        const SizedBox(width: 10),

        ActionControlButton(
          icon: (vm.selectedCards.length > 1 && vm.canTake())
              ? CupertinoIcons.square_arrow_down_on_square_fill
              : CupertinoIcons.square_arrow_down_fill,
          label: (vm.selectedCards.length > 1 && vm.canTake())
              ? "+Take"
              : "Take",
          enabled: vm.canTake(),
          onTap: () {
            vm.performTakeCards();
          },
        ),
        const SizedBox(width: 10),

        ActionControlButton(
          icon: CupertinoIcons.plus_square_fill,
          label: "Add",
          enabled: vm.canAdd(),
          onTap: () {
            vm.performStackSelectedCards();
          },
        ),
        const SizedBox(width: 10),

        ActionControlButton(
          icon: CupertinoIcons.plus_square_fill_on_square_fill,
          label: "+Pair",
          enabled: vm.canAddAndPair(),
          onTap: () {
            vm.performStackAndPairSelectedCards();
          },
        ),
        const SizedBox(width: 10),

        ActionControlButton(
          icon: CupertinoIcons.square_fill_on_square_fill,
          label: "Pair",
          enabled: vm.canPair(),
          onTap: () {
            vm.performPairSelectedCards();
          },
        ),

        const SizedBox(width: 10),
        _buildControlsInfoButton(context),
      ],
    );
  }

  Widget _buildControlsInfoButton(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: AppStyle.theme.surface,
        borderRadius: BorderRadius.circular(12),
        onPressed: () => _showControlsLegendPopup(context),
        child: const Icon(CupertinoIcons.info),
      ),
    );
  }

  void _showControlsLegendPopup(BuildContext context) {
    showAppPopup(
      context: context,
      title: "Controls",
      // subtitle: "What each button does",
      primaryText: "Got it",
      content: const ControlsLegendContent(),
    );
  }

  // void _showGameStatusPopup(BuildContext context, RoomViewModel vm) {
  //   showAppPopup(
  //     context: context,
  //     title: 'Game Status',
  //     subtitle: 'Turn, dealer, round, and scores',
  //     content: GameStatusContent(vm: vm),
  //     primaryText: 'Close',
  //     onPrimary: () {}, // optional
  //     barrierDismissible: true,
  //   );
  // }

}
