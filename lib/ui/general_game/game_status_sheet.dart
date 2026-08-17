import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/ui/general_game/game_info_sheet.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

Future<void> showGameStatusPopup(
  BuildContext context, {
  GeneralGameViewModel? vm,
  GameState? gameState,
  String? playerId,
  bool showActions = true,
}) {
  return showAppPopup<void>(
    context: context,
    title: 'Game Status',
    subtitle: gameState?.id ?? vm?.gameState.id,
    content: GameStatusSheet(
      vm: vm,
      gameState: gameState,
      playerId: playerId,
      showActions: showActions,
    ),
  );
}

class GameStatusSheet extends StatefulWidget {
  const GameStatusSheet({
    super.key,
    this.vm,
    this.gameState,
    this.playerId,
    this.scrollController,
    this.showActions,
  }) : assert(vm != null || (gameState != null && playerId != null));

  final GeneralGameViewModel? vm;
  final GameState? gameState;
  final String? playerId;
  final ScrollController? scrollController;
  final bool? showActions;

  @override
  State<GameStatusSheet> createState() => _GameStatusSheetState();
}

class _GameStatusSheetState extends State<GameStatusSheet> {
  GameState get gameState => widget.vm?.gameState ?? widget.gameState!;
  String get playerId => widget.vm?.player.id ?? widget.playerId!;
  bool get showActions => widget.showActions ?? widget.vm != null;

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final theme = AppStyle.theme;
    final playerIds = gameState.playersInfo.keys.toList();
    final totalScores = gameState.scores;
    final roundScores = gameState.round.roundScores;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 360),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 0; i < playerIds.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _ScoreCard(
                      score: totalScores[playerIds[i]] ?? 0,
                      name: _playerLabel(playerIds[i]),
                      avatarId: _playerAvatarId(playerIds[i]),
                      isYou: playerIds[i] == playerId,
                      isDealer: gameState.controllerId == playerIds[i],
                    ),
                  ),
                ],
              ],
            ),
            if (roundScores.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Last round',
                style: theme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              ...playerIds.map((pid) {
                final scoreMap = Map<String, dynamic>.from(
                  roundScores[pid] ?? {},
                );
                if (scoreMap.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LastRoundRow(
                    name: _playerLabel(pid),
                    avatarId: _playerAvatarId(pid),
                    scoreMap: scoreMap,
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                'No round scores yet',
                textAlign: TextAlign.center,
                style: theme.mutedText,
              ),
            ],
            if (vm != null || showActions) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (vm != null) ...[
                    Expanded(
                      child: _CompactActionButton(
                        label: 'Rules',
                        icon: CupertinoIcons.info,
                        onPressed: () {
                          showAppPopup(
                            context: context,
                            title: 'How to play',
                            content: GameInfoSheet(vm: vm),
                          );
                        },
                      ),
                    ),
                    if (showActions) const SizedBox(width: 10),
                  ],
                  if (showActions && vm != null) ...[
                    Expanded(
                      child: _CompactActionButton(
                        label: 'Lobby',
                        icon: CupertinoIcons.house_fill,
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/landing');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactActionButton(
                        label: 'Resign',
                        icon: CupertinoIcons.arrow_right_square_fill,
                        danger: true,
                        onPressed: () => _handleResign(context, vm),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _playerAvatarId(String pid) {
    final raw = gameState.playersInfo[pid];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw)['avatarId'] as String?;
  }

  String _playerLabel(String pid) {
    if (pid == playerId) return 'You';
    final info = Map<String, dynamic>.from(
      gameState.playersInfo[pid] ?? <String, dynamic>{},
    );
    return (info['name'] as String?) ?? pid;
  }

  Future<void> _handleResign(
    BuildContext context,
    GeneralGameViewModel vm,
  ) async {
    final shouldLeave = vm.opp == null
        ? await _confirmExitEmptyGame(context)
        : await _confirmResignGame(context);
    if (shouldLeave != true || !context.mounted) return;
    await vm.resign();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    context.go('/landing');
  }

  Future<bool?> _confirmResignGame(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Resign?'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Your opponent wins this match.'),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: AppStyle.theme.mutedText),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Resign'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmExitEmptyGame(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Exit game?'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('This will delete the current game.'),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: AppStyle.theme.mutedText),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.score,
    required this.name,
    required this.avatarId,
    required this.isYou,
    required this.isDealer,
  });

  final dynamic score;
  final String name;
  final String? avatarId;
  final bool isYou;
  final bool isDealer;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final accent = isYou ? theme.turnHighlight : theme.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isYou
              ? theme.turnHighlight.withValues(alpha: .45)
              : theme.border.withValues(alpha: .5),
        ),
      ),
      child: Column(
        children: [
          PlayerAvatarView(avatarId: avatarId, size: 40, showBorder: false),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (isDealer) ...[
                const SizedBox(width: 6),
                Text(
                  'Dealer',
                  style: theme.caption.copyWith(color: theme.muted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: theme.title.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: accent,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LastRoundRow extends StatelessWidget {
  const _LastRoundRow({
    required this.name,
    required this.avatarId,
    required this.scoreMap,
  });

  final String name;
  final String? avatarId;
  final Map<String, dynamic> scoreMap;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final chips = <Widget>[
      if ((scoreMap['A'] ?? 0) != 0)
        _MiniScoreChip(label: 'A', value: '${scoreMap['A']}'),
      if ((scoreMap['2♠'] ?? 0) != 0)
        _MiniScoreChip(label: '2♠', value: '${scoreMap['2♠']}'),
      if ((scoreMap['10♦'] ?? 0) != 0)
        _MiniScoreChip(label: '10♦', value: '${scoreMap['10♦']}'),
      if ((scoreMap['pi'] ?? 0) != 0)
        _MiniScoreChip(label: 'Pi', value: '${scoreMap['pi']}'),
      if ((scoreMap['carta'] ?? 0) != 0)
        _MiniScoreChip(label: 'Carta', value: '${scoreMap['carta']}'),
      if ((scoreMap['virao'] ?? 0) != 0)
        _MiniScoreChip(label: 'Virao', value: '${scoreMap['virao']}'),
      _MiniScoreChip(
        label: 'Total',
        value: '${scoreMap['total'] ?? 0}',
        highlight: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlayerAvatarView(avatarId: avatarId, size: 22, showBorder: false),
              const SizedBox(width: 8),
              Text(
                name,
                style: theme.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: chips),
        ],
      ),
    );
  }
}

class _MiniScoreChip extends StatelessWidget {
  const _MiniScoreChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? theme.turnHighlight.withValues(alpha: .14)
            : theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? theme.turnHighlight.withValues(alpha: .35)
              : theme.border.withValues(alpha: .25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.caption),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.caption.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final fg = danger ? theme.danger : theme.textPrimary;
    final bg = danger
        ? theme.danger.withValues(alpha: .12)
        : theme.surfaceAlt.withValues(alpha: .55);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: danger
                ? theme.danger.withValues(alpha: .35)
                : theme.border.withValues(alpha: .4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.body.copyWith(
                fontWeight: FontWeight.w700,
                color: fg,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
