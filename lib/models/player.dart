class Player {
  String id;
  String? name;
  Player({required this.id, this.name});
  factory Player.fromDto(Map<String, dynamic> playerDto) {
    return Player(id: playerDto['id'], name: playerDto['name'] ?? '');
  }
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
