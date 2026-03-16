import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class GamePill extends StatelessWidget {
  const GamePill({
    super.key,
    required this.game,
    required this.myPid,
    this.onEnter,
    this.onDelete,
    this.onShare,
  });

  final GamePillData game;
  final String myPid;
  final VoidCallback? onEnter;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final joined = game.containsPlayer(myPid);
    final myTurn = game.isMyTurn(myPid);

    final bg = AppStyle.theme.surface;
    final border = joined
        ? AppStyle.theme.turnHighlight
        : AppStyle.theme.surfaceAlt;

    final enterLabel = joined ? 'Enter' : 'Join';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: myTurn ? AppStyle.theme.border : bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 8),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (myTurn) ...[
                  Text("You're Up!", style: AppStyle.theme.title),
                  const SizedBox(height: 6),
                ],

                const SizedBox(height: 10),

                ...game.playerNames.map(
                  (name) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _playerRow(name),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: AppStyle.theme.surfaceAlt,
                    onPressed: onEnter,
                    child: Text(enterLabel, style: AppStyle.theme.title),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    color: AppStyle.theme.muted,
                    onPressed: onShare,
                    child: Icon(
                      CupertinoIcons.share_up,
                      size: 18,
                      color: AppStyle.theme.border,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    color: AppStyle.theme.danger,
                    onPressed: joined ? onDelete : null,
                    child: Icon(
                      CupertinoIcons.trash,
                      size: 18,
                      color: AppStyle.theme.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("ID: ${game.id}", style: AppStyle.theme.mutedText),
                  const SizedBox(width: 10),

                  _modeBadge(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppStyle.theme.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppStyle.theme.border.withValues(alpha: 0.35),
        ),
      ),
      child: Text(game.gameMode.name, style: AppStyle.theme.mutedText),
    );
  }

  Widget _playerRow(String name) {
    final open = name == 'Open' || name == 'Waiting...' || name == 'Unknown';

    return Row(
      children: [
        Icon(
          CupertinoIcons.person_fill,
          size: 16,
          color: open ? AppStyle.theme.muted : AppStyle.theme.turnHighlight,
        ),
        const SizedBox(width: 8),
        Text(
          open ? 'Waiting...' : name,
          style: open ? AppStyle.theme.mutedText : AppStyle.theme.title,
        ),
      ],
    );
  }
}
