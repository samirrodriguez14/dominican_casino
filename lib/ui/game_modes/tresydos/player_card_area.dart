import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/game/widgets/cards/playing_card.dart';
import 'package:flutter/cupertino.dart';

// ignore: must_be_immutable
class PlayerCardArea extends StatefulWidget {
  double width;
  PlayerCardArea({super.key, this.width=40});

  @override
  State<StatefulWidget> createState() => PlayerCardAreaState();
}

class PlayerCardAreaState extends State<PlayerCardArea> {
  bool isSelected = false;
  List<PlayingCard> cards = [];
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount:5,
      itemBuilder: (context, index) {
        return Center(
          child: GestureDetector(
            onTap: () => setState(() {
              isSelected = !isSelected;
            }),
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 2),
              child: PlayingCard(
                width:widget.width ,
                playingCardModel: PlayingCardModel(
                  suit: "hearts",
                  rank: "$index",
                ),
                isSelected: isSelected,
              ),
            ),
          ),
        );
      },
    );
  }
}
