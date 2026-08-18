import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Card back for sale, shown as a plain palette fill.
class StoreThemeCard extends StatelessWidget {
  const StoreThemeCard({
    super.key,
    required this.color,
    this.locked = false,
    this.selected = false,
    this.priceLabel,
    this.onTap,
  });

  final Color color;
  final bool locked;
  final bool selected;
  final String? priceLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final isLight = color.computeLuminance() > 0.42;
    final ink = isLight ? const Color(0xFF1C1612) : theme.textPrimary;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: locked ? null : SoundService.wrapTap(onTap),
      child: AspectRatio(
        aspectRatio: 2.5 / 3.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.turnHighlight.withValues(alpha: .85)
                  : ink.withValues(alpha: .14),
              width: selected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: .30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: locked
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.lock_fill,
                        color: ink.withValues(alpha: .82),
                        size: 22,
                      ),
                      if (priceLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          priceLabel!,
                          style: theme.title.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            color: ink.withValues(alpha: .88),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
