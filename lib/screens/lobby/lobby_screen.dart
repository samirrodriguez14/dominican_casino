import 'package:dominican_casino/models/lobby_game.dart';
import 'package:dominican_casino/view_models/lobby_view_model.dart';
import 'package:dominican_casino/screens/lobby/widgets/lobby_game_pill.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' show ReadContext, WatchContext;
import 'package:dominican_casino/style/theme_data.dart';
import 'package:provider/provider.dart';

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
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.go('/home'),
                    child: const Icon(CupertinoIcons.back),
                  ),
                  const Spacer(),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/images/logo_icon_transparent.png',
                        ),
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
              Expanded(child: _LobbyBody(vm: vm)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: vm.loading ? null : () => vm.createGame(),
                  child: const Text(
                    "Create Game",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
          style: const TextStyle(color: CupertinoColors.systemRed),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  if (vm.games.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text("No games yet", style: AppStyles.muted),
      ),
    );
  }

  final myUid = vm.userId; // <-- expose current user id in your VM

  return ListView.separated(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
    itemCount: vm.games.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (context, i) {
      final g = vm.games[i];

      final full = _isFull(g);
      final canEnter = _canEnter(g, myUid?? "");

      return LobbyGamePill(
        // New UI props you’ll add:
        title: "Game ${_shortId(g.id)}",
        subtitle: "P1: ${g.player1?.isNotEmpty == true ? "Ready" : "Open"}  •  "
            "P2: ${g.player2?.isNotEmpty == true ? "Ready" : "Open"}",
        statusText: full ? "FULL" : "OPEN",
        statusIsFull: full,

        enterEnabled: canEnter,
        enterLabel: canEnter ? "Enter" : "Full",

        onEnter: canEnter ? () => vm.joinGame(g.id) : null,

        onDelete: () async {
          final ok = await _confirmDelete(context, g.id);
          if (!ok) return;
          await vm.deleteGame(g.id);
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

/// Allow entering if there's a spot OR user is already one of the players
bool _canEnter(LobbyGame g, String myUid) {
  final p1 = (g.player1 ?? '').trim();
  final p2 = (g.player2 ?? '').trim();
  final isMe = p1 == myUid || p2 == myUid;
  return isMe || !_isFull(g);
}

String _shortId(String id) => id.length <= 6 ? id : id.substring(0, 6);
}
