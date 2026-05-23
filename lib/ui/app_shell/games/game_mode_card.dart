import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameModeCard extends StatelessWidget {
  final GameMode mode;

  const GameModeCard({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<GamesViewModel>();
    double screenHeight = MediaQuery.of(context).size.height;

    final theme = AppStyle.theme;
    final game = vm.gamesInfo.firstWhere((g) => g.id == mode.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        spacing: 8,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            gameModeIcon(mode),
            size: screenHeight * 0.08,
            color: theme.turnHighlight,
          ),

          Text(
            game.title,
            style: theme.title.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),

          Text(
            game.players.label,
            style: theme.body,
            textAlign: TextAlign.center,
          ),

          Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(theme.radius),
                  onPressed: () => _showJoinGameDialog(context, mode.name),
                  child: Text("Join By Id", style: theme.title),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: theme.border,
                  borderRadius: BorderRadius.circular(theme.radius),
                  onPressed: () => _showEnterGameDialog(context, vm, mode),
                  child: Text("Play", style: AppStyle.theme.title),
                ),
              ),
            ],
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

void _showEnterGameDialog(
  BuildContext context,
  GamesViewModel vm,
  GameMode mode,
) {
  showCupertinoDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text("Start New Game Against"),

        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text("Friend", style: AppStyle.theme.title),
            onPressed: () => gameEnter(context, vm, mode, false),
          ),

          CupertinoDialogAction(
            child: Text("Puli (AI bot)", style: AppStyle.theme.title),
            onPressed: () => gameEnter(context, vm, mode, true),
          ),
        ],
      );
    },
  );
}

Future<void> gameEnter(
  BuildContext context,
  GamesViewModel vm,
  GameMode mode,
  bool local,
) async {
  switch (mode) {
    case GameMode.tresydos:
      final gid = await vm.newGame(mode, local);
      if (gid != null && context.mounted) context.go('/game/$gid/tresydos');
      break;
    case GameMode.casino:
      final gid = await vm.newGame(mode, local);
      if (gid != null && context.mounted) context.go('/game/$gid/casino');
      break;
    case GameMode.robaito:
      break;
  }
}
