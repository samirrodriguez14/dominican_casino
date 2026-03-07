import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class LobbyGamePill extends StatelessWidget {
  const LobbyGamePill({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusIsFull,
    required this.enterEnabled,
    required this.enterLabel,
    required this.onEnter,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final String statusText;
  final bool statusIsFull;

  final bool enterEnabled;
  final String enterLabel;
  final VoidCallback? onEnter;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bg = AppStyle.theme.surface; // or your raisedSurfaceBox
    final border = AppStyle.theme.surfaceAlt;

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
          // Left text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Game $title", style: AppStyle.theme.title),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: AppStyle.theme.mutedText),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Actions
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
                color: AppStyle.theme.danger,
                onPressed: onDelete,
                child: Icon(
                  CupertinoIcons.trash,
                  size: 18,
                  color: AppStyle.theme.border,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
