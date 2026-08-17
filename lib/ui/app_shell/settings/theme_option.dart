import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ThemeOptionCard extends StatelessWidget {
  const ThemeOptionCard({
    super.key,
    required this.themeType,
    required this.previewTheme,
    required this.selected,
    required this.onTap,
    this.locked = false,
    this.badgeLabel,
  });

  final Theme themeType;
  final AppTheme previewTheme;
  final bool selected;
  final VoidCallback? onTap;
  final bool locked;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: locked ? null : SoundService.wrapTap(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: previewTheme.raisedSurfaceBox(),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ThemePreviewHeader(
                  themeType: themeType,
                  previewTheme: previewTheme,
                  selected: selected,
                  locked: locked,
                  badgeLabel: badgeLabel,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: previewTheme.background,
                      borderRadius: BorderRadius.circular(previewTheme.radius),
                      border: Border.all(color: previewTheme.border),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _PreviewMiniCard(
                                  imagePath: previewTheme.cardBack,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PreviewMiniIcon(
                                  imagePath: previewTheme.appLogo,
                                  theme: previewTheme,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _ColorDot(previewTheme.background),
                            const SizedBox(width: 6),
                            _ColorDot(previewTheme.surface),
                            const SizedBox(width: 6),
                            _ColorDot(previewTheme.surfaceAlt),
                            const SizedBox(width: 6),
                            _ColorDot(previewTheme.turnHighlight),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (locked)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(previewTheme.radius),
                  ),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.lock_fill,
                      color: previewTheme.textPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemePreviewHeader extends StatelessWidget {
  const _ThemePreviewHeader({
    required this.themeType,
    required this.previewTheme,
    required this.selected,
    this.locked = false,
    this.badgeLabel,
  });

  final Theme themeType;
  final AppTheme previewTheme;
  final bool selected;
  final bool locked;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            themeLabel(themeType),
            style: TextStyle(
              color: previewTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (badgeLabel != null)
          Text(
            badgeLabel!,
            style: TextStyle(
              color: previewTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          )
        else if (!locked)
          AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: selected ? 1 : 0.9,
            child: Icon(
              selected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: selected ? previewTheme.turnHighlight : previewTheme.muted,
              size: 20,
            ),
          ),
      ],
    );
  }
}

class _PreviewMiniCard extends StatelessWidget {
  const _PreviewMiniCard({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(CupertinoIcons.square_stack_3d_down_right),
          ),
        ),
      ),
    );
  }
}

class _PreviewMiniIcon extends StatelessWidget {
  const _PreviewMiniIcon({required this.imagePath, required this.theme});

  final String imagePath;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(CupertinoIcons.app_fill, color: theme.turnHighlight, size: 28),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: CupertinoColors.white.withValues(alpha: .25)),
      ),
    );
  }
}

/// Compact theme picker: name + a color swatch (fits inside a settings card).
class ThemeOptionChip extends StatelessWidget {
  const ThemeOptionChip({
    super.key,
    required this.themeType,
    required this.previewTheme,
    required this.selected,
    required this.onTap,
  });

  final Theme themeType;
  final AppTheme previewTheme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? previewTheme.surfaceAlt.withValues(alpha: .7)
              : theme.textPrimary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? previewTheme.turnHighlight.withValues(alpha: .85)
                : theme.textPrimary.withValues(alpha: .14),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: previewTheme.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: previewTheme.turnHighlight,
                  width: 1.6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                themeLabel(themeType),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? theme.textPrimary : theme.muted,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
