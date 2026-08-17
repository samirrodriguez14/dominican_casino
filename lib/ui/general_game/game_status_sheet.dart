import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/ui/general_game/game_info_sheet.dart';
import 'package:dominican_casino/ui/general_game/match_coin_payout.dart';
import 'package:dominican_casino/ui/widgets/coin_gain_badge.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
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
  void initState() {
    super.initState();
    widget.vm?.addListener(_onVm);
  }

  @override
  void didUpdateWidget(covariant GameStatusSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm != widget.vm) {
      oldWidget.vm?.removeListener(_onVm);
      widget.vm?.addListener(_onVm);
    }
  }

  @override
  void dispose() {
    widget.vm?.removeListener(_onVm);
    super.dispose();
  }

  void _onVm() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final theme = AppStyle.theme;
    final playerIds = gameState.playersInfo.keys.toList();
    final totalScores = gameState.scores;
    final roundScores = gameState.round.roundScores;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 460),
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
                      pendingCoins: gameState.pendingCoinsFor(playerIds[i]),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < playerIds.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _LastRoundPlayerCard(
                        name: _playerLabel(playerIds[i]),
                        avatarId: _playerAvatarId(playerIds[i]),
                        scoreMap: Map<String, dynamic>.from(
                          roundScores[playerIds[i]] ?? {},
                        ),
                        isYou: playerIds[i] == playerId,
                        isCasino: gameState.gameMode == GameMode.casino,
                      ),
                    ),
                  ],
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                'No round scores yet',
                textAlign: TextAlign.center,
                style: theme.mutedText,
              ),
            ],
            if (vm != null &&
                gameState.gameStatus == GameStatus.gameOver)
              MatchCoinPayout(vm: vm),
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
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await vm.queueHomeCoinClaim();
                          if (!context.mounted) return;
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
    await vm.queueHomeCoinClaim();
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
              onPressed: SoundService.wrapTap(
                () => Navigator.of(context).pop(false),
              ),
              child: Text('Cancel', style: AppStyle.theme.mutedText),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: SoundService.wrapTap(
                () => Navigator.of(context).pop(true),
              ),
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
              onPressed: SoundService.wrapTap(
                () => Navigator.of(context).pop(false),
              ),
              child: Text('Cancel', style: AppStyle.theme.mutedText),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: SoundService.wrapTap(
                () => Navigator.of(context).pop(true),
              ),
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
    required this.pendingCoins,
    required this.isYou,
    required this.isDealer,
  });

  final dynamic score;
  final String name;
  final String? avatarId;
  final int pendingCoins;
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
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              PlayerAvatarView(avatarId: avatarId, size: 40, showBorder: false),
              if (pendingCoins > 0)
                Positioned(
                  right: -18,
                  bottom: -4,
                  child: CoinGainBadge(pending: pendingCoins, compact: true),
                ),
            ],
          ),
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

class _LastRoundPlayerCard extends StatelessWidget {
  const _LastRoundPlayerCard({
    required this.name,
    required this.avatarId,
    required this.scoreMap,
    required this.isYou,
    required this.isCasino,
  });

  final String name;
  final String? avatarId;
  final Map<String, dynamic> scoreMap;
  final bool isYou;
  final bool isCasino;

  int _n(String key) => (scoreMap[key] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    // Card face is light — use a dark ink so opponent scores stay readable.
    final scoreColor = isYou ? theme.turnHighlight : theme.suitBlack;

    final pointChips = <({String label, String value})>[
      if (_n('A') != 0) (label: 'A', value: '+${_n('A')}'),
      if (_n('2♠') != 0) (label: '2♠', value: '+${_n('2♠')}'),
      if (_n('10♦') != 0) (label: '10♦', value: '+${_n('10♦')}'),
      if (_n('pi') != 0) (label: 'Pi', value: '+${_n('pi')}'),
      if (_n('carta') != 0) (label: 'Carta', value: '+${_n('carta')}'),
      if (_n('virao') != 0) (label: 'Virao', value: '+${_n('virao')}'),
    ];

    final coinChips = <({String label, String value})>[
      if (_n('coinsTake') > 0) (label: 'Take', value: '+${_n('coinsTake')}'),
      if (_n('coinsSpecial') > 0)
        (label: 'Special', value: '+${_n('coinsSpecial')}'),
      if (_n('coinsVirao') > 0) (label: 'Virao', value: '+${_n('coinsVirao')}'),
    ];

    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isYou
                ? theme.turnHighlight.withValues(alpha: .55)
                : theme.border.withValues(alpha: .45),
            width: isYou ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      PlayerAvatarView(
                        avatarId: avatarId,
                        size: 28,
                        showBorder: false,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: theme.suitBlack,
                          ),
                        ),
                      ),
                      Text(
                        '+${_n('total')}',
                        style: theme.title.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: scoreColor,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  if (pointChips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final chip in pointChips)
                              _MiniDetailChip(
                                label: chip.label,
                                value: chip.value,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                ],
              ),
            ),
            if (isCasino) ...[
              Container(
                height: 1,
                color: theme.border.withValues(alpha: .35),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    if (coinChips.isNotEmpty)
                      Expanded(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              alignment: WrapAlignment.end,
                              children: [
                                for (final chip in coinChips)
                                  _MiniDetailChip(
                                    label: chip.label,
                                    value: chip.value,
                                    coin: true,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(coinIcon, size: 14, color: theme.turnHighlight),
                          const SizedBox(width: 4),
                          Text(
                            '+${_n('coins')}',
                            style: theme.title.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: theme.turnHighlight,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniDetailChip extends StatelessWidget {
  const _MiniDetailChip({
    required this.label,
    required this.value,
    this.coin = false,
  });

  final String label;
  final String value;
  final bool coin;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: coin
            ? theme.turnHighlight.withValues(alpha: .12)
            : theme.background.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: coin
              ? theme.turnHighlight.withValues(alpha: .35)
              : theme.border.withValues(alpha: .3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.caption.copyWith(
              fontSize: 11,
              color: theme.textPrimary.withValues(alpha: .75),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: coin ? theme.turnHighlight : theme.textPrimary,
            ),
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
      onPressed: SoundService.wrapTap(() {
        AppHaptics.lightImpact();
        onPressed();
      }),
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
