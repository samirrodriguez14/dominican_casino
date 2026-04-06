import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/current_game_sheet.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:flutter/cupertino.dart';

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
                   
                    const SizedBox(height: 20),
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
}
