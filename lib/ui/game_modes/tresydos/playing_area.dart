import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/game/decks/card_deck.dart';
import 'package:dominican_casino/ui/game/widgets/cards/playing_card.dart';
import 'package:flutter/cupertino.dart';

// ignore: must_be_immutable
class PlayingArea2 extends StatefulWidget {
  double width;
  PlayingArea2({super.key, this.width = 70});

  @override
  State<StatefulWidget> createState() => PlayingAreaState();
}

class PlayingAreaState extends State<PlayingArea2> {
  final currrentCard = PlayingCardModel(suit: 'spades', rank: "3");
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CardDeck(
                cards: [],
                cardWidth: widget.width,
                extraPoints: 0,
                onTap: () => {},
              ),
            ],
          ),
          SizedBox(width: 10),
          PlayingCard(
            playingCardModel: currrentCard,
            isSelected: false,
            width: widget.width,
          ),
        ],
      ),
    );
  }
}
