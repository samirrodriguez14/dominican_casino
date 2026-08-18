import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class PlayingCardBack extends StatelessWidget {
  final double width;

  const PlayingCardBack({super.key, this.width = 44});

  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;
    final radius = (width * 0.125).clamp(6.0, 14.0);
    final fill = AppStyle.cardBackColor;
    final isLight = fill.computeLuminance() > 0.42;
    final edge = (isLight ? const Color(0xFF1C1612) : AppStyle.theme.textPrimary)
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
      ),
    );
  }
}
