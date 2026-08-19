import 'package:dominican_casino/models/theme_pack.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';

class PlayingCardBack extends StatelessWidget {
  final double width;
  final CardBack? cardBack;
  final AppTheme? previewTheme;
  final String? tintId;
  final CardBackMark? mark;
  final String? avatarId;
  final VoidCallback? onTap;
  final bool showShadow;

  const PlayingCardBack({
    super.key,
    this.width = 44,
    this.cardBack,
    this.previewTheme,
    this.tintId,
    this.mark,
    this.avatarId,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = previewTheme ?? AppStyle.theme;
    final height = width * 1.4;
    final radius = (width * 0.125).clamp(6.0, 14.0);
    final resolvedTint =
        tintId ?? (cardBack != null ? cardBack!.name : AppStyle.cardBackTintId);
    final fill = cardBackTintById(resolvedTint).color;
    final overlay = mark ?? AppStyle.cardBackMark;
    final overlayAvatar = avatarId ?? AppStyle.cardBackAvatarId;
    final isLight = fill.computeLuminance() > 0.42;
    final edge = (isLight ? const Color(0xFF1C1612) : theme.textPrimary)
        .withValues(alpha: .18);

    final card = SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: edge, width: 1),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: .18),
                    blurRadius: (width * 0.12).clamp(4.0, 10.0),
                    offset: Offset(0, (width * 0.045).clamp(2.0, 4.0)),
                  ),
                ]
              : const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: switch (overlay) {
            CardBackMark.none => null,
            CardBackMark.logo => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.12,
                  vertical: height * 0.18,
                ),
                child: Opacity(
                  opacity: isLight ? 0.72 : 0.92,
                  child: Image.asset(
                    theme.appLogoMark,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            CardBackMark.avatar => Center(
              child: PlayerAvatarView(
                avatarId: overlayAvatar,
                size: width * 0.52,
                showBorder: false,
              ),
            ),
          },
        ),
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
