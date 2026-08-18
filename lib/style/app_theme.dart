import 'package:dominican_casino/style/casino_theme.dart';
// import 'package:dominican_casino/style/casino_theme_light.dart';
// import 'package:dominican_casino/style/dominican_theme.dart';
import 'package:dominican_casino/style/felt_walnut_theme.dart';
// import 'package:dominican_casino/style/green_table_theme.dart';
import 'package:dominican_casino/style/midnight_theme.dart';
import 'package:dominican_casino/style/sage_theme.dart';
import 'package:flutter/cupertino.dart';

class AppStyle {
  static AppTheme theme = SageTheme();
  static CardBack cardBack = CardBack.sage;

  static Color get cardBackColor => cardBackStyle(cardBack).color;
}

abstract class AppTheme {
  double get radius;

  String get appLogo => 'assets/images/logo_icon_sage.png';

  /// Two-card mark with a transparent field, for placing on UI cards.
  String get appLogoMark => 'assets/images/logo_cards_transparent.png';
  // ---- Base colors ----
  Color get background;
  Color get surface;
  Color get surfaceRaised;
  Color get surfaceAlt;
  Color get textPrimary;
  Color get muted;
  Color get border;

  /// Playing-card faces in the shell (games, store, settings).
  Color get pickerFace => surfaceAlt;
  Color get pickerFaceAlt => surfaceRaised;
  Color get pickerFaceEdge => border;

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
  sage,
  casino,
  midnight,
  //  casinoLight, greenTable, dominican
}

/// Themes the player already owns (selectable in Profile).
const ownedThemes = <Theme>[Theme.sage, Theme.feltWaltnut];

enum CardBack { sage, walnut, ink, ivory, brass }

class CardBackStyle {
  const CardBackStyle({
    required this.id,
    required this.color,
    required this.owned,
    this.priceLabel,
  });

  final CardBack id;
  final Color color;
  final bool owned;
  final String? priceLabel;
}

const cardBackCatalog = <CardBackStyle>[
  CardBackStyle(
    id: CardBack.sage,
    color: Color(0xFF3A634F),
    owned: true,
  ),
  CardBackStyle(
    id: CardBack.walnut,
    color: Color(0xFF53463A),
    owned: true,
  ),
  CardBackStyle(
    id: CardBack.ink,
    color: Color(0xFF1A2220),
    owned: true,
  ),
  CardBackStyle(
    id: CardBack.ivory,
    color: Color(0xFFE8E2D6),
    owned: true,
  ),
  CardBackStyle(
    id: CardBack.brass,
    color: Color(0xFFC4B07A),
    owned: true,
  ),
];

CardBackStyle cardBackStyle(CardBack id) {
  return cardBackCatalog.firstWhere((item) => item.id == id);
}

CardBack defaultCardBackFor(Theme theme) {
  return theme == Theme.feltWaltnut ? CardBack.walnut : CardBack.sage;
}

String cardBackLabel(CardBack id) {
  return switch (id) {
    CardBack.sage => 'Sage',
    CardBack.walnut => 'Walnut',
    CardBack.ink => 'Ink',
    CardBack.ivory => 'Ivory',
    CardBack.brass => 'Brass',
  };
}

String themeLabel(Theme themeType) {
  switch (themeType) {
    case Theme.feltWaltnut:
      return 'Felt Walnut';
    case Theme.sage:
      return 'Sage';
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
    case Theme.sage:
      return SageTheme();
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
