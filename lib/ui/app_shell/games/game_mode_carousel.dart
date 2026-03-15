import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:flutter/cupertino.dart';

class GameModeCarousel extends StatefulWidget {
  const GameModeCarousel({super.key});

  @override
  State<GameModeCarousel> createState() => _GameModeCarouselState();
}

class _GameModeCarouselState extends State<GameModeCarousel> {
  final PageController controller = PageController(
    viewportFraction: 0.55,
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
      height: screenHeight * 0.3,
      child: PageView.builder(
        controller: controller,
        itemCount: GameMode.values.length,
        itemBuilder: (context, index) {
          final diff = (page - index).abs();
          final scale = (1 - (diff * 0.4)).clamp(0.1, 1.0);
          final mode = GameMode.values[index];
          return Center(
            child: Transform.scale(
              scale: scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: AppStyle.theme.raisedSurfaceBox(),
                    child: GameModeCard(mode: mode),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
