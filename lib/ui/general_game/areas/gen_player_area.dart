import 'package:dominican_casino/ui/game/widgets/action_icon_button.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/game/widgets/cards/playing_card.dart';
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
      width: double.infinity,
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
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: vm.myHandCards.map((c) {
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
                                key: vm.keyForCard(c.id),

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
        ],
      ),
    );
  }

  Widget _buildPlayControls(BuildContext context, GeneralGameViewModel vm) {
    return Row(
      children: [
        if (vm.possiblePlayActions.isEmpty)
          ActionControlButton(
            icon: CupertinoIcons.exclamationmark,
            label: vm.isMyTurn ? "Your Turn" : "Opponent's turn",
            enabled: vm.isMyTurn,
            onTap: () {},
          ),

        if (vm.possiblePlayActions.isNotEmpty)
          Flexible(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: vm.possiblePlayActions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () =>
                          vm.performPlayAction(vm.possiblePlayActions[index]),
                      child: Container(
                        decoration: AppStyle.theme.raisedSurfaceBox(),
                        child: Text(vm.possiblePlayActions[index].toString()),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
