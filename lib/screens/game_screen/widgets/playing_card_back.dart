import 'package:dominican_casino/style/theme_data.dart';
import 'package:flutter/cupertino.dart';

class PlayingCardBack extends StatelessWidget {
  final double width;
  final double height;
  final bool empty;

  const PlayingCardBack({
    super.key,
    this.width = 44,
    this.height = 62,
    this.empty = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: empty? AppColors.background.withOpacity(0.7): AppColors.surfaceAlt.withOpacity(.7),
        border: Border.all(
          color: AppColors.surfaceAlt.withOpacity(.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: const Offset(0, 2),
            color: AppColors.background.withOpacity(.12),
          ),
        ],
      ),
      child: (!empty)
          ? Container(
              decoration: AppStyles.surfaceBox().copyWith(
                image: DecorationImage(
                  image: AssetImage('assets/images/logo_card.png'),
                  fit: BoxFit.fitHeight,
                ),
              ),
            )
          : Icon(CupertinoIcons.minus_circle_fill),
    );
  }
}
