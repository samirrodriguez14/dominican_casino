import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Circular icon button matching the in-card Play control.
class PopupCircleButton extends StatelessWidget {
  const PopupCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: emphasized
              ? theme.surfaceAlt
              : theme.textPrimary.withValues(alpha: .12),
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: .18),
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .28),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: theme.textPrimary),
      ),
    );
  }
}
