import 'package:dominican_casino/style/casino_theme.dart';
import 'package:flutter/cupertino.dart';

class AppStyle {
  static AppTheme theme = CasinoTheme();
}

abstract class AppTheme {
  double get radius;

  // ---- Base colors ----
  Color get background;
  Color get surface;
  Color get surfaceRaised;
  Color get surfaceAlt;
  Color get textPrimary;
  Color get muted;
  Color get border;

  // ---- Game / Card accents (NEW) ----
  Color get turnHighlight;        // used for current-turn outline/glow
  Color get opponentHighlight;    // optional: opponent turn
  Color get danger;               // delete / errors
  Color get warning;              // warnings / “confirm”
  Color get success;              // success states (can equal turnHighlight)

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
}


CupertinoThemeData buildCupertinoTheme() {
  final t = AppStyle.theme;
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