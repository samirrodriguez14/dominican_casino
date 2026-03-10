import 'dart:math' as math;

import 'package:dominican_casino/style/layouts/casino_board.dart';
import 'package:dominican_casino/ui/game_modes/tresydos/opponent_card_area.dart';
import 'package:dominican_casino/ui/game_modes/tresydos/player_card_area.dart';
import 'package:dominican_casino/ui/game_modes/tresydos/playing_area.dart';
import 'package:flutter/cupertino.dart';

class TresyDosScreen extends StatelessWidget {
  const TresyDosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final opponentCardsWidth = screenWidth < 620
        ? screenWidth * 0.13
        : 700 * 0.08;
    final cardsWidth = screenWidth < 620 ? screenWidth * 0.2 : 700 * 0.15;
    return CupertinoPageScaffold(
      child: SafeArea(
        // child: SizedBox(
        //   width: double.infinity,
        child: Column(
          spacing: 5,
          children: [
            Text("Title"),
            Text("Board"),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: screenWidth * 0.9,
                      height: screenHeight * 0.8,
                      child: CasinoBoard(child: Container()),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: PlayingArea2(width: cardsWidth),
                    ),

                    Positioned(
                      left: -90,
                      top: 0,
                      bottom: 0, //screenHeight/8,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: opponentCardsWidth * 1.5,
                          ),
                          child: Transform.rotate(
                            angle: -math.pi / 2,
                            child: OpponentCardArea(width: opponentCardsWidth),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -90,
                      top: 0,
                      bottom: 0, //screenHeight/8,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: opponentCardsWidth * 1.5,
                          ),
                          child: Transform.rotate(
                            angle: math.pi / 2,
                            child: OpponentCardArea(width: opponentCardsWidth),
                          ),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: opponentCardsWidth * 1.5,
                        ),
                        child: OpponentCardArea(width: opponentCardsWidth),
                      ),
                    ),

                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: cardsWidth * 1.5,
                        child: PlayerCardArea(width: cardsWidth),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
