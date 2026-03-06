import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class PlayingCardBack extends StatelessWidget {
  final double width;
  final bool empty;

  const PlayingCardBack({super.key, this.width = 44, this.empty = false});
  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;

    return SizedBox(
      width: width,
      height: height,

      child: (!empty)
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppStyle.theme.surfaceRaised,
                  width: 1,
                ),
                image: DecorationImage(
                  image: AssetImage('assets/images/card_wood_back.png'),
                  fit: BoxFit.fill,
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppStyle.theme.surface,
                border: Border.all(
                  color: AppStyle.theme.surfaceRaised,
                  width: 1,
                ),
              ),
              child: Icon(CupertinoIcons.minus_circle_fill),
            ),
    );
  }
}
