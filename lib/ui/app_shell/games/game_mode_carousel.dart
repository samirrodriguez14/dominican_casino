import 'package:dominican_casino/data/games_instructions.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class GameModeCarousel extends StatefulWidget {
  const GameModeCarousel({super.key});

  @override
  State<GameModeCarousel> createState() => _GameModeCarouselState();
}

class _GameModeCarouselState extends State<GameModeCarousel> {
  final PageController controller = PageController(
    viewportFraction: 0.7,
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
      height: screenHeight * 0.5,
      child: PageView.builder(
        controller: controller,
        itemCount: GameMode.values.length,
        itemBuilder: (context, index) {
          final diff = (page - index).abs();
          final scale = (1 - (diff * 0.3)).clamp(0.1, 1.0);
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
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 16,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.all(12),
                        color: AppStyle.theme.border,
                        borderRadius: BorderRadius.circular(
                          AppStyle.theme.radius,
                        ),
                        onPressed: () => _showGameInfo(context, mode),
                        child: Text("Tutorial", style: AppStyle.theme.title),
                      ),
                    ],
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

void _showGameInfo(BuildContext context, GameMode mode) {
  final theme = AppStyle.theme;

  showCupertinoModalPopup(
    context: context,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.muted.withValues(alpha: .4),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 16),

              Text("How to Play", style: theme.title),

              const SizedBox(height: 12),

              Text(
                gamesData[mode.name].toString(),
                style: theme.body,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 18),

              CupertinoButton.filled(
                onPressed: () {
                  Uuid uuid = Uuid();
                  context.go('/game/${uuid.v4().substring(0, 6)}/casino/true');
                },
                child: const Text("Got it"),
              ),
            ],
          ),
        ),
      );
    },
  );
}
