import 'package:dominican_casino/models/avatar_catalog.dart';

/// On-device AI seats for local matches. Distinct names/avatars so a
/// multi-seat table is not copies of the same bot.
class LocalBotProfile {
  const LocalBotProfile({
    required this.name,
    required this.avatarId,
    this.avatarAsset,
  });

  final String name;
  final String avatarId;
  /// Optional custom image override. When null, resolved from [AvatarCatalog].
  final String? avatarAsset;

  /// Asset path for seat maps — catalog lookup when [avatarAsset] is omitted.
  String? get resolvedAvatarAsset {
    if (avatarAsset != null && avatarAsset!.isNotEmpty) return avatarAsset;
    return AvatarLook.fromId(avatarId).resolvedAssetPath;
  }
}

class LocalBotRoster {
  /// Enough unique seats for a 6-player BS table (5 bots + human).
  static const profiles = [
    LocalBotProfile(name: 'Pulilo', avatarId: 'star'),
    LocalBotProfile(name: 'Lila', avatarId: 'moon'),
    LocalBotProfile(name: 'Tico', avatarId: 'palm'),
    LocalBotProfile(name: 'Nena', avatarId: 'heart'),
    LocalBotProfile(name: 'Chago', avatarId: 'spade'),
    LocalBotProfile(name: 'Mango', avatarId: 'sun'),
    LocalBotProfile(name: 'Coco', avatarId: 'club'),
    LocalBotProfile(name: 'Yuca', avatarId: 'diamond'),
  ];

  static bool isBotName(Object? name) {
    if (name is! String || name.isEmpty) return false;
    return profiles.any((p) => p.name == name);
  }

  /// Up to [count] bots, preferring avatars not in [avoidAvatarIds].
  static List<LocalBotProfile> pick(
    int count, {
    String? avoidAvatarId,
    Set<String>? avoidAvatarIds,
  }) {
    if (count <= 0) return const [];
    final avoid = <String>{
      if (avoidAvatarId != null && avoidAvatarId.isNotEmpty) avoidAvatarId,
      ...?avoidAvatarIds,
    };
    final ordered = [...profiles];
    if (avoid.isNotEmpty) {
      ordered.sort((a, b) {
        final ac = avoid.contains(a.avatarId);
        final bc = avoid.contains(b.avatarId);
        if (ac == bc) return 0;
        return ac ? 1 : -1;
      });
    }
    if (count <= ordered.length) {
      return ordered.take(count).toList();
    }
    // Should not need more than [profiles], but cycle safely if asked.
    return [
      for (var i = 0; i < count; i++)
        ordered[i % ordered.length],
    ];
  }
}
