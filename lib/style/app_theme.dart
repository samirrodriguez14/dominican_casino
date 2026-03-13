import 'package:dominican_casino/style/casino_theme.dart';
// import 'package:dominican_casino/style/casino_theme_light.dart';
// import 'package:dominican_casino/style/dominican_theme.dart';
import 'package:dominican_casino/style/felt_walnut_theme.dart';
// import 'package:dominican_casino/style/green_table_theme.dart';
import 'package:dominican_casino/style/midnight_theme.dart';
import 'package:flutter/cupertino.dart';

class AppStyle {
  static AppTheme theme = CasinoTheme();
}

abstract class AppTheme {
  double get radius;

  String get cardBack;
  String get appLogo;
  // ---- Base colors ----
  Color get background;
  Color get surface;
  Color get surfaceRaised;
  Color get surfaceAlt;
  Color get textPrimary;
  Color get muted;
  Color get border;

  // ---- Game / Card accents (NEW) ----
  Color get turnHighlight; // used for current-turn outline/glow
  Color get opponentHighlight; // optional: opponent turn
  Color get danger; // delete / errors
  Color get warning; // warnings / “confirm”
  Color get success; // success states (can equal turnHighlight)

  // Cards (optional but super useful across themes)
  Color get cardBackground;
  Color get cardBorder;
  Color get suitRed;
  Color get suitBlack;

  // ---- Decorations ----
  BoxDecoration surfaceBox({Color? color});
  BoxDecoration raisedSurfaceBox({Color? color});
  BoxDecoration tableBackground();

  BoxDecoration playerSectionBox({
    Color? highlightColor, // if null, defaults to theme.turnHighlight
    bool highlight = false,
    bool joined = true,
  });

  // ---- Text ----
  TextStyle get title;
  TextStyle get body;
  TextStyle get mutedText;
  TextStyle get caption;

  Widget dottedBox({
    required Widget child,
    Color? color,
    EdgeInsets padding = const EdgeInsets.all(12),
  });
}

CupertinoThemeData buildCupertinoTheme(AppTheme theme) {
  final t = theme;
  return CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: t.surfaceAlt,
    scaffoldBackgroundColor: t.background,
    barBackgroundColor: t.surface,
    textTheme: CupertinoTextThemeData(
      primaryColor: t.textPrimary,
      textStyle: TextStyle(color: t.textPrimary, fontSize: 16),
    ),
  );
}

enum Theme {
  feltWaltnut,
  casino,
  midnight,
  //  casinoLight, greenTable, dominican
}

enum Cardtheme { blue, dark, wood }

String themeLabel(Theme themeType) {
  switch (themeType) {
    case Theme.feltWaltnut:
      return 'Felt Walnut';

    case Theme.casino:
      return 'Casino';
    case Theme.midnight:
      return 'Midnight';
    // case Theme.dominican:
    //   return 'Dominican';
    // case Theme.casinoLight:
    //   return 'Casino Light';
    // case Theme.greenTable:
    //   return 'Green Light';
  }
}

AppTheme themeFromEnum(Theme theme) {
  switch (theme) {
    case Theme.feltWaltnut:
      return FeltWalnutTheme();
    case Theme.casino:
      return CasinoTheme();
    case Theme.midnight:
      return MidnightNeonTheme();
    // case Theme.dominican:
    //   return DominicanTheme();
    // case Theme.casinoLight:
    //   return LightCasinoTheme();
    // case Theme.greenTable:
    //   return GreenTableTheme();
  }
}
