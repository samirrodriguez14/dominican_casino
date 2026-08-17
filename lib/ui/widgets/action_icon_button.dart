import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
class ActionControlButton extends StatelessWidget {
  const ActionControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? AppStyle.theme.surfaceAlt : AppStyle.theme.surface;
    final fg = enabled ? AppStyle.theme.textPrimary : AppStyle.theme.muted;

    return Expanded(
      child: AnimatedScale(
        scale: enabled ? 1.0 : 0.92,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.55,
          duration: const Duration(milliseconds: 140),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            borderRadius: BorderRadius.circular(14),
            color: bg,
            onPressed: SoundService.wrapTap(enabled ? onTap : null),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: fg),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppStyle.theme.body.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}