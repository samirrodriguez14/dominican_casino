import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_pill.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Opens a modal listing the player's current games. Fully dismissed on close.
Future<void> showCurrentGamesPopup(BuildContext context) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) => const CurrentGamesPopup(),
  );
}

class CurrentGamesPopup extends StatelessWidget {
  const CurrentGamesPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GamesViewModel>();
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final height = MediaQuery.of(context).size.height * 0.78;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: theme.muted.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: theme.textPrimary,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.currentGames,
                      textAlign: TextAlign.center,
                      style: theme.title.copyWith(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 46),
                ],
              ),
            ),
            Expanded(child: _CurrentGamesList(vm: vm)),
          ],
        ),
      ),
    );
  }
}

class _CurrentGamesList extends StatelessWidget {
  const _CurrentGamesList({required this.vm});

  final GamesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final list = vm.myCurrentGames;

    if (vm.loading && list.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (vm.error != null && list.isEmpty) {
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

    if (list.isEmpty) {
      return Center(
        child: Text(l10n.noCurrentGames, style: AppStyle.theme.mutedText),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _CurrentGamePill(vm: vm, game: list[i]),
    );
  }
}

class _CurrentGamePill extends StatelessWidget {
  const _CurrentGamePill({required this.vm, required this.game});

  final GamesViewModel vm;
  final GamePillData game;

  @override
  Widget build(BuildContext context) {
    return GamePill(
      game: game,
      myPid: vm.userId ?? '',
      onEnter: () {
        Navigator.of(context).pop();
        context.go('/game/${game.id}/${game.gameMode.name}/false');
      },
      onDelete: () async {
        final ok = await vm.confirmDelete(context, game.id);
        if (!ok) return;
        await vm.deleteGame(game.id);
      },
      onShare: game.gameStatus == GameStatus.waitingForPlayers
          ? () async {
              final link =
                  'https://dominican-casino.web.app/join/${game.id}/${game.gameMode}';
              final message =
                  '''
                Join my Dominican ${gameModeTo(game.gameMode)} game!
                $link
                ''';
              await SharePlus.instance.share(ShareParams(text: message));
            }
          : () {},
    );
  }
}
