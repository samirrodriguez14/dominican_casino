import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_pill.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class CurrentGamesSheet extends StatefulWidget {
  const CurrentGamesSheet({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  State<CurrentGamesSheet> createState() => _CurrentGamesSheetState();
}

class _CurrentGamesSheetState extends State<CurrentGamesSheet> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pid = context.read<AppRepo>().player?.id;
      if (pid != null) {
        context.read<GamesViewModel>().startListening(pid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GamesViewModel>();

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
          const SizedBox(height: 2),

          Expanded(
            child: _CurrentGamesBody(
              vm: vm,
              scrollController: widget.scrollController,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentGamesBody extends StatelessWidget {
  const _CurrentGamesBody({required this.vm, required this.scrollController});

  final GamesViewModel vm;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (vm.loading && vm.games.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 40),
          Center(child: CupertinoActivityIndicator()),
          SizedBox(height: 400),
        ],
      );
    }

    if (vm.error != null && vm.games.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              vm.error!,
              style: TextStyle(color: AppStyle.theme.danger),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 400),
        ],
      );
    }

    if (vm.games.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 10),
          Center(
            child: Text("No current games", style: AppStyle.theme.mutedText),
          ),
          const SizedBox(height: 400),
        ],
      );
    }

    final myUid = vm.userId;

    final myGames = myUid == null
        ? <GamePillData>[]
        : vm.games.where((g) => g.containsPlayer(myUid)).toList();

    if (myGames.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 40),
          Center(
            child: Text(
              "You are not in any games",
              style: AppStyle.theme.mutedText,
            ),
          ),
          const SizedBox(height: 400),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: myGames.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final g = myGames[i];

        return GamePill(
          game: g,
          myPid: myUid ?? '',
          onEnter: () => context.go('/game/${g.id}/${g.gameMode.name}/false'),
          onDelete: () async {
            final ok = await vm.confirmDelete(context, g.id);
            if (!ok) return;
            await vm.deleteGame(g.id);
          },
          onShare:g.gameStatus ==GameStatus.waitingForPlayers?
           () async {
            final link = "https://dominican-casino.web.app/join/${g.id}/${g.gameMode}";
            final message =
                '''
                Join my Dominican ${gameModeTo(g.gameMode)} game!
                $link
                ''';

            await SharePlus.instance.share(ShareParams(text: message));
          }: ()=>{},
        );
      },
    );
  }
}
