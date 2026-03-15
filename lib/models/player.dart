class Player {
  String id;
  int playerNum;
  String? name;
  Player({required this.id, this.name, this.playerNum =0});
  factory Player.fromDto(Map<String, dynamic> playerDto) {
    return Player(id: playerDto['id'], name: playerDto['name'] ?? '');
  }
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
