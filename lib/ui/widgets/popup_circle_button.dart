import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Circular icon button matching the in-card Play control.
class PopupCircleButton extends StatelessWidget {
  const PopupCircleButton({
    super.key,
    this.icon,
    this.child,
    required this.onPressed,
    this.emphasized = false,
    this.selected = false,
    this.size = 52,
  }) : assert(icon != null || child != null);

  final IconData? icon;
  final Widget? child;
  final VoidCallback onPressed;
  final bool emphasized;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final fill = selected
        ? theme.turnHighlight.withValues(alpha: .28)
        : emphasized
        ? theme.surfaceAlt
        : theme.textPrimary.withValues(alpha: .12);
    final border = selected
        ? theme.turnHighlight.withValues(alpha: .85)
        : theme.textPrimary.withValues(alpha: .18);
    final iconColor = selected ? theme.turnHighlight : theme.textPrimary;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onPressed),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .28),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child ?? Icon(icon, size: size * 0.42, color: iconColor),
      ),
    );
  }
}
