import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/casino_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppStyle {
  static AppTheme theme = CasinoTheme();
}




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
  static AppTheme get theme => AppStyle.theme;

  static const double radius = 12;

  static BoxDecoration surfaceBox({Color? color}) => BoxDecoration(
    color: color ?? theme.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: theme.border),
  );

  static BoxDecoration raisedSurfaceBox({Color? color}) => BoxDecoration(
    color: color ?? theme.surfaceRaised,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: theme.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow.withOpacity(0.25),
        blurRadius: 10,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration woodenTable() => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7B4B2A), Color(0xFF5A341D)],
    ),
    border: Border.all(color: const Color(0xFF3A2314), width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.5),
        blurRadius: 20,
        offset: const Offset(0, 12),
      ),
    ],
  );

  static BoxDecoration casinoTable() => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: const RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Color.fromARGB(255, 25, 89, 54), // bright felt
        Color(0xFF134B2C), // darker edges
      ],
    ),
    border: Border.all(color: theme.surfaceAlt.withOpacity(.6), width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.45),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(.35),
        blurRadius: 6,
        spreadRadius: -4,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration premiumGameTable() => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [theme.surfaceRaised, AppColors.surfaceDeep],
    ),
    border: Border.all(color: Colors.black.withOpacity(.35), width: 3),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow.withOpacity(.5),
        blurRadius: 25,
        offset: const Offset(0, 14),
      ),
    ],
  );

  static BoxDecoration playerSectionBox({
    required Color highlightColor,
    bool highlight = false,
    bool joined = true,
  }) {
    return BoxDecoration(
      color: joined
          ? (highlight ? AppColors.background : AppColors.surface)
          : AppColors.charcoal.withOpacity(0.1),

      borderRadius: BorderRadius.circular(radius),

      border: Border.all(
        color: highlight
            ? highlightColor.withOpacity(.75)
            : AppColors.surfaceAlt.withOpacity(.55),
        width: highlight ? 2 : 1,
      ),

      boxShadow: highlight
          ? [
              BoxShadow(
                color: highlightColor.withOpacity(.25),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ]
          : [
              BoxShadow(
                color: AppColors.shadow.withOpacity(.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  static BoxDecoration tableBackground() => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.surfaceDeep, AppColors.background],
    ),
  );
  static BoxDecoration opponentAreaBox() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.muted.withOpacity(.45)),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow.withOpacity(.25),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Optional subtle vignette/glow where cards live (no borders)
  static BoxDecoration tableInsetGlow() => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: RadialGradient(
      center: Alignment.center,
      radius: 1.1,
      colors: [AppColors.surfaceAlt.withOpacity(.12), Colors.transparent],
    ),
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

CupertinoThemeData buildCupertinoTheme() {
  final t = AppStyle.theme;

  return CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: t.surfaceAlt,
    scaffoldBackgroundColor: t.background,
    barBackgroundColor: t.surface,
  );
}