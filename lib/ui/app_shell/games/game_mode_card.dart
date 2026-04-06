import 'package:dominican_casino/data/games_instructions.dart';
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
            gameModeTitle(mode),
            style: theme.title.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),

          Text(
            gameModePlayers(mode),
            style: theme.body,
            textAlign: TextAlign.center,
          ),

          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(theme.radius),
                  onPressed: () => _showGameInfo(context, mode),
                  child: Text("Info", style: theme.title),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: theme.border,
                  borderRadius: BorderRadius.circular(theme.radius),
                  onPressed: () => gameEnter(context, vm, mode),
                  child: Text("New", style: AppStyle.theme.title),
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

  Future<void> gameEnter(
    BuildContext context,
    GamesViewModel vm,
    GameMode mode,
  ) async {
    switch (mode) {
      case GameMode.tresydos:
        final gid = await vm.newGame(mode);
        if (gid != null && context.mounted) context.go('/game/$gid/tresydos');
        break;
      case GameMode.casino:
        final gid = await vm.newGame(mode);
        if (gid != null && context.mounted) context.go('/game/$gid/casino');
        break;
      case GameMode.robaito:
        break;
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

String gameModePlayers(GameMode mode) {
  switch (mode) {
    case GameMode.tresydos:
      return "2-4 Players";
    case GameMode.casino:
      return "2 Players";
    case GameMode.robaito:
      return "2-4 players";
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
                  color: theme.muted.withOpacity(.4),
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
                onPressed: () => Navigator.pop(context),
                child: const Text("Got it"),
              ),
            ],
          ),
        ),
      );
    },
  );
}
