import 'package:dominican_casino/models/lobby_game.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/lobby_view_model.dart';
import 'package:dominican_casino/ui/lobby/widgets/lobby_game_pill.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' show ReadContext, WatchContext;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LobbyViewModel>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LobbyViewModel>();

    return CupertinoPageScaffold(
      backgroundColor: AppStyle.theme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              //TopBar
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.go('/landing'),
                    child: const Icon(CupertinoIcons.back),
                  ),
                  const Spacer(),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AppStyle.theme.appLogo),
                      ),
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => vm.refresh(),
                    child: const Icon(CupertinoIcons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 10),
             //Body
              Expanded(child: _LobbyBody(vm: vm)),
              const SizedBox(height: 10),
             //Bottom bar buttons
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: CupertinoButton(
                      color: AppStyle.theme.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: null,
                      child: Text(
                        "Joined Games",
                        style: TextStyle(
                          color: AppStyle.theme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    // width: double.infinity,
                    child: CupertinoButton(
                      color: AppStyle.theme.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: vm.loading ? null : () => vm.createGame(),
                      child: Text(
                        "+ Create",
                        style: TextStyle(
                          color: AppStyle.theme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyBody extends StatelessWidget {
  const _LobbyBody({required this.vm});
  final LobbyViewModel vm;

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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text("No games yet", style: AppStyle.theme.mutedText),
        ),
      );
    }

    final myUid = vm.userId;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      itemCount: vm.games.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final g = vm.games[i];
        final full = _isFull(g);
        final joined = _joined(g, myUid ?? "_");
        final p1Info = g.playersInfo?[g.player1 ?? ""] ?? "";
        final p2Info = g.playersInfo?[g.player2 ?? ""] ?? "";
        return LobbyGamePill(
          title: _shortId(g.id),
          subtitle: "",
          pid: myUid??"",
          player1: g.player1?.isNotEmpty == true ? "${p1Info['name']}" : "Open",
          player2: g.player2?.isNotEmpty == true ? "${p2Info['name']}" : "Open",
          statusText: full ? "FULL" : "OPEN",
          statusIsFull: full,
          joined: joined,
          enterEnabled: !full || joined,
          enterLabel: joined
              ? "Enter"
              : full
              ? "Full"
              : "Join",

          onEnter: !full || joined
              ? () {
                  context.go('/game/${g.id}');
                }
              : null,

          onDelete: () async {
            final ok = await _confirmDelete(context, g.id);
            if (!ok) return;
            await vm.deleteGame(g.id);
          },
          onShare: () async {
            final link = "https://dominican-casino.web.app/join/${g.id}";
            final message =
                '''
                Join my Dominican Casino game!
                $link
                ''';

            await SharePlus.instance.share(ShareParams(text: message));
          },
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String gameId) async {
    final res = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Delete game?"),
        content: Text("Game: $gameId"),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  bool _isFull(LobbyGame g) {
    final p1 = (g.player1 ?? '').trim();
    final p2 = (g.player2 ?? '').trim();
    return p1.isNotEmpty && p2.isNotEmpty;
  }

  bool _joined(LobbyGame g, String myUid) {
    final p1 = (g.player1 ?? '').trim();
    final p2 = (g.player2 ?? '').trim();
    final isMe = p1 == myUid || p2 == myUid;
    return isMe;
  }

  String _shortId(String id) => id.length <= 6 ? id : id.substring(0, 6);
}
