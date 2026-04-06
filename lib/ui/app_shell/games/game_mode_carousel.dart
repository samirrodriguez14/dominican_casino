import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class GameModeCarousel extends StatefulWidget {
  const GameModeCarousel({super.key});

  @override
  State<GameModeCarousel> createState() => _GameModeCarouselState();
}

class _GameModeCarouselState extends State<GameModeCarousel> {
  final PageController controller = PageController(
    viewportFraction: 0.5,
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
                  const SizedBox(height: 16),

                  Text(
                    "or",
                    style: AppStyle.theme.mutedText.copyWith(fontSize: 16),
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
                        onPressed: () =>
                            _showJoinGameDialog(context, mode.name),
                        child: Text("Join by Id", style: AppStyle.theme.title),
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

  void _showJoinGameDialog(BuildContext context, String mode) {
    final TextEditingController controller = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Join Game"),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: controller,
              placeholder: "Enter Game ID",
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text("Join", style: AppStyle.theme.title),
              onPressed: () {
                final gameId = controller.text.trim();

                Navigator.pop(context);

                if (gameId.isNotEmpty) {
                  context.go('/game/$gameId/$mode');
                }
              },
            ),
          ],
        );
      },
    );
  }
}
