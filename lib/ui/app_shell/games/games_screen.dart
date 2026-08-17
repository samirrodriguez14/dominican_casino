import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:flutter/cupertino.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, shellTopBarHeight(context), 12, 108),
      child: const GameModeCarousel(),
    );
  }
}
