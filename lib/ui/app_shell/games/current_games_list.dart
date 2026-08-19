import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/services/share_invite.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/ui/app_shell/games/game_pill.dart';
import 'package:dominican_casino/ui/general_game/game_status_sheet.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Current or history games as [GamePill] rows.
class CurrentGamesList extends StatelessWidget {
  const CurrentGamesList({
    super.key,
    required this.history,
    this.onBeforeEnter,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 16),
    this.embeddedInCard = false,
  });

  final bool history;
  final VoidCallback? onBeforeEnter;
  final EdgeInsetsGeometry padding;
  final bool embeddedInCard;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GamesViewModel>();
    final l10n = AppLocalizations.of(context);
    final all = history ? vm.myPreviousGames : vm.myCurrentGames;
    final list = history ? vm.visiblePreviousGames : all;
    final showLoadMore = history && vm.hasMoreHistory;

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
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: padding,
      itemCount: list.length + (showLoadMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (showLoadMore && i == list.length) {
          return _LoadMoreRow(onPressed: vm.loadMoreHistory);
        }
        return _CurrentGamePill(
          vm: vm,
          game: list[i],
          history: history,
          onBeforeEnter: onBeforeEnter,
          embeddedInCard: embeddedInCard,
        );
      },
    );
  }
}

class _CurrentGamePill extends StatelessWidget {
  const _CurrentGamePill({
    required this.vm,
    required this.game,
    required this.history,
    this.onBeforeEnter,
    this.embeddedInCard = false,
  });

  final GamesViewModel vm;
  final GamePillData game;
  final bool history;
  final VoidCallback? onBeforeEnter;
  final bool embeddedInCard;

  @override
  Widget build(BuildContext context) {
    final waiting = game.gameStatus == GameStatus.waitingForPlayers;

    void enter() {
      onBeforeEnter?.call();
      context.go('/game/${game.id}/${game.gameMode.name}/false');
    }

    return GamePill(
      game: game,
      myPid: vm.userId ?? '',
      myAvatarId: vm.myAvatarId,
      embeddedInCard: embeddedInCard,
      onOpen: history ? null : enter,
      onPlay: history ? null : enter,
      onInfo: history ? () => _showGameStatus(context, vm, game) : null,
      onDelete: () async {
        final ok = await vm.confirmDelete(context, game.id);
        if (!ok) return;
        await vm.deleteGame(game.id);
      },
      onShare: !history && waiting
          ? (buttonContext) => shareGameInvite(
              context: buttonContext,
              gameId: game.id,
              gameMode: game.gameMode.name,
            )
          : null,
    );
  }
}

class _LoadMoreRow extends StatelessWidget {
  const _LoadMoreRow({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    return Center(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        onPressed: SoundService.wrapTap(onPressed),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.loadMore,
              style: theme.mutedText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: theme.muted,
            ),
          ],
        ),
      ),
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
    content: _GameStatusLoader(future: future, playerId: vm.userId ?? ''),
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
