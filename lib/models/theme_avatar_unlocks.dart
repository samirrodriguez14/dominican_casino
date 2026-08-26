import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';

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

/// Stable id for a Journey face cutout used as a player avatar.
String journeyAvatarId(JourneyWorld world, JourneyRank rank) =>
    'journey_${world.name}_${rank.name}';

/// Asset path for a `journey_{world}_{rank}` avatar id, or null if not a Journey id.
String? journeyAvatarAssetPath(String? avatarId) {
  if (avatarId == null || !avatarId.startsWith('journey_')) return null;
  final rest = avatarId.substring('journey_'.length);
  final parts = rest.split('_');
  if (parts.length != 2) return null;
  final worldName = parts[0];
  final rankName = parts[1];
  var valid = false;
  for (final w in JourneyWorld.values) {
    if (w.name == worldName) {
      valid = true;
      break;
    }
  }
  if (!valid) return null;
  valid = false;
  for (final r in JourneyRank.values) {
    if (r.name == rankName) {
      valid = true;
      break;
    }
  }
  if (!valid) return null;
  return 'assets/images/journey/avatars_transparent_challengers/$rest.png';
}

/// Painted suit/base id used for colors when [avatarId] is a Journey face.
String paintedAvatarIdFor(String? avatarId) {
  if (avatarId == null || avatarId.isEmpty) return 'spade';
  final asset = journeyAvatarAssetPath(avatarId);
  if (asset == null) return avatarId;
  final worldName = avatarId.substring('journey_'.length).split('_').first;
  return switch (worldName) {
    'diamonds' => 'diamond',
    'clubs' => 'club',
    'hearts' => 'heart',
    'spades' => 'spade',
    _ => 'spade',
  };
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
  return locked.any((id) => id.startsWith('journey_'));
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
