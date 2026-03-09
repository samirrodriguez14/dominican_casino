import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:dominican_casino/ui/lobby/widgets/lobby_game_pill.dart';
import 'package:dominican_casino/view_models/lobby_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum GameMode { tresydos, casino, robaito }

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
                          color: AppStyle.theme.surface,
                          borderRadius: BorderRadius.circular(
                            AppStyle.theme.radius,
                          ),
                          onPressed: () => context.push("/lobby"),
                          child: Text(
                            "Enter Lobby",
                            style: AppStyle.theme.title,
                          ),
                        ),
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
                  context.go('/game/$gameId');
                }
              },
            ),
          ],
        );
      },
    );
  }


}

class CurrentGamesSheet extends StatelessWidget {
  const CurrentGamesSheet({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LobbyViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: AppStyle.theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, -4),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: AppStyle.theme.muted.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 2),

          Text("Current Games", style: AppStyle.theme.mutedText),
          const SizedBox(height: 2,),

          Expanded(
            child: _CurrentGamesBody(
              vm: vm,
              scrollController: scrollController,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentGamesBody extends StatelessWidget {
  const _CurrentGamesBody({required this.vm, required this.scrollController});

  final LobbyViewModel vm;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (vm.loading && vm.games.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (vm.error != null && vm.games.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            vm.error!,
            style: TextStyle(color: AppStyle.theme.danger),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (vm.games.isEmpty) {
      return Center(
        child: Text("No current games", style: AppStyle.theme.mutedText),
      );
    }

    final myUid = vm.userId;

    final myGames = vm.games.where((g) {
      final p1 = (g.player1 ?? '').trim();
      final p2 = (g.player2 ?? '').trim();
      return p1 == myUid || p2 == myUid;
    }).toList();

    if (myGames.isEmpty) {
      return Center(
        child: Text(
          "You are not in any games",
          style: AppStyle.theme.mutedText,
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: myGames.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final g = myGames[i];
        final p1Info = g.playersInfo?[g.player1 ?? ""] ?? {};
        final p2Info = g.playersInfo?[g.player2 ?? ""] ?? {};

        return LobbyGamePill(
          title: _shortId(g.id),
          subtitle: "",
          pid: myUid ?? "",
          player1: g.player1?.isNotEmpty == true ? "${p1Info['name']}" : "Open",
          player2: g.player2?.isNotEmpty == true ? "${p2Info['name']}" : "Open",
          statusText: "IN GAME",
          statusIsFull: true,
          joined: true,
          enterEnabled: true,
          enterLabel: "Enter",
          onEnter: () => context.go('/game/${g.id}'),
          onDelete: () => {},
          onShare: () => {},
        );
      },
    );
  }

  String _shortId(String id) => id.length <= 6 ? id : id.substring(0, 6);
}
