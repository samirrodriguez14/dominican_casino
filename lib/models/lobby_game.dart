class LobbyGame {
  final String id;
  final String? player1;
  final String? player2;

  LobbyGame({required this.id, this.player1, this.player2});

  factory LobbyGame.fromDoc(String id, Map<String, dynamic> data) {
    return LobbyGame(
      id: id,
      player1: data['player1'] as String?,
      player2: data['player2'] as String?,
    );
  }
}