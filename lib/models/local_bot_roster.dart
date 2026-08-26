/// On-device AI seats for local matches. Distinct names/avatars so a
/// 4-player Tres y Dos table is not four copies of Pulilo.
class LocalBotProfile {
  const LocalBotProfile({
    required this.name,
    required this.avatarId,
    this.avatarAsset,
  });

  final String name;
  final String avatarId;
  /// Optional custom image (e.g. Journey challenger art).
  final String? avatarAsset;
}

class LocalBotRoster {
  static const profiles = [
    LocalBotProfile(name: 'Pulilo', avatarId: 'star'),
    LocalBotProfile(name: 'Lila', avatarId: 'moon'),
    LocalBotProfile(name: 'Tico', avatarId: 'palm'),
  ];

  static bool isBotName(Object? name) {
    if (name is! String || name.isEmpty) return false;
    return profiles.any((p) => p.name == name);
  }

  /// Up to [count] bots, preferring avatars that are not [avoidAvatarId].
  static List<LocalBotProfile> pick(int count, {String? avoidAvatarId}) {
    final ordered = [...profiles];
    if (avoidAvatarId != null && avoidAvatarId.isNotEmpty) {
      ordered.sort((a, b) {
        final ac = a.avatarId == avoidAvatarId;
        final bc = b.avatarId == avoidAvatarId;
        if (ac == bc) return 0;
        return ac ? 1 : -1;
      });
    }
    final n = count.clamp(0, ordered.length);
    return ordered.take(n).toList();
  }
}
