import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/current_game_sheet.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  static const _emptySheetSize = 0.10;
  static const _withGamesSheetSize = 0.28;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final vm = context.watch<GamesViewModel>();
    final uid = vm.userId;
    final hasCurrentGames =
        uid != null && vm.games.any((g) => g.containsPlayer(uid));
    final sheetSize = hasCurrentGames ? _withGamesSheetSize : _emptySheetSize;

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

            DraggableScrollableSheet(
              key: ValueKey(hasCurrentGames ? 'sheet-games' : 'sheet-empty'),
              initialChildSize: sheetSize,
              minChildSize: sheetSize,
              maxChildSize: 0.82,
              snap: true,
              snapSizes: [sheetSize, 0.82],
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
