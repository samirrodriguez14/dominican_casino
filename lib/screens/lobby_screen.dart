import 'package:dominican_casino/view_models/lobby_view_model.dart';
import 'package:dominican_casino/widgets/lobby_game_pill.dart';
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
        child: Text(
          vm.error!,
          style: const TextStyle(color: CupertinoColors.systemRed),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (vm.games.isEmpty) {
      return Center(child: Text("no games", style: AppStyles.muted));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: vm.games.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final g = vm.games[i];
        return LobbyGamePill(
          gameId: g.id,
          player1Id: g.player1,
          player2Id: g.player2,
          onEnter: () => vm.joinGame(g.id),
          onDelete: () async {
            final ok = await _confirmDelete(context, g.id);
            if (!ok) return;
            await vm.deleteGame(g.id); // add this method to VM/repo
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
}
