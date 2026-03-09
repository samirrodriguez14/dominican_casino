import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/challenge_players.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:flutter/cupertino.dart';

enum GameMode { tresydos, casino, robaito }

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<StatefulWidget> createState() => GamesScreenState();
}

class GamesScreenState extends State<GamesScreen> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: screenHeight * 0.05),

          Container(
            width: screenHeight * 0.2,
            height: screenHeight * 0.2,
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage(AppStyle.theme.appLogo)),
            ),
          ),

          SizedBox(height: screenHeight *0.05),
          GameModeCarousel(),
          // SizedBox(height: 10),

          ChallengePlayersSection(),
          // SizedBox(height: 10),
        ],
      ),
    );
  }
}
