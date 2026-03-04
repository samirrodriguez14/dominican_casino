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
  static const Color surfaceRaised = Color(0xFF22324B); // slightly above surface
  static const Color surfaceDeep = Color(0xFF0B1422);   // deeper than background

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

  // ---- Alternate palette (optional skin) ----
  // #0a2463, #fb3640, #605f5e, #247ba0, #e2e2e2
  static const Color imperialBlue = Color(0xFF0A2463);
  static const Color strawberryRed = Color(0xFFFB3640);
  static const Color charcoal = Color(0xFF605F5E);
  static const Color cerulean = Color(0xFF247BA0);
  static const Color alabasterGrey = Color(0xFFE2E2E2);

  // If you want to "switch" later, you can map these into a ThemeConfig.
}

class AppStyles {
  static const double radius = 12;

  static BoxDecoration surfaceBox({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
      );

  static BoxDecoration raisedSurfaceBox({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static TextStyle title = const TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 16,
  );

  static TextStyle body = const TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
  );

  static TextStyle muted = const TextStyle(
    color: AppColors.muted,
    fontSize: 13,
  );

  static TextStyle caption = TextStyle(
    color: AppColors.muted.withOpacity(0.9),
    fontSize: 12,
  );
}
CupertinoThemeData buildCasinoCupertinoTheme() {
  return const CupertinoThemeData(
    brightness: Brightness.dark,

    // This controls filled buttons, switches, etc.
    primaryColor: AppColors.surfaceAlt,

    scaffoldBackgroundColor: AppColors.background,
    barBackgroundColor: AppColors.surface,

    // You can also set "primaryContrastingColor" if needed
    // primaryContrastingColor: AppColors.textPrimary,

    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.textPrimary,

      textStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),

      navTitleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),

      navLargeTitleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 32,
      ),

      actionTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
