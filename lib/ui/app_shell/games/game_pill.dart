import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';

class GamePill extends StatelessWidget {
  const GamePill({
    super.key,
    required this.game,
    required this.myPid,
    this.myAvatarId,
    this.embeddedInCard = false,
    this.onOpen,
    this.onPlay,
    this.onInfo,
    this.onDelete,
    this.onShare,
  });

  final GamePillData game;
  final String myPid;
  final String? myAvatarId;
  final bool embeddedInCard;
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
    final waiting = game.gameStatus == GameStatus.waitingForPlayers;
    final highlight = myTurn && !isGameOver;
    final timeLabel = game.updatedAt == null
        ? null
        : l10n.timeAgo(game.updatedAt!);
    final ranks = isGameOver ? game.finishRanks() : const <String, int>{};
    final actions = <Widget>[
      if (onPlay != null)
        _PillIconButton(
          icon: CupertinoIcons.play_fill,
          color: theme.textPrimary,
          background: theme.textPrimary.withValues(alpha: .14),
          embeddedInCard: embeddedInCard,
          onPressed: onPlay,
        ),
      if (onInfo != null)
        _PillIconButton(
          icon: CupertinoIcons.info,
          color: theme.textPrimary,
          background: theme.textPrimary.withValues(alpha: .14),
          embeddedInCard: embeddedInCard,
          onPressed: onInfo,
        ),
      if (waiting && onShare != null)
        _PillIconButton(
          icon: CupertinoIcons.share_up,
          color: theme.textPrimary,
          background: embeddedInCard
              ? theme.textPrimary.withValues(alpha: .14)
              : theme.surfaceAlt.withValues(alpha: .85),
          embeddedInCard: embeddedInCard,
          onPressed: onShare,
        ),
      if (onDelete != null)
        _PillIconButton(
          icon: CupertinoIcons.trash,
          color: theme.textPrimary,
          background: embeddedInCard
              ? theme.danger.withValues(alpha: .72)
              : theme.danger,
          embeddedInCard: embeddedInCard,
          onPressed: onDelete,
        ),
    ];

    return GestureDetector(
      onTap: SoundService.wrapTap(onOpen),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          embeddedInCard ? 12 : 14,
          embeddedInCard ? 10 : 12,
          embeddedInCard ? 10 : 12,
          embeddedInCard ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: embeddedInCard
              ? (highlight
                    ? theme.turnHighlight.withValues(alpha: .14)
                    : theme.textPrimary.withValues(alpha: .08))
              : (highlight
                    ? theme.border.withValues(alpha: .55)
                    : theme.surface),
          borderRadius: BorderRadius.circular(embeddedInCard ? 12 : 16),
          border: Border.all(
            color: embeddedInCard
                ? (highlight
                      ? theme.turnHighlight.withValues(alpha: .55)
                      : theme.textPrimary.withValues(alpha: .16))
                : (highlight
                      ? theme.turnHighlight.withValues(alpha: .7)
                      : theme.border.withValues(alpha: .55)),
          ),
          boxShadow: embeddedInCard
              ? null
              : const [
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
                            place: ranks[seat.id],
                            coinsMade: isGameOver
                                ? game.coinsMade(seat.id)
                                : 0,
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
                        embeddedInCard: embeddedInCard,
                      ),
                    if (game.jackpot > 0)
                      _JackpotChip(
                        amount: game.jackpot,
                        embeddedInCard: embeddedInCard,
                      ),
                    _ModeBadge(
                      mode: game.gameMode,
                      embeddedInCard: embeddedInCard,
                    ),
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
  const _StatusChip({
    required this.label,
    required this.color,
    this.embeddedInCard = false,
  });

  final String label;
  final Color color;
  final bool embeddedInCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: embeddedInCard ? .18 : .16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: embeddedInCard ? .6 : .7),
        ),
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

class _JackpotChip extends StatelessWidget {
  const _JackpotChip({
    required this.amount,
    this.embeddedInCard = false,
  });

  final int amount;
  final bool embeddedInCard;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final gold = theme.turnHighlight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: embeddedInCard ? .18 : .16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: gold.withValues(alpha: embeddedInCard ? .55 : .65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(coinIcon, size: 11, color: gold),
          const SizedBox(width: 4),
          Text(
            '$amount',
            style: theme.caption.copyWith(
              color: gold,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode, this.embeddedInCard = false});

  final GameMode mode;
  final bool embeddedInCard;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final label = switch (mode) {
      GameMode.casino => 'Casino',
      GameMode.casinoSpeed => 'Casino Speed',
      GameMode.tresydos => 'Tres y Dos',
      GameMode.robaito => 'Robaito',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: embeddedInCard
            ? theme.textPrimary.withValues(alpha: .10)
            : theme.surfaceAlt.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: embeddedInCard
              ? theme.textPrimary.withValues(alpha: .18)
              : theme.border.withValues(alpha: .35),
        ),
      ),
      child: Text(
        label,
        style: theme.caption.copyWith(
          color: embeddedInCard
              ? theme.textPrimary.withValues(alpha: .82)
              : null,
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.seat,
    this.fallbackAvatarId,
    this.place,
    this.coinsMade = 0,
  });

  final GamePillSeat seat;
  final String? fallbackAvatarId;
  final int? place;
  final int coinsMade;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final open = seat.isOpen;
    final gold = theme.turnHighlight;
    final placeColor = place == 1
        ? gold
        : place == 2
            ? gold.withValues(alpha: .78)
            : theme.muted;

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
        if (!open && place != null) ...[
          const SizedBox(width: 8),
          Text(
            l10n.placeShort(place!),
            style: theme.caption.copyWith(
              color: placeColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          if (coinsMade > 0) ...[
            const SizedBox(width: 6),
            Text(
              '+$coinsMade',
              style: theme.caption.copyWith(
                color: gold,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ],
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
    this.embeddedInCard = false,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onPressed;
  final bool embeddedInCard;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final size = embeddedInCard ? 36.0 : 40.0;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onPressed),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.textPrimary.withValues(
              alpha: embeddedInCard ? .18 : .14,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: embeddedInCard ? 16 : 18, color: color),
      ),
    );
  }
}
