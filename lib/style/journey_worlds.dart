import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Journey world identity + palette tokens (aligned with AppTheme packs).
class JourneyWorldPalette {
  const JourneyWorldPalette({
    required this.background,
    required this.surface,
    required this.accent,
    required this.accentSecondary,
    required this.text,
    required this.suitSymbol,
    required this.cardBorder,
  });

  final Color background;
  final Color surface;
  final Color accent;
  final Color accentSecondary;
  final Color text;
  final Color suitSymbol;
  final Color cardBorder;
}

/// Four suit worlds in Journey progression order.
enum JourneyWorld {
  diamonds,
  clubs,
  hearts,
  spades;

  String get label => switch (this) {
    JourneyWorld.diamonds => 'Diamonds',
    JourneyWorld.clubs => 'Clubs',
    JourneyWorld.hearts => 'Hearts',
    JourneyWorld.spades => 'Spades',
  };

  String get suitSymbol => switch (this) {
    JourneyWorld.diamonds => '♦',
    JourneyWorld.clubs => '♣',
    JourneyWorld.hearts => '♥',
    JourneyWorld.spades => '♠',
  };

  /// Full Ace challenger card art used as Journey trophy ornaments.
  String get aceCardAssetPath =>
      'assets/images/journey/cards_challengers/${name}_ace.png';

  /// Persisted [Theme] enum for this world (catalog remap).
  Theme get themeId => switch (this) {
    JourneyWorld.diamonds => Theme.casino,
    JourneyWorld.clubs => Theme.dune,
    JourneyWorld.hearts => Theme.fig,
    JourneyWorld.spades => Theme.midnight,
  };

  /// Player level required before this kingdom can unlock.
  int get requiredLevel => switch (this) {
    JourneyWorld.diamonds => 1,
    JourneyWorld.clubs => 5,
    JourneyWorld.hearts => 10,
    JourneyWorld.spades => 15,
  };
}

/// Kingdom that becomes level-eligible at exactly [level], if any.
JourneyWorld? journeyWorldUnlockedAtLevel(int level) {
  for (final world in JourneyWorld.values) {
    if (world.requiredLevel == level) return world;
  }
  return null;
}

JourneyWorld? journeyWorldForTheme(Theme theme) {
  return switch (theme) {
    Theme.casino => JourneyWorld.diamonds,
    Theme.dune => JourneyWorld.clubs,
    Theme.fig => JourneyWorld.hearts,
    Theme.midnight => JourneyWorld.spades,
    Theme.sage => null,
  };
}

JourneyWorldPalette journeyPaletteFor(JourneyWorld world) {
  return switch (world) {
    JourneyWorld.diamonds => const JourneyWorldPalette(
      background: Color(0xFF1D141D),
      surface: Color(0xFF4B3046),
      accent: Color(0xFFC9A568),
      accentSecondary: Color(0xFF76556F),
      text: Color(0xFFF4EEE5),
      suitSymbol: Color(0xFFC9A568),
      cardBorder: Color(0xFF76556F),
    ),
    JourneyWorld.clubs => const JourneyWorldPalette(
      background: Color(0xFF111D19),
      surface: Color(0xFF3E5A4E),
      accent: Color(0xFFD4C59A),
      accentSecondary: Color(0xFF6F8B72),
      text: Color(0xFFF1EFE5),
      suitSymbol: Color(0xFFD4C59A),
      cardBorder: Color(0xFF6F8B72),
    ),
    JourneyWorld.hearts => const JourneyWorldPalette(
      background: Color(0xFF211417),
      surface: Color(0xFF68404F),
      accent: Color(0xFFD7A19E),
      accentSecondary: Color(0xFF913E4E),
      text: Color(0xFFF5ECE8),
      suitSymbol: Color(0xFFD7A19E),
      cardBorder: Color(0xFF913E4E),
    ),
    JourneyWorld.spades => const JourneyWorldPalette(
      background: Color(0xFF10171C),
      surface: Color(0xFF293943),
      accent: Color(0xFFAEB9BD),
      accentSecondary: Color(0xFF4D606A),
      text: Color(0xFFEEF0EE),
      suitSymbol: Color(0xFFAEB9BD),
      cardBorder: Color(0xFF4D606A),
    ),
  };
}
