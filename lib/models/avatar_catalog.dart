import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/journey_worlds.dart';

/// How an avatar disc is drawn.
enum AvatarKind { painted, journey }

/// First-class avatar definition (painted icon or Journey challenger face).
class AvatarDef {
  const AvatarDef.painted({
    required this.id,
    required this.paintedFallbackId,
  })  : kind = AvatarKind.painted,
        assetPath = null,
        journeyWorld = null,
        journeyRank = null;

  const AvatarDef.journey({
    required this.id,
    required this.assetPath,
    required this.paintedFallbackId,
    required this.journeyWorld,
    required this.journeyRank,
  }) : kind = AvatarKind.journey;

  final String id;
  final AvatarKind kind;
  /// Cutout PNG for Journey faces; null for painted icons.
  final String? assetPath;
  /// Painted suit/base id used for score colors / fallback glyph.
  final String paintedFallbackId;
  final JourneyWorld? journeyWorld;
  final JourneyRank? journeyRank;

  bool get isJourney => kind == AvatarKind.journey;
}

/// Resolved look for rendering / seat maps — one catalog lookup.
class AvatarLook {
  const AvatarLook({
    required this.def,
    this.assetOverride,
  });

  factory AvatarLook.fromId(String? avatarId, {String? assetOverride}) {
    return AvatarLook(
      def: AvatarCatalog.byId(avatarId),
      assetOverride: assetOverride,
    );
  }

  final AvatarDef def;
  final String? assetOverride;

  String get id => def.id;

  /// Asset to show on the disc, or null for painted glyphs.
  String? get resolvedAssetPath {
    final override = assetOverride;
    if (override != null && override.isNotEmpty) return override;
    return def.assetPath;
  }

  String get paintedFallbackId => def.paintedFallbackId;
}

/// Saved catalog of every playable avatar id.
class AvatarCatalog {
  AvatarCatalog._();

  static const defaultId = 'spade';

  static const List<String> paintedIds = [
    'sun',
    'palm',
    'heart',
    'spade',
    'diamond',
    'club',
    'moon',
    'star',
    'acorn',
    'leaf',
  ];

  /// Placeholder face for the wanderer's other half (chapter cliffhanger).
  static const otherHalfId = 'journey_other_half';

  static final Map<String, AvatarDef> _byId = () {
    final map = <String, AvatarDef>{};
    for (final id in paintedIds) {
      map[id] = AvatarDef.painted(id: id, paintedFallbackId: id);
    }
    for (final world in JourneyWorld.values) {
      for (final rank in JourneyRank.values) {
        final id = journeyAvatarId(world, rank);
        map[id] = AvatarDef.journey(
          id: id,
          assetPath:
              'assets/images/journey/avatars_transparent_challengers/'
              '${world.name}_${rank.name}.png',
          paintedFallbackId: _paintedFallbackForWorld(world),
          journeyWorld: world,
          journeyRank: rank,
        );
      }
    }
    map[otherHalfId] = const AvatarDef.painted(
      id: otherHalfId,
      paintedFallbackId: 'moon',
    );
    return map;
  }();

  static List<AvatarDef> get all => List.unmodifiable(_byId.values);

  static List<AvatarDef> get journeyAll =>
      all.where((d) => d.isJourney).toList(growable: false);

  static AvatarDef byId(String? id) {
    if (id == null || id.isEmpty) return _byId[defaultId]!;
    return _byId[id] ?? _byId[defaultId]!;
  }

  static bool contains(String? id) =>
      id != null && id.isNotEmpty && _byId.containsKey(id);
}

String _paintedFallbackForWorld(JourneyWorld world) => switch (world) {
  JourneyWorld.diamonds => 'diamond',
  JourneyWorld.clubs => 'club',
  JourneyWorld.hearts => 'heart',
  JourneyWorld.spades => 'spade',
};

/// Stable id for a Journey face cutout used as a player avatar.
String journeyAvatarId(JourneyWorld world, JourneyRank rank) =>
    'journey_${world.name}_${rank.name}';

/// Asset path for a catalog Journey avatar id, or null if not a Journey id.
///
/// Prefer [AvatarLook.fromId] / [AvatarCatalog.byId]; kept for call-site
/// migration.
String? journeyAvatarAssetPath(String? avatarId) {
  final def = AvatarCatalog.byId(avatarId);
  if (!def.isJourney || def.id != avatarId) return null;
  return def.assetPath;
}

/// Painted suit/base id used for colors when [avatarId] is a Journey face.
String paintedAvatarIdFor(String? avatarId) =>
    AvatarCatalog.byId(avatarId).paintedFallbackId;
