import 'package:dominican_casino/style/casino_theme.dart';
import 'package:dominican_casino/style/dune_theme.dart';
import 'package:dominican_casino/style/fig_theme.dart';
import 'package:dominican_casino/style/midnight_theme.dart';
import 'package:dominican_casino/style/sage_theme.dart';
import 'package:flutter/cupertino.dart';

class AppStyle {
  static AppTheme theme = SageTheme();
  static CardBack cardBack = CardBack.sage;
  static CardBackMark cardBackMark = CardBackMark.logo;
  static String cardBackTintId = 'sage';
  static String? cardBackAvatarId;

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
    // Use a brighter accent so CupertinoDialogAction (esp. non-destructive)
    // is readable on dark backgrounds.
    primaryColor: t.turnHighlight,
    scaffoldBackgroundColor: t.background,
    barBackgroundColor: t.surface,
    textTheme: CupertinoTextThemeData(
      primaryColor: t.textPrimary,
      textStyle: TextStyle(color: t.textPrimary, fontSize: 16),
    ),
  );
}

enum Theme {
  sage,
  casino,
  midnight,
  fig,
  dune,
}

enum CardBack { sage, walnut, ink, ivory, brass, clay, tide, fig, dune }

enum CardBackMark { none, logo, avatar }

extension CardBackMarkCycle on CardBackMark {
  CardBackMark get next {
    const values = CardBackMark.values;
    return values[(index + 1) % values.length];
  }
}

class CardBackStyle {
  const CardBackStyle({required this.id, required this.color});

  final CardBack id;
  final Color color;
}

const cardBackCatalog = <CardBackStyle>[
  CardBackStyle(id: CardBack.sage, color: Color(0xFF3A634F)),
  CardBackStyle(id: CardBack.walnut, color: Color(0xFF53463A)),
  CardBackStyle(id: CardBack.ink, color: Color(0xFF1A282C)),
  CardBackStyle(id: CardBack.ivory, color: Color(0xFFE8E2D6)),
  CardBackStyle(id: CardBack.brass, color: Color(0xFF7A4E3A)),
  CardBackStyle(id: CardBack.clay, color: Color(0xFF6B4336)),
  CardBackStyle(id: CardBack.tide, color: Color(0xFF3A5558)),
  CardBackStyle(id: CardBack.fig, color: Color(0xFF5A3A48)),
  CardBackStyle(id: CardBack.dune, color: Color(0xFF6A5A40)),
];

CardBackStyle cardBackStyle(CardBack id) {
  return cardBackCatalog.firstWhere((item) => item.id == id);
}

String themeLabel(Theme themeType) {
  switch (themeType) {
    case Theme.sage:
      return 'Base';
    case Theme.casino:
      return 'Diamonds';
    case Theme.midnight:
      return 'Spades';
    case Theme.fig:
      return 'Hearts';
    case Theme.dune:
      return 'Clubs';
  }
}

String cardBackLabel(CardBack id) {
  return switch (id) {
    CardBack.sage => 'Sage',
    CardBack.walnut => 'Walnut',
    CardBack.ink => 'Ink',
    CardBack.ivory => 'Ivory',
    CardBack.brass => 'Copper',
    CardBack.clay => 'Diamonds',
    CardBack.tide => 'Spades',
    CardBack.fig => 'Hearts',
    CardBack.dune => 'Clubs',
  };
}

AppTheme themeFromEnum(Theme theme) {
  switch (theme) {
    case Theme.sage:
      return SageTheme();
    case Theme.casino:
      return ClayTheme();
    case Theme.midnight:
      return TideTheme();
    case Theme.fig:
      return FigTheme();
    case Theme.dune:
      return DuneTheme();
  }
}
