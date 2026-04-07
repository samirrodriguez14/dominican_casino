import 'package:dominican_casino/models/game_state.dart';
class GamePillData {
  final String id;
  final Map<String, dynamic> playersInfo;
  final String? currentTurnPlayerId;
  final GameMode gameMode;
  final GameStatus gameStatus;
  final String? winnerId;

  GamePillData({
    required this.id,
    required this.playersInfo,
    required this.currentTurnPlayerId,
    required this.gameMode,
    required this.gameStatus,
    required this.winnerId,
  });

  factory GamePillData.fromDoc(String id, Map<String, dynamic> data) {
    return GamePillData(
      id: id,
      playersInfo: Map<String, dynamic>.from(data['playersInfo'] ?? {}),
      currentTurnPlayerId: data['currentTurnPlayerId'] as String?,
      gameMode: _parseGameMode(data['gameMode']),
      gameStatus: _parseGameStatus(data['gameStatus']),
      winnerId: data['winnerId'] as String?,
    );
  }

  factory GamePillData.fromJson(Map<String, dynamic> json) {
    return GamePillData(
      id: json['id'] as String,
      playersInfo: Map<String, dynamic>.from(json['playersInfo'] ?? {}),
      currentTurnPlayerId: json['currentTurnPlayerId'] as String?,
      gameMode: _parseGameMode(json['gameMode']),
      gameStatus: _parseGameStatus(json['gameStatus']),
      winnerId: json['winnerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playersInfo': playersInfo,
      'currentTurnPlayerId': currentTurnPlayerId,
      'gameMode': gameMode.name,
      'gameStatus': gameStatus.name,
      'winnerId': winnerId,
    };
  }

  List<String> get playerIds => playersInfo.keys.toList();

  bool containsPlayer(String pid) => playersInfo.containsKey(pid);

  bool isMyTurn(String pid) => currentTurnPlayerId == pid;

  bool didPlayerWin(String pid) => winnerId == pid;

  String? playerName(String pid) {
    final raw = playersInfo[pid];
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(raw);
    return map['name'] as String?;
  }

  List<String> get playerNames {
    return playersInfo.values.map((raw) {
      final map = Map<String, dynamic>.from(raw);
      return (map['name'] as String?) ?? 'Unknown';
    }).toList();
  }

  static GameMode _parseGameMode(dynamic raw) {
    final value = raw?.toString();
    return GameMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GameMode.casino,
    );
  }

  static GameStatus _parseGameStatus(dynamic raw) {
    final value = raw?.toString();
    return GameStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GameStatus.error,
    );
  }
}