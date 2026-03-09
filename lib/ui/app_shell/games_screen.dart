import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

enum GameMode { tresydos, casino, robaito }

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<StatefulWidget> createState() => GamesScreenState();
}

class GamesScreenState extends State<GamesScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 220),

          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage(AppStyle.theme.appLogo)),
            ),
          ),

          SizedBox(height: 30),
          GameModeCarousel(),
          // SizedBox(height: ),
        ],
      ),
    );
  }
}

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
    return Expanded(
      // height: 220,
      child: PageView.builder(
        controller: controller,
        itemCount: GameMode.values.length,
        itemBuilder: (context, index) {
          final diff = (page - index).abs();
          final scale = (1 - (diff * 0.25)).clamp(0.7, 1.0);
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

class GameModeCard extends StatelessWidget {
  final GameMode mode;

  const GameModeCard({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;

    return Container(
      // height: 200,
      // width: 200,
      padding: const EdgeInsets.all(16),
      // decoration: theme.raisedSurfaceBox(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(gameModeIcon(mode), size: 40, color: theme.turnHighlight),

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
