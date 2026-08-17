import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';

class GamePill extends StatelessWidget {
  const GamePill({
    super.key,
    required this.game,
    required this.myPid,
    this.myAvatarId,
    this.onOpen,
    this.onPlay,
    this.onInfo,
    this.onDelete,
    this.onShare,
  });

  final GamePillData game;
  final String myPid;
  final String? myAvatarId;
  final VoidCallback? onOpen;
  final VoidCallback? onPlay;
  final VoidCallback? onInfo;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final myTurn = game.isMyTurn(myPid);
    final isGameOver = game.gameStatus == GameStatus.gameOver;
    final didWin = game.winnerId == myPid;
    final waiting = game.gameStatus == GameStatus.waitingForPlayers;
    final highlight = myTurn && !isGameOver;
    final timeLabel = game.updatedAt == null
        ? null
        : l10n.timeAgo(game.updatedAt!);
    final actions = <Widget>[
      if (onPlay != null)
        _PillIconButton(
          icon: CupertinoIcons.play_fill,
          color: theme.textPrimary,
          background: theme.textPrimary.withValues(alpha: .14),
          onPressed: onPlay,
        ),
      if (onInfo != null)
        _PillIconButton(
          icon: CupertinoIcons.info,
          color: theme.textPrimary,
          background: theme.textPrimary.withValues(alpha: .14),
          onPressed: onInfo,
        ),
      if (waiting && onShare != null)
        _PillIconButton(
          icon: CupertinoIcons.share_up,
          color: theme.textPrimary,
          background: theme.surfaceAlt.withValues(alpha: .85),
          onPressed: onShare,
        ),
      if (onDelete != null)
        _PillIconButton(
          icon: CupertinoIcons.trash,
          color: theme.textPrimary,
          background: theme.danger,
          onPressed: onDelete,
        ),
    ];

    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
        decoration: BoxDecoration(
          color: highlight
              ? theme.border.withValues(alpha: .55)
              : theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight
                ? theme.turnHighlight.withValues(alpha: .7)
                : theme.border.withValues(alpha: .55),
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14,
              offset: Offset(0, 8),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...game.seats.map(
                        (seat) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _PlayerRow(
                            seat: seat,
                            fallbackAvatarId: seat.id == myPid
                                ? myAvatarId
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions[i],
                      ],
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${game.id}', style: theme.caption),
                      if (timeLabel != null)
                        Text(timeLabel, style: theme.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    if (highlight)
                      _StatusChip(
                        label: l10n.yourTurn,
                        color: theme.turnHighlight,
                      )
                    else if (isGameOver)
                      _StatusChip(
                        label: didWin ? l10n.won : l10n.lost,
                        color: didWin ? theme.success : theme.danger,
                      ),
                    _ModeBadge(mode: game.gameMode),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .7)),
      ),
      child: Text(
        label,
        style: AppStyle.theme.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode});

  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      GameMode.casino => 'Casino',
      GameMode.tresydos => 'Tres y Dos',
      GameMode.robaito => 'Robaito',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppStyle.theme.surfaceAlt.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppStyle.theme.border.withValues(alpha: .35),
        ),
      ),
      child: Text(label, style: AppStyle.theme.caption),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.seat, this.fallbackAvatarId});

  final GamePillSeat seat;
  final String? fallbackAvatarId;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final open = seat.isOpen;

    return Row(
      children: [
        if (open)
          Icon(CupertinoIcons.person_fill, size: 22, color: theme.muted)
        else
          PlayerAvatarView(
            avatarId: seat.avatarId ?? fallbackAvatarId,
            size: 22,
            showBorder: false,
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            open ? 'Waiting...' : seat.name,
            overflow: TextOverflow.ellipsis,
            style: open ? theme.mutedText : theme.title.copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _PillIconButton extends StatelessWidget {
  const _PillIconButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppStyle.theme.textPrimary.withValues(alpha: .14),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
