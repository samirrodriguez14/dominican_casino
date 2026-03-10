
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/lobby/lobby_screen.dart';
import 'package:dominican_casino/ui/lobby/widgets/lobby_game_pill.dart';
import 'package:dominican_casino/view_models/lobby_view_model.dart';
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
        context.read<LobbyViewModel>().startListening(pid);
      }
    });
  }

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

  final LobbyViewModel vm;
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

    final myGames = vm.games.where((g) {
      final p1 = (g.player1 ?? '').trim();
      final p2 = (g.player2 ?? '').trim();
      return p1 == myUid || p2 == myUid;
    }).toList();

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
        final p1Info = g.playersInfo?[g.player1 ?? ""] ?? {};
        final p2Info = g.playersInfo?[g.player2 ?? ""] ?? {};
        final myTurn = myUid != null && g.currentTurnPlayerId == myUid;

        return LobbyGamePill(
          title: _shortId(g.id),
          subtitle: "",
          pid: myUid ?? "",
          myTurn: myTurn,
          player1: g.player1?.isNotEmpty == true ? "${p1Info['name']}" : "Open",
          player2: g.player2?.isNotEmpty == true ? "${p2Info['name']}" : "Open",
          statusText: "IN GAME",
          statusIsFull: LobbyBody.isFull(g),
          joined: LobbyBody.joined(g, myUid ?? ""),
          enterEnabled:
              !LobbyBody.isFull(g) || LobbyBody.joined(g, myUid ?? ""),
          enterLabel: "Enter",
          onEnter: () => context.go('/game/${g.id}'),
          onDelete: () async {
            final ok = await vm.confirmDelete(context, g.id);
            if (!ok) return;
            await vm.deleteGame(g.id);
          },
          onShare: () async {
            final link = "https://dominican-casino.web.app/join/${g.id}";
            final message = '''
Join my Dominican Casino game!
$link
''';

            await SharePlus.instance.share(ShareParams(text: message));
          },
        );
      },
    );
  }

  String _shortId(String id) => id.length <= 6 ? id : id.substring(0, 6);
}