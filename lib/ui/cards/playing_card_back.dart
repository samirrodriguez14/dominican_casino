import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class PlayingCardBack extends StatelessWidget {
  final double width;

  const PlayingCardBack({super.key, this.width = 44});

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final height = width * 1.4;
    final radius = (width * 0.125).clamp(6.0, 14.0);
    final fill = AppStyle.cardBackColor;
    final isLight = fill.computeLuminance() > 0.42;
    final edge = (isLight ? const Color(0xFF1C1612) : theme.textPrimary)
        .withValues(alpha: .14);

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: edge, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: isLight
              ? null
              : Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.12,
                      vertical: height * 0.18,
                    ),
                    child: Opacity(
                      opacity: 0.92,
                      child: Image.asset(
                        theme.appLogoMark,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
