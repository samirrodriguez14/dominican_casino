import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/wallet_config.dart';

class GamePillSeat {
  final String id;
  final String name;
  final String? avatarId;
  final String? avatarAsset;

  const GamePillSeat({
    required this.id,
    required this.name,
    this.avatarId,
    this.avatarAsset,
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
  final int entryCost;
  final Map<String, int> scores;
  final Map<String, int> pendingCoins;

  GamePillData({
    required this.id,
    required this.playersInfo,
    required this.currentTurnPlayerId,
    required this.gameMode,
    required this.gameStatus,
    required this.winnerId,
    this.updatedAt,
    this.entryCost = WalletConfig.entryCost,
    Map<String, int>? scores,
    Map<String, int>? pendingCoins,
  })  : scores = scores ?? const {},
        pendingCoins = pendingCoins ?? const {};

  factory GamePillData.fromDoc(String id, Map<String, dynamic> data) {
    return GamePillData(
      id: id,
      playersInfo: Map<String, dynamic>.from(data['playersInfo'] ?? {}),
      currentTurnPlayerId: data['currentTurnPlayerId'] as String?,
      gameMode: _parseGameMode(data['gameMode']),
      gameStatus: _parseGameStatus(data['gameStatus']),
      winnerId: data['winnerId'] as String?,
      updatedAt: parseUpdatedAt(data['updatedAt']),
      entryCost: (data['entryCost'] as num?)?.toInt() ?? WalletConfig.entryCost,
      scores: _intMap(data['scores']),
      pendingCoins: _intMap(data['pendingCoins']),
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
      entryCost: (json['entryCost'] as num?)?.toInt() ?? WalletConfig.entryCost,
      scores: _intMap(json['scores']),
      pendingCoins: _intMap(json['pendingCoins']),
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
      'entryCost': entryCost,
      'scores': scores,
      'pendingCoins': pendingCoins,
    };
  }

  List<String> get playerIds => playersInfo.keys.toList();

  List<GamePillSeat> get seats {
    final all = playersInfo.entries.map((entry) {
      final raw = entry.value;
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      return GamePillSeat(
        id: entry.key,
        name: (map['name'] as String?) ?? 'Unknown',
        avatarId: map['avatarId'] as String?,
        avatarAsset: map['avatarAsset'] as String?,
      );
    }).toList();
    if (gameStatus != GameStatus.gameOver) return all;
    final ranks = finishRanks();
    all.sort((a, b) {
      final ar = ranks[a.id] ?? 99;
      final br = ranks[b.id] ?? 99;
      if (ar != br) return ar.compareTo(br);
      return a.name.compareTo(b.name);
    });
    return all;
  }

  int get seatedPlayerCount => playersInfo.length;

  int get jackpot => WalletConfig.potTotal(entryCost, seatedPlayerCount);

  int scoreOf(String pid) => scores[pid] ?? 0;

  int pendingCoinsFor(String pid) => pendingCoins[pid] ?? 0;

  Map<String, int> finishRanks() {
    final ids = playersInfo.keys.toList();
    final ranks = <String, int>{};
    if (ids.isEmpty) return ranks;

    final winner = winnerId;
    final hasWinner =
        winner != null && winner.isNotEmpty && ids.contains(winner);
    final rest = [
      for (final id in ids)
        if (!hasWinner || id != winner) id,
    ]..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));

    if (hasWinner) ranks[winner] = 1;

    var place = hasWinner ? 2 : 1;
    var i = 0;
    while (i < rest.length) {
      final score = scoreOf(rest[i]);
      var j = i + 1;
      while (j < rest.length && scoreOf(rest[j]) == score) {
        j++;
      }
      for (var k = i; k < j; k++) {
        ranks[rest[k]] = place;
      }
      place += j - i;
      i = j;
    }
    return ranks;
  }

  int? finishRank(String pid) => finishRanks()[pid];

  int coinsMade(String pid) {
    if (gameStatus != GameStatus.gameOver) return 0;
    final rank = finishRank(pid);
    var pot = 0;
    if (rank != null) {
      final pool = WalletConfig.potShareForRank(
        entryCost,
        seatedPlayerCount,
        rank,
      );
      if (pool > 0) {
        final tied = finishRanks().values.where((r) => r == rank).length;
        pot = tied <= 1 ? pool : pool ~/ tied;
      }
    }
    return pendingCoinsFor(pid) + pot;
  }

  bool containsPlayer(String pid) {
    if (playersInfo.containsKey(pid)) return true;
    for (final raw in playersInfo.values) {
      if (raw is Map && raw['id'] == pid) return true;
    }
    return false;
  }

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

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    );
  }
}
