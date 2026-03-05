import 'package:dominican_casino/style/theme_data.dart';
import 'package:flutter/cupertino.dart';
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
    final bg = AppColors.surface; // or your raisedSurfaceBox
    final border = AppColors.surfaceAlt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withOpacity(0.6)),
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
                    Text(title, style: AppStyles.theme.title),
                    const SizedBox(width: 8),
                    _StatusChip(text: statusText, isFull: statusIsFull),
                  ],
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: AppStyles.theme.mutedText),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Actions
          Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: enterEnabled
                    ? AppColors.cerulean
                    : AppColors.cardBorder,
                onPressed: onEnter, // null disables
                child: Text(enterLabel,style: AppStyles.theme.title,)
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: AppColors.accentRed,
                onPressed: onDelete,
                child: const Icon(CupertinoIcons.trash, size: 18, color: AppColors.cardBorder,),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.isFull});
  final String text;
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    final bg = isFull
        ? AppColors.accentRed.withOpacity(0.18)
        : AppColors.accentGreen.withOpacity(0.18);
    final fg = isFull ? AppColors.accentRed : AppColors.accentGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}