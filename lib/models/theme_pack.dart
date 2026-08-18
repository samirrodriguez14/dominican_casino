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

const themePackCatalog = <ThemePack>[
  ThemePack(
    id: Theme.sage,
    cardBack: CardBack.sage,
    avatarIds: ['palm', 'leaf', 'club', 'star'],
    unlock: ThemeUnlockKind.free,
    defaultTintId: 'sage',
  ),
  ThemePack(
    id: Theme.casino,
    cardBack: CardBack.clay,
    avatarIds: ['acorn', 'diamond'],
    unlock: ThemeUnlockKind.coins,
    coinCost: 400,
    defaultTintId: 'clay',
  ),
  ThemePack(
    id: Theme.midnight,
    cardBack: CardBack.tide,
    avatarIds: ['moon', 'spade'],
    unlock: ThemeUnlockKind.coins,
    coinCost: 600,
    defaultTintId: 'tide',
  ),
  ThemePack(
    id: Theme.fig,
    cardBack: CardBack.fig,
    avatarIds: ['heart'],
    unlock: ThemeUnlockKind.coins,
    coinCost: 500,
    defaultTintId: 'fig',
  ),
  ThemePack(
    id: Theme.dune,
    cardBack: CardBack.dune,
    avatarIds: ['sun'],
    unlock: ThemeUnlockKind.coins,
    coinCost: 500,
    defaultTintId: 'dune',
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

List<ThemePack> coinPacksForSale(Set<Theme> owned) {
  return [
    for (final pack in themePackCatalog)
      if (pack.isCoinLocked && !owned.contains(pack.id)) pack,
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
  CardBackTint(id: 'clay', color: Color(0xFF6B4336), themes: {Theme.casino}),
  CardBackTint(
    id: 'terracotta',
    color: Color(0xFF5A342C),
    themes: {Theme.casino},
  ),
  CardBackTint(id: 'copper', color: Color(0xFF7A4E3A), themes: {Theme.casino}),
  CardBackTint(id: 'tide', color: Color(0xFF3A5558), themes: {Theme.midnight}),
  CardBackTint(id: 'reef', color: Color(0xFF2C4448), themes: {Theme.midnight}),
  CardBackTint(
    id: 'tideDeep',
    color: Color(0xFF1A282C),
    themes: {Theme.midnight},
  ),
  CardBackTint(id: 'fig', color: Color(0xFF5A3A48), themes: {Theme.fig}),
  CardBackTint(id: 'mulberry', color: Color(0xFF4A2E3A), themes: {Theme.fig}),
  CardBackTint(id: 'wine', color: Color(0xFF3A242C), themes: {Theme.fig}),
  CardBackTint(id: 'dune', color: Color(0xFF6A5A40), themes: {Theme.dune}),
  CardBackTint(id: 'khaki', color: Color(0xFF5A4C34), themes: {Theme.dune}),
  CardBackTint(id: 'sandstone', color: Color(0xFF4A4030), themes: {Theme.dune}),
];

const _legacyTintIds = {
  'cream': 'sage',
  'linen': 'sage',
  'white': 'copper',
  'sand': 'moss',
  'mossPaper': 'forest',
  'sageMist': 'sageDeep',
  'walnut': 'clay',
  'walnutDeep': 'terracotta',
  'walnutPaper': 'terracotta',
  'umber': 'clay',
  'coolWhite': 'tideDeep',
  'slatePaper': 'reef',
  'casinoGold': 'copper',
  'brass': 'copper',
  'ink': 'tideDeep',
  'ivory': 'sage',
  'navy': 'tide',
  'slate': 'reef',
  'emerald': 'terracotta',
  'midnightNavy': 'tideDeep',
  'midnightIce': 'tideDeep',
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
