import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/game_state.dart';

class GamePillSeat {
  final String id;
  final String name;
  final String? avatarId;

  const GamePillSeat({
    required this.id,
    required this.name,
    this.avatarId,
  });

  bool get isOpen =>
      name.isEmpty ||
      name == 'Open' ||
      name == 'Waiting...' ||
      name == 'Unknown';
}

class GamePillData {
  final String id;
  final Map<String, dynamic> playersInfo;
  final String? currentTurnPlayerId;
  final GameMode gameMode;
  final GameStatus gameStatus;
  final String? winnerId;
  final DateTime? updatedAt;

  GamePillData({
    required this.id,
    required this.playersInfo,
    required this.currentTurnPlayerId,
    required this.gameMode,
    required this.gameStatus,
    required this.winnerId,
    this.updatedAt,
  });

  factory GamePillData.fromDoc(String id, Map<String, dynamic> data) {
    return GamePillData(
      id: id,
      playersInfo: Map<String, dynamic>.from(data['playersInfo'] ?? {}),
      currentTurnPlayerId: data['currentTurnPlayerId'] as String?,
      gameMode: _parseGameMode(data['gameMode']),
      gameStatus: _parseGameStatus(data['gameStatus']),
      winnerId: data['winnerId'] as String?,
      updatedAt: parseUpdatedAt(data['updatedAt']),
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
      updatedAt: parseUpdatedAt(json['updatedAt']),
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
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  List<String> get playerIds => playersInfo.keys.toList();

  List<GamePillSeat> get seats {
    return playersInfo.entries.map((entry) {
      final raw = entry.value;
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      return GamePillSeat(
        id: entry.key,
        name: (map['name'] as String?) ?? 'Unknown',
        avatarId: map['avatarId'] as String?,
      );
    }).toList();
  }

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
    return seats.map((seat) => seat.name).toList();
  }

  static DateTime? parseUpdatedAt(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
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
