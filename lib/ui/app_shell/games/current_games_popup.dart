import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/ui/app_shell/games/game_pill.dart';
import 'package:dominican_casino/ui/general_game/game_status_sheet.dart';
import 'package:dominican_casino/ui/widgets/popup_circle_button.dart';
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

class CurrentGamesPopup extends StatefulWidget {
  const CurrentGamesPopup({super.key});

  @override
  State<CurrentGamesPopup> createState() => _CurrentGamesPopupState();
}

class _CurrentGamesPopupState extends State<CurrentGamesPopup> {
  bool _showHistory = false;

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
        child: Stack(
          children: [
            Column(
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
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      _showHistory ? l10n.gameHistory : l10n.currentGames,
                      key: ValueKey(_showHistory),
                      textAlign: TextAlign.center,
                      style: theme.title.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _CurrentGamesList(
                      key: ValueKey(_showHistory),
                      vm: vm,
                      history: _showHistory,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupCircleButton(
                    icon: _showHistory
                        ? CupertinoIcons.clock_fill
                        : CupertinoIcons.clock,
                    selected: _showHistory,
                    onPressed: () {
                      setState(() => _showHistory = !_showHistory);
                    },
                  ),
                  const SizedBox(width: 10),
                  PopupCircleButton(
                    icon: CupertinoIcons.xmark,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentGamesList extends StatelessWidget {
  const _CurrentGamesList({
    super.key,
    required this.vm,
    required this.history,
  });

  final GamesViewModel vm;
  final bool history;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final list = history ? vm.myPreviousGames : vm.myCurrentGames;

    if (vm.loading && list.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (vm.error != null && list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.couldNotLoadGames,
            style: TextStyle(color: AppStyle.theme.danger),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Text(
          history ? l10n.noPreviousGames : l10n.noCurrentGames,
          style: AppStyle.theme.mutedText,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) =>
          _CurrentGamePill(vm: vm, game: list[i], history: history),
    );
  }
}

class _CurrentGamePill extends StatelessWidget {
  const _CurrentGamePill({
    required this.vm,
    required this.game,
    required this.history,
  });

  final GamesViewModel vm;
  final GamePillData game;
  final bool history;

  @override
  Widget build(BuildContext context) {
    final waiting = game.gameStatus == GameStatus.waitingForPlayers;

    void enter() {
      Navigator.of(context).pop();
      context.go('/game/${game.id}/${game.gameMode.name}/false');
    }

    return GamePill(
      game: game,
      myPid: vm.userId ?? '',
      myAvatarId: vm.myAvatarId,
      onOpen: history ? null : enter,
      onPlay: history ? null : enter,
      onInfo: history ? () => _showGameStatus(context, vm, game) : null,
      onDelete: () async {
        final ok = await vm.confirmDelete(context, game.id);
        if (!ok) return;
        await vm.deleteGame(game.id);
      },
      onShare: !history && waiting
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
          : null,
    );
  }
}

Future<void> _showGameStatus(
  BuildContext context,
  GamesViewModel vm,
  GamePillData game,
) {
  final future = vm.loadGameState(game.id);
  return showAppPopup<void>(
    context: context,
    title: 'Game Status',
    subtitle: game.id,
    content: _GameStatusLoader(
      future: future,
      playerId: vm.userId ?? '',
    ),
  );
}

class _GameStatusLoader extends StatelessWidget {
  const _GameStatusLoader({required this.future, required this.playerId});

  final Future<GameState> future;
  final String playerId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GameState>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Could not load this game.',
                style: TextStyle(color: AppStyle.theme.danger),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const SizedBox(
            height: 180,
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        return GameStatusSheet(
          gameState: snap.data,
          playerId: playerId,
          showActions: false,
        );
      },
    );
  }
}
