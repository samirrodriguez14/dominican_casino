import 'package:dominican_casino/ui/game/widgets/cards/playing_card_back.dart';
import 'package:flutter/cupertino.dart';

// ignore: must_be_immutable
class OpponentCardArea extends StatefulWidget {
  double width;
  OpponentCardArea({super.key, this.width = 40});

  @override
  State<StatefulWidget> createState() => OppoenetCardAreaState();
}

class OppoenetCardAreaState extends State<OpponentCardArea> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,

      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 1),
          child: PlayingCardBack(width: widget.width),
        );
      },
    );
  }
}
