import 'dart:math' as math;

import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/game/areas/opponent_area.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

// ignore: must_be_immutable
class TresydosPlayingArea extends StatefulWidget {
  double width;
  TresydosPlayingArea({super.key, this.width = 70});

  @override
  State<StatefulWidget> createState() => TresydosPlayingAreaState();
}

class TresydosPlayingAreaState extends State<TresydosPlayingArea> {
  static final Uuid _uuid = const Uuid();

  final currrentCard = PlayingCardModel(
    id: _uuid.v4().substring(0, 8),
    suit: 'spades',
    rank: "3",
  );
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 300, child: OpponentArea()),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: -94,
                child: SizedBox(
                  width: 300,
                  child: Transform.rotate(
                    angle: math.pi / 2,
                    child: OpponentArea(),
                  ),
                ),
              ),
              Positioned(
                left: -94,
                child: SizedBox(
                  width: 300,
                  child: Transform.rotate(
                    angle: -math.pi / 2,
                    child: OpponentArea(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CardDeck(
                        title: 'Take',
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
            ],
          ),
        ),
      ],
    );
  }
}
