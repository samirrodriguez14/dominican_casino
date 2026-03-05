import 'dart:ui';

import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class CasinoTheme extends AppTheme {
  @override
  double get radius => 12;

  @override
  Color get background => const Color(0xFF0D1B2A);

  @override
  Color get surface => const Color(0xFF1B263B);

  @override
  Color get surfaceRaised => const Color(0xFF22324B);

  @override
  Color get surfaceAlt => const Color(0xFF415A77);

  @override
  Color get textPrimary => const Color(0xFFE0E1DD);

  @override
  Color get muted => const Color(0xFF778DA9);

  @override
  Color get border => surfaceAlt.withOpacity(.55);

  @override
  BoxDecoration surfaceBox() {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
    );
  }

  @override
  BoxDecoration raisedSurfaceBox() {
    return BoxDecoration(
      color: surfaceRaised,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: CupertinoColors.black.withOpacity(.25),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  @override
  BoxDecoration tableBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color(0xFF0B1422),
          background,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  @override
  BoxDecoration playerSectionBox({
    required Color highlightColor,
    bool highlight = false,
    bool joined = true,
  }) {
    return BoxDecoration(
      color: joined ? surface : CupertinoColors.black.withOpacity(.15),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlight ? highlightColor : border,
        width: highlight ? 2 : 1,
      ),
    );
  }

  @override
  TextStyle get title =>
      TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16);

  @override
  TextStyle get body => TextStyle(color: textPrimary, fontSize: 14);

  @override
  TextStyle get mutedText => TextStyle(color: muted, fontSize: 13);

  @override
  TextStyle get caption =>
      TextStyle(color: muted.withOpacity(.9), fontSize: 12);
}