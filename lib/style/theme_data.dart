import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/casino_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



class AppColors {
  // ---- Base (current) palette ----
  static const Color background = Color(0xFF0D1B2A);
  static const Color surface = Color(0xFF1B263B);
  static const Color surfaceAlt = Color(0xFF415A77);
  static const Color muted = Color(0xFF778DA9);
  static const Color textPrimary = Color(0xFFE0E1DD);

  // ---- Accents ----
  static const Color accentRed = Color(0xFFC1121F);
  static const Color accentGreen = Color(0xFF2ECC71); // ✅ not null
  static const Color accentAmber = Color(0xFFFFC857);

  // ---- Extra surfaces / states ----
  static const Color surfaceRaised = Color(
    0xFF22324B,
  ); // slightly above surface
  static const Color surfaceDeep = Color(0xFF0B1422); // deeper than background

  static Color border = surfaceAlt.withOpacity(0.55);
  static Color separator = muted.withOpacity(0.25);

  static Color disabledBg = surface.withOpacity(0.65);
  static Color disabledFg = muted.withOpacity(0.65);

  // For buttons that should pop
  static const Color primaryAction = surfaceAlt; // default action background
  static const Color primaryActionText = textPrimary;

  // ---- Shadows ----
  static const Color shadow = Color(0xFF000000);

  // ---- Card specific ----
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFCCCCCC);

  // ---- Suit colors ----
  static const Color suitRed = accentRed;
  static const Color suitBlack = Color(0xFF000000);


}
CupertinoThemeData buildCupertinoTheme() {
  final t = AppStyle.theme;

  return CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: t.surfaceAlt,
    scaffoldBackgroundColor: t.background,
    barBackgroundColor: t.surface,
  );
}