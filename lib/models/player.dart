class Player {
  static const String defaultAvatarId = 'spade';

  String id;
  bool completedTutorial;
  bool completedJourneyTutorial;
  bool completedProfileTutorial;
  String? name;
  String? token;
  String? avatarId;
  int xp;
  Player({
    required this.id,
    this.name,
    this.token,
    this.avatarId = defaultAvatarId,
    this.completedTutorial = false,
    this.completedJourneyTutorial = false,
    this.completedProfileTutorial = false,
    this.xp = 0,
  });
  factory Player.fromDto(Map<String, dynamic> playerDto) {
    return Player(
      id: playerDto['id'],
      name: playerDto['name'] ?? '',
      token: playerDto['token'],
      avatarId: playerDto['avatarId'] as String? ?? defaultAvatarId,
      completedTutorial: playerDto['completedTutorial'] ?? false,
      completedJourneyTutorial:
          playerDto['completedJourneyTutorial'] ?? false,
      completedProfileTutorial:
          playerDto['completedProfileTutorial'] ?? false,
      xp: (playerDto['xp'] as num?)?.toInt() ?? 0,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'token': token,
    'avatarId': avatarId,
    'completedTutorial': completedTutorial,
    'completedJourneyTutorial': completedJourneyTutorial,
    'completedProfileTutorial': completedProfileTutorial,
    'xp': xp,
  };

  /// Seat snapshot stored on a game document (no auth/token fields).
  /// Omit nulls — Firestore rejects them on `set()`.
  Map<String, dynamic> toGameSeat() => {
    'id': id,
    'name': ?name,
    'avatarId': ?avatarId,
  };

  Player copyWith({
    String? id,
    bool? completedTutorial,
    bool? completedJourneyTutorial,
    bool? completedProfileTutorial,
    String? name,
    String? token,
    String? avatarId,
    int? xp,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      token: token ?? this.token,
      avatarId: avatarId ?? this.avatarId,
      completedTutorial: completedTutorial ?? this.completedTutorial,
      completedJourneyTutorial:
          completedJourneyTutorial ?? this.completedJourneyTutorial,
      completedProfileTutorial:
          completedProfileTutorial ?? this.completedProfileTutorial,
      xp: xp ?? this.xp,
    );
  }

  /// True until the player picks a display name (generated ids look like `p_a1b2c3d4`).
  bool get needsAccountSetup {
    final n = name?.trim();
    if (n == null || n.isEmpty) return true;
    return n.startsWith('p_') && n.length <= 12;
  }
}
