import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

enum ThemeUnlockKind { free, play, coins }

class ThemePack {
  const ThemePack({
    required this.id,
    required this.cardBack,
    required this.avatarIds,
    required this.unlock,
    this.coinCost,
    this.defaultTintId = 'sage',
  });

  final Theme id;
  final CardBack cardBack;
  final List<String> avatarIds;
  final ThemeUnlockKind unlock;
  final int? coinCost;
  final String defaultTintId;

  bool get isCoinLocked => unlock == ThemeUnlockKind.coins;
  bool get isPlayLocked => unlock == ThemeUnlockKind.play;
}

/// Base (Sage) + four Journey worlds. Worlds unlock via play, not coins.
const themePackCatalog = <ThemePack>[
  ThemePack(
    id: Theme.sage,
    cardBack: CardBack.sage,
    avatarIds: ['palm', 'leaf', 'star'],
    unlock: ThemeUnlockKind.free,
    defaultTintId: 'sage',
  ),
  ThemePack(
    id: Theme.casino,
    cardBack: CardBack.clay,
    avatarIds: ['diamond', 'acorn'],
    unlock: ThemeUnlockKind.play,
    defaultTintId: 'diamonds',
  ),
  ThemePack(
    id: Theme.dune,
    cardBack: CardBack.dune,
    avatarIds: ['club', 'leaf'],
    unlock: ThemeUnlockKind.play,
    defaultTintId: 'clubs',
  ),
  ThemePack(
    id: Theme.fig,
    cardBack: CardBack.fig,
    avatarIds: ['heart'],
    unlock: ThemeUnlockKind.play,
    defaultTintId: 'hearts',
  ),
  ThemePack(
    id: Theme.midnight,
    cardBack: CardBack.tide,
    avatarIds: ['spade', 'moon'],
    unlock: ThemeUnlockKind.play,
    defaultTintId: 'spades',
  ),
];

const defaultOwnedPacks = <Theme>{Theme.sage};

ThemePack themePack(Theme id) {
  return themePackCatalog.firstWhere((pack) => pack.id == id);
}

ThemePack? themePackForCardBack(CardBack back) {
  for (final pack in themePackCatalog) {
    if (pack.cardBack == back) return pack;
  }
  return null;
}

CardBack defaultCardBackFor(Theme theme) => themePack(theme).cardBack;

List<String> avatarsForPack(Theme id) => themePack(id).avatarIds;

/// Coin theme sales retired — worlds unlock through Journey.
List<ThemePack> coinPacksForSale(Set<Theme> owned) => const [];

List<ThemePack> playLockedPacks(Set<Theme> owned) {
  return [
    for (final pack in themePackCatalog)
      if (pack.isPlayLocked && !owned.contains(pack.id)) pack,
  ];
}

class CardBackTint {
  const CardBackTint({required this.id, required this.color, this.themes});

  final String id;
  final Color color;
  final Set<Theme>? themes;

  bool allowedFor(Theme theme) => themes == null || themes!.contains(theme);
}

const cardBackTintCatalog = <CardBackTint>[
  CardBackTint(id: 'sage', color: Color(0xFF3A634F), themes: {Theme.sage}),
  CardBackTint(id: 'forest', color: Color(0xFF2C4A3D), themes: {Theme.sage}),
  CardBackTint(id: 'sageDeep', color: Color(0xFF24382E), themes: {Theme.sage}),
  CardBackTint(id: 'moss', color: Color(0xFF3E4A38), themes: {Theme.sage}),
  CardBackTint(
    id: 'diamonds',
    color: Color(0xFF4B3046),
    themes: {Theme.casino},
  ),
  CardBackTint(id: 'violet', color: Color(0xFF3A2438), themes: {Theme.casino}),
  CardBackTint(id: 'gold', color: Color(0xFF76556F), themes: {Theme.casino}),
  // Legacy Clay aliases → Diamonds
  CardBackTint(id: 'clay', color: Color(0xFF4B3046), themes: {Theme.casino}),
  CardBackTint(
    id: 'terracotta',
    color: Color(0xFF3A2438),
    themes: {Theme.casino},
  ),
  CardBackTint(id: 'copper', color: Color(0xFF76556F), themes: {Theme.casino}),
  CardBackTint(id: 'clubs', color: Color(0xFF3E5A4E), themes: {Theme.dune}),
  CardBackTint(id: 'mossClub', color: Color(0xFF2A4038), themes: {Theme.dune}),
  CardBackTint(id: 'cream', color: Color(0xFF6F8B72), themes: {Theme.dune}),
  CardBackTint(id: 'dune', color: Color(0xFF3E5A4E), themes: {Theme.dune}),
  CardBackTint(id: 'khaki', color: Color(0xFF2A4038), themes: {Theme.dune}),
  CardBackTint(
    id: 'sandstone',
    color: Color(0xFF6F8B72),
    themes: {Theme.dune},
  ),
  CardBackTint(id: 'hearts', color: Color(0xFF68404F), themes: {Theme.fig}),
  CardBackTint(id: 'mulberry', color: Color(0xFF4A2834), themes: {Theme.fig}),
  CardBackTint(id: 'wine', color: Color(0xFF913E4E), themes: {Theme.fig}),
  CardBackTint(id: 'fig', color: Color(0xFF68404F), themes: {Theme.fig}),
  CardBackTint(id: 'spades', color: Color(0xFF293943), themes: {Theme.midnight}),
  CardBackTint(id: 'slate', color: Color(0xFF1A282E), themes: {Theme.midnight}),
  CardBackTint(id: 'steel', color: Color(0xFF4D606A), themes: {Theme.midnight}),
  CardBackTint(id: 'tide', color: Color(0xFF293943), themes: {Theme.midnight}),
  CardBackTint(id: 'reef', color: Color(0xFF1A282E), themes: {Theme.midnight}),
  CardBackTint(
    id: 'tideDeep',
    color: Color(0xFF4D606A),
    themes: {Theme.midnight},
  ),
];

const _legacyTintIds = {
  'cream': 'sage',
  'linen': 'sage',
  'white': 'copper',
  'sand': 'moss',
  'mossPaper': 'forest',
  'sageMist': 'sageDeep',
  'walnut': 'diamonds',
  'walnutDeep': 'violet',
  'walnutPaper': 'violet',
  'umber': 'diamonds',
  'coolWhite': 'slate',
  'slatePaper': 'slate',
  'casinoGold': 'gold',
  'brass': 'gold',
  'ink': 'slate',
  'ivory': 'sage',
  'navy': 'spades',
  'emerald': 'clubs',
  'midnightNavy': 'slate',
  'midnightIce': 'slate',
};

CardBackTint cardBackTintById(String id) {
  final resolved = _legacyTintIds[id] ?? id;
  return cardBackTintCatalog.firstWhere(
    (tint) => tint.id == resolved,
    orElse: () => cardBackTintCatalog.first,
  );
}

List<CardBackTint> tintsForTheme(Theme theme) {
  return [
    for (final tint in cardBackTintCatalog)
      if (tint.allowedFor(theme)) tint,
  ];
}

String coerceTintForTheme(String id, Theme theme) {
  final tint = cardBackTintById(id);
  if (tint.allowedFor(theme)) return tint.id;
  return themePack(theme).defaultTintId;
}
