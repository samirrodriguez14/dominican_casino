import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class PlayingCardBack extends StatelessWidget {
  final double width;

  const PlayingCardBack({super.key, this.width = 44});
  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;

    return SizedBox(
      width: width,
      height: height,

      child: 
          Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppStyle.theme.surfaceRaised,
                  width: 1,
                ),
                image: DecorationImage(
                  image: AssetImage(AppStyle.theme.cardBack),
                  fit: BoxFit.fill,
                ),
              ),
            )
          
    );
  }
}
