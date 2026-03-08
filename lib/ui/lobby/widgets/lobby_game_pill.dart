import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class LobbyGamePill extends StatelessWidget {
  const LobbyGamePill({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pid,
    required this.player1,
    required this.player2,
    required this.statusText,
    required this.statusIsFull,
    required this.enterEnabled,
    required this.enterLabel,
    required this.onEnter,
    required this.onDelete,
    required this.joined,
    required this.onShare,
  });

  final String title;
  final String subtitle;
  final String pid;
  final String player1;
  final String player2;
  final String statusText;
  final bool statusIsFull;

  final bool enterEnabled;
  final bool joined;
  final String enterLabel;
  final VoidCallback? onEnter;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final bg = AppStyle.theme.surface;
    final border = joined
        ? AppStyle.theme.turnHighlight
        : AppStyle.theme.surfaceAlt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: (0.6))),
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
                _playerRow(player1),
                const SizedBox(height: 6),
                _playerRow(player2),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Actions
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
                    color: enterEnabled
                        ? AppStyle.theme.surfaceAlt
                        : AppStyle.theme.border,
                    onPressed: onEnter, // null disables
                    child: Text(enterLabel, style: AppStyle.theme.title),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    color: AppStyle.theme.muted,
                    onPressed: statusIsFull ? null : onShare,
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
              const SizedBox(height: 4),

              Text("gameId: $title", style: AppStyle.theme.mutedText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playerRow(String name) {
    final open = name == "Open";

    return Row(
      children: [
        Icon(
          CupertinoIcons.person_fill,
          size: 16,
          color: open ? AppStyle.theme.muted : AppStyle.theme.turnHighlight,
        ),
        const SizedBox(width: 8),
        Text(
          open ? "Waiting..." : name,
          style: open ? AppStyle.theme.mutedText : AppStyle.theme.title,
        ),
      ],
    );
  }
}
