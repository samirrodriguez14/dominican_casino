import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Theme for sale, shown as the card back itself.
class StoreThemeCard extends StatelessWidget {
  const StoreThemeCard({
    super.key,
    required this.previewTheme,
    this.locked = false,
    this.priceLabel,
    this.onTap,
  });

  final AppTheme previewTheme;
  final bool locked;
  final String? priceLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onTap),
      child: AspectRatio(
        aspectRatio: 2.5 / 3.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: CupertinoColors.black.withValues(alpha: .18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: .30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(previewTheme.cardBack, fit: BoxFit.cover),
                if (locked)
                  ColoredBox(
                    color: CupertinoColors.black.withValues(alpha: .42),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.lock_fill,
                            color: theme.textPrimary,
                            size: 28,
                          ),
                          if (priceLabel != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              priceLabel!,
                              style: theme.title.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
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
