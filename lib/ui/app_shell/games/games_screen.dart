import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/current_game_sheet.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

enum GameMode { tresydos, casino, casinoNew, robaito }

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: screenHeight * 0.18,
                      height: screenHeight * 0.18,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(AppStyle.theme.appLogo),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      "Select a game to Start",
                      style: AppStyle.theme.mutedText.copyWith(fontSize: 16),
                    ),

                    GameModeCarousel(),
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
                          onPressed: () => _showJoinGameDialog(context),
                          child: Text(
                            "Join by Id",
                            style: AppStyle.theme.title,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),

            // Draggable challenge sheet
            DraggableScrollableSheet(
              initialChildSize: 0.10,
              minChildSize: 0.10,
              maxChildSize: 0.82,
              snap: true,
              // expand: false,
              snapSizes: const [0.10, .82],
              builder: (context, scrollController) {
                return CurrentGamesSheet(scrollController: scrollController);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinGameDialog(BuildContext context) {
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
                  context.go('/gengame/$gameId');
                }
              },
            ),
          ],
        );
      },
    );
  }
}
