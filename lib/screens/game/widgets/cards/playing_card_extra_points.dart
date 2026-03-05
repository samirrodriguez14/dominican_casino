import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class PlayingCardExtraPoints extends StatelessWidget {
  final double width;
  final double height;
  final int total;

  const PlayingCardExtraPoints({
    super.key,
    this.width = 44 / 2,
    this.height = 62,
    this.total = 0,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
        ),
        color: AppStyle.theme.surface,

        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: const Offset(0, 2),
        color: AppStyle.theme.background.withOpacity(.12),
          ),
        ],
      ),
      child: Center(child: Text('$total')),
    );
  }
}
