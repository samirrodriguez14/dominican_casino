class Player {
  String id;
  int playerNum;
  String? name;
  String? token;
  Player({required this.id, this.name, this.token,this.playerNum =0});
  factory Player.fromDto(Map<String, dynamic> playerDto) {
    return Player(id: playerDto['id'], name: playerDto['name'] ?? '', token: playerDto['token']);
  }
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'token':token};
}
