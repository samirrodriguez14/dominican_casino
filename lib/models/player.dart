class Player {
  String id;
  bool completedTutorial;
  String? name;
  String? token;
  Player({
    required this.id,
    this.name,
    this.token,
    this.completedTutorial = false,
  });
  factory Player.fromDto(Map<String, dynamic> playerDto) {
    return Player(
      id: playerDto['id'],
      name: playerDto['name'] ?? '',
      token: playerDto['token'],
      completedTutorial: playerDto['completedTutorial'] ?? false,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'token': token,
    'completedTutorial': completedTutorial,
  };

  Player copyWith({
    String? id,
    bool? completedTutorial,
    String? name,
    String? token,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      token: token ?? this.token,
      completedTutorial: completedTutorial ?? this.completedTutorial,
    );
  }
}
