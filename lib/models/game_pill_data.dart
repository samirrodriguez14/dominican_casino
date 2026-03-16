import 'package:dominican_casino/models/game_state.dart';

class GamePillData {
  final String id;
  final String? currentTurnPlayerId;
  final Map<String, dynamic> playersInfo;
  final GameMode gameMode;

  GamePillData({
    required this.id,
    required this.playersInfo,
    required this.currentTurnPlayerId,
    required this.gameMode,
  });

  factory GamePillData.fromDoc(String id, Map<String, dynamic> data) {
    return GamePillData(
      id: id,
      currentTurnPlayerId: data['currentTurnPlayerId'] as String?,
      playersInfo: Map<String, dynamic>.from(data['playersInfo'] ?? {}),
      gameMode: gameModeFrom(data['gameMode'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currentTurnPlayerId': currentTurnPlayerId,
      'playersInfo': playersInfo,
      'gameMode': gameMode,
    };
  }

  bool containsPlayer(String pid) => playersInfo.containsKey(pid);

  bool isMyTurn(String pid) => currentTurnPlayerId == pid;

  List<Map<String, dynamic>> get players {
    return playersInfo.values.map((p) => Map<String, dynamic>.from(p)).toList();
  }

  List<String> get playerNames {
    return players.map((p) => (p['name'] as String?) ?? 'Unknown').toList();
  }
}
