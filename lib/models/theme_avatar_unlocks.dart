import 'package:dominican_casino/models/avatar_catalog.dart';
import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';

export 'package:dominican_casino/models/avatar_catalog.dart'
    show
        AvatarCatalog,
        AvatarDef,
        AvatarKind,
        AvatarLook,
        journeyAvatarAssetPath,
        journeyAvatarId,
        paintedAvatarIdFor;

/// Painted avatar unlocked when the player reaches [requiredLevel].
class LevelAvatarExtra {
  const LevelAvatarExtra({
    required this.avatarId,
    required this.requiredLevel,
  });

  final String avatarId;
  final int requiredLevel;
}

/// Per-theme avatar unlock rules (starter + level extras + optional Journey faces).
class ThemeAvatarUnlocks {
  const ThemeAvatarUnlocks({
    required this.starterAvatarId,
    this.levelExtras = const [],
    this.journeyWorld,
  });

  final String starterAvatarId;
  final List<LevelAvatarExtra> levelExtras;
  final JourneyWorld? journeyWorld;

  /// All avatar ids that can ever belong to this pack (catalog order).
  List<String> get allAvatarIds => [
    starterAvatarId,
    for (final extra in levelExtras) extra.avatarId,
    if (journeyWorld != null)
      for (final rank in JourneyRank.values)
        journeyAvatarId(journeyWorld!, rank),
  ];
}

const themeAvatarUnlockCatalog = <Theme, ThemeAvatarUnlocks>{
  Theme.sage: ThemeAvatarUnlocks(
    starterAvatarId: 'palm',
    levelExtras: [
      LevelAvatarExtra(avatarId: 'leaf', requiredLevel: 5),
      LevelAvatarExtra(avatarId: 'star', requiredLevel: 10),
    ],
  ),
  Theme.casino: ThemeAvatarUnlocks(
    starterAvatarId: 'diamond',
    levelExtras: [
      LevelAvatarExtra(avatarId: 'acorn', requiredLevel: 5),
    ],
    journeyWorld: JourneyWorld.diamonds,
  ),
  Theme.dune: ThemeAvatarUnlocks(
    starterAvatarId: 'club',
    levelExtras: [
      LevelAvatarExtra(avatarId: 'leaf', requiredLevel: 10),
    ],
    journeyWorld: JourneyWorld.clubs,
  ),
  Theme.fig: ThemeAvatarUnlocks(
    starterAvatarId: 'heart',
    levelExtras: [
      LevelAvatarExtra(avatarId: 'sun', requiredLevel: 15),
    ],
    journeyWorld: JourneyWorld.hearts,
  ),
  Theme.midnight: ThemeAvatarUnlocks(
    starterAvatarId: 'spade',
    levelExtras: [
      LevelAvatarExtra(avatarId: 'moon', requiredLevel: 20),
    ],
    journeyWorld: JourneyWorld.spades,
  ),
};

ThemeAvatarUnlocks themeAvatarUnlocks(Theme id) {
  return themeAvatarUnlockCatalog[id] ??
      themeAvatarUnlockCatalog[Theme.sage]!;
}

/// Whether [rank] is recorded as defeated in [defeatedByWorld].
bool _isDefeated(
  Map<String, List<String>> defeatedByWorld,
  JourneyWorld world,
  JourneyRank rank,
) {
  final list = defeatedByWorld[world.name];
  if (list == null) return false;
  return list.contains(rank.name);
}

/// Unlocked avatar ids for [theme], in catalog order.
List<String> unlockedAvatarIdsForPack(
  Theme theme, {
  required int level,
  Map<String, List<String>> defeatedByWorld = const {},
}) {
  final rules = themeAvatarUnlocks(theme);
  final out = <String>[rules.starterAvatarId];
  for (final extra in rules.levelExtras) {
    if (level >= extra.requiredLevel) out.add(extra.avatarId);
  }
  final world = rules.journeyWorld;
  if (world != null) {
    for (final rank in JourneyRank.values) {
      if (_isDefeated(defeatedByWorld, world, rank)) {
        out.add(journeyAvatarId(world, rank));
      }
    }
  }
  return out;
}

/// Still-locked avatar ids for [theme], in catalog order.
List<String> lockedAvatarIdsForPack(
  Theme theme, {
  required int level,
  Map<String, List<String>> defeatedByWorld = const {},
}) {
  final rules = themeAvatarUnlocks(theme);
  final unlocked = unlockedAvatarIdsForPack(
    theme,
    level: level,
    defeatedByWorld: defeatedByWorld,
  ).toSet();
  return [
    for (final id in rules.allAvatarIds)
      if (!unlocked.contains(id)) id,
  ];
}

/// True when any Journey face for this pack is still locked.
bool hasLockedJourneyAvatars(
  Theme theme, {
  required int level,
  Map<String, List<String>> defeatedByWorld = const {},
}) {
  final world = themeAvatarUnlocks(theme).journeyWorld;
  if (world == null) return false;
  final locked = lockedAvatarIdsForPack(
    theme,
    level: level,
    defeatedByWorld: defeatedByWorld,
  );
  return locked.any((id) => AvatarCatalog.byId(id).isJourney);
}

/// Lowest level still required for a locked painted extra, or null.
int? nextLevelAvatarUnlock(
  Theme theme, {
  required int level,
}) {
  final rules = themeAvatarUnlocks(theme);
  int? next;
  for (final extra in rules.levelExtras) {
    if (level >= extra.requiredLevel) continue;
    if (next == null || extra.requiredLevel < next) {
      next = extra.requiredLevel;
    }
  }
  return next;
}
