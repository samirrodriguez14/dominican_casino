
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/games_screen.dart';
import 'package:flutter/cupertino.dart';

class GameModeCard extends StatelessWidget {
  final GameMode mode;

  const GameModeCard({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
        double screenHeight = MediaQuery.of(context).size.height;

    final theme = AppStyle.theme;

    return Container(
      // height: 200,
      // width: 200,
      padding: const EdgeInsets.all(16),
      // decoration: theme.raisedSurfaceBox(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(gameModeIcon(mode), size:screenHeight*0.08 , color: theme.turnHighlight),

          const SizedBox(height: 10),

          Text(
            gameModeTitle(mode),
            style: theme.title.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            gameModeSubtitle(mode),
            style: theme.mutedText.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
    
        ],
      ),
    );
  }

  IconData gameModeIcon(GameMode mode) {
    switch (mode) {
      case GameMode.tresydos:
        return CupertinoIcons.square_stack_3d_up;
      case GameMode.casino:
        return CupertinoIcons.plus_app;
      case GameMode.robaito:
        return CupertinoIcons.app_fill;
    }
  }


  String gameModeTitle(GameMode mode) {
    switch (mode) {
      case GameMode.tresydos:
        return "Tres y Dos";
      case GameMode.casino:
        return "Casino";
      case GameMode.robaito:
        return "Robaito";
    }
  }

  String gameModeSubtitle(GameMode mode) {
    switch (mode) {
      case GameMode.tresydos:
        return "End with 3 and 2 of the same card";
      case GameMode.casino:
        return "Classic Dominican Casino Game";
      case GameMode.robaito:
        return "well.. take from the teammate";
    }
  }
}
