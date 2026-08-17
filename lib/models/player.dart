class Player {
  String id;
  bool completedTutorial;
  String? name;
  String? token;
  String? avatarId;
  Player({
    required this.id,
    this.name,
    this.token,
    this.avatarId,
    this.completedTutorial = false,
  });
  factory Player.fromDto(Map<String, dynamic> playerDto) {
    return Player(
      id: playerDto['id'],
      name: playerDto['name'] ?? '',
      token: playerDto['token'],
      avatarId: playerDto['avatarId'] as String?,
      completedTutorial: playerDto['completedTutorial'] ?? false,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'token': token,
    'avatarId': avatarId,
    'completedTutorial': completedTutorial,
  };

  Player copyWith({
    String? id,
    bool? completedTutorial,
    String? name,
    String? token,
    String? avatarId,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      token: token ?? this.token,
      avatarId: avatarId ?? this.avatarId,
      completedTutorial: completedTutorial ?? this.completedTutorial,
    );
  }

  /// True until the player picks a display name (generated ids look like `p_a1b2c3d4`).
  bool get needsAccountSetup {
    final n = name?.trim();
    if (n == null || n.isEmpty) return true;
    return n.startsWith('p_') && n.length <= 12;
  }
}
