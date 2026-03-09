import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/settings/settings_screen.dart';
import 'package:flutter/cupertino.dart';

class ThemeOptionCard extends StatelessWidget {
  const ThemeOptionCard({
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
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: previewTheme.raisedSurfaceBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ThemePreviewHeader(
              themeType: themeType,
              previewTheme: previewTheme,
              selected: selected,
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
      ),
    );
  }
}

class _ThemePreviewHeader extends StatelessWidget {
  const _ThemePreviewHeader({
    required this.themeType,
    required this.previewTheme,
    required this.selected,
  });

  final Theme themeType;
  final AppTheme previewTheme;
  final bool selected;

  String get label {
    switch (themeType) {
      case Theme.feltWaltnut:
        return 'Felt Walnut';
      case Theme.walnut:
        return 'Walnut';
      case Theme.casino:
        return 'Casino';
      case Theme.midnight:
        return 'Midnight';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: previewTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
