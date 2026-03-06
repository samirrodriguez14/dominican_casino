import 'package:dominican_casino/ui/game/decks/players_deck.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:dominican_casino/ui/game/widgets/cards/playing_area_stack.dart';
import 'package:dominican_casino/ui/game/widgets/cards/playing_card.dart';
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Opacity(
            opacity: vm.controlGame ? 0.5 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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

        Positioned(
          left: -5,
          top: 0,
          bottom: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PlayersDeck(
                cards: vm.oppCollectedCards,
                me: false,
                extraPoints: vm.oppExtraPoints,
              ),
              PlayersDeck(
                cards: vm.pCollectedCards,
                me: true,
                extraPoints: vm.myExtraPoints,
              ),
            ],
          ),
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
}
