import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/app_shell/store/store_catalog.dart';
import 'package:flutter/cupertino.dart';

/// Playing-card face for an energy or coin pack. Price and icon sit
/// inline at the top-left, with a smaller copy at the bottom-right.
class StoreBundleCard extends StatelessWidget {
  const StoreBundleCard({
    super.key,
    required this.bundle,
    this.onTap,
    this.onLongPress,
    this.overlayLabel,
  });

  final StoreBundle bundle;
  final void Function(Offset? origin)? onTap;
  final VoidCallback? onLongPress;
  final String? overlayLabel;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final face = _faceColor(theme);
    final accent = bundle.kind == StoreBundleKind.energy
        ? theme.warning
        : theme.turnHighlight;
    final overlay = overlayLabel ??
        (bundle.comingSoon ? AppLocalizations.of(context).comingSoon : null);
    final canTap = overlay == null && onTap != null;

    Widget card = CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: canTap
          ? SoundService.wrapTap(() {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null || !box.hasSize) {
                onTap?.call(null);
                return;
              }
              onTap?.call(box.localToGlobal(box.size.center(Offset.zero)));
            })
          : null,
      child: AspectRatio(
        aspectRatio: 2.5 / 3.5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final inset = (w * 0.08).clamp(5.0, 10.0);
            final priceSize = (w * 0.155).clamp(9.0, 15.0);
            final amountSize = (w * 0.30).clamp(16.0, 34.0);
            final iconSize = (w * 0.26).clamp(16.0, 32.0);

            return DecoratedBox(
              decoration: BoxDecoration(
                color: face,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.textPrimary.withValues(alpha: .14),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: .30),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: inset,
                    left: inset,
                    child: _PriceIndex(
                      price: bundle.priceLabel,
                      icon: bundle.priceIcon,
                      fontSize: priceSize,
                      color: theme.textPrimary,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(bundle.icon, size: iconSize, color: accent),
                        SizedBox(height: w * 0.04),
                        Text(
                          bundle.amountLabel,
                          style: theme.title.copyWith(
                            fontSize: amountSize,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: inset,
                    right: inset,
                    child: _PriceIndex(
                      price: bundle.priceLabel,
                      icon: bundle.priceIcon,
                      fontSize: priceSize * 0.78,
                      color: theme.textPrimary.withValues(alpha: .78),
                    ),
                  ),
                  if (overlay != null)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: CupertinoColors.black.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              overlay,
                              textAlign: TextAlign.center,
                              style: theme.title.copyWith(
                                fontSize: (w * 0.12).clamp(9.0, 13.0),
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (onLongPress == null) return card;
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: IgnorePointer(
        ignoring: !canTap,
        child: card,
      ),
    );
  }

  Color _faceColor(AppTheme theme) {
    return bundle.kind == StoreBundleKind.energy
        ? theme.pickerFace
        : theme.pickerFaceAlt;
  }
}

class _PriceIndex extends StatelessWidget {
  const _PriceIndex({
    required this.price,
    required this.icon,
    required this.fontSize,
    required this.color,
  });

  final String price;
  final IconData icon;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: fontSize * 0.95, color: color),
        SizedBox(width: fontSize * 0.18),
        Text(
          price,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
