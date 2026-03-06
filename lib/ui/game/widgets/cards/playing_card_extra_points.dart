import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlayingCardExtraPoints extends StatelessWidget {
  final double width;
  final double height;
  final int total;
  final bool me;

  const PlayingCardExtraPoints({
    super.key,
    required this.me,
    this.width = 28,
    this.height = 32,
    this.total = 0,
  });

  @override
  Widget build(BuildContext context) {
    final radius = const Radius.circular(6);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppStyle.theme.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: me ? radius : Radius.zero,
          topRight: me ? radius : Radius.zero,
          bottomLeft: me ? Radius.zero : radius,
          bottomRight: me ? Radius.zero : radius,
        ),
        border: Border.all(
          color: AppStyle.theme.border.withValues(alpha: .55),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .08),
            blurRadius: 1,
            offset: const Offset(0, -1),
            spreadRadius: -1,
          ),
        ],
        gradient: LinearGradient(
          begin: me ? Alignment.topCenter : Alignment.bottomCenter,
          end: me ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            AppStyle.theme.cardBackground.withValues(alpha: .98),
            AppStyle.theme.surfaceRaised.withValues(alpha: .92),
          ],
        ),
      ),
      child: Center(
        child: Text(
          '+$total',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppStyle.theme.suitBlack,
            letterSpacing: -.2,
          ),
        ),
      ),
    );
  }
}
