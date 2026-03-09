import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:dominican_casino/ui/app_shell/games/games_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class GameModeCarousel extends StatefulWidget {
  const GameModeCarousel({super.key});

  @override
  State<GameModeCarousel> createState() => _GameModeCarouselState();
}

class _GameModeCarouselState extends State<GameModeCarousel> {
  final PageController controller = PageController(
    viewportFraction: 0.45,
    initialPage: 1,
  );

  double page = 1;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {
        page = controller.page ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
        double screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight*0.28,
      child: PageView.builder(
        controller: controller,
        itemCount: GameMode.values.length,
        itemBuilder: (context, index) {
          final diff = (page - index).abs();
          final scale = (1 - (diff * 0.25)).clamp(0.5, 1.0);
          final mode =  GameMode.values[index];
          return Center(
            child: Transform.scale(
              scale: scale,
              child: Column(
                children: [
                  Container(
                    decoration: AppStyle.theme.raisedSurfaceBox(),
                    child: CupertinoButton(
                      onPressed: () => gameEnter(context, mode),
                      child: GameModeCard(mode: mode),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void gameEnter(BuildContext context, GameMode mode) {
    switch (mode) {
      case GameMode.tresydos:
        // context.go('');
        break;
      case GameMode.casino:
        context.go('/lobby');
        break;
      case GameMode.robaito:
        // context.go('/landing');
        break;
    }
  }
}
