import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class PlayingCardBack extends StatelessWidget {
  final double width;

  const PlayingCardBack({super.key, this.width = 44});
  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;
    final radius = (width * 0.125).clamp(6.0, 14.0);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppStyle.theme.surfaceRaised, width: 1),
          image: DecorationImage(
            image: ResizeImage(
              AssetImage(AppStyle.theme.cardBack),
              width: (width * dpr).round(),
              height: (height * dpr).round(),
            ),
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
