import 'package:flutter/cupertino.dart';

/// Compact Apple logo for auth buttons.
class AppleMark extends StatelessWidget {
  const AppleMark({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '\uF8FF',
      style: TextStyle(
        fontSize: size,
        height: 1,
        color: color ?? CupertinoTheme.of(context).textTheme.textStyle.color,
        fontFamily: '.AppleSystemUIFont',
      ),
    );
  }
}
