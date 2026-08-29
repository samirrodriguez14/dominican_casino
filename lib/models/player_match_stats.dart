import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';

/// Per-mode career counters for a player.
class ModeMatchStats {
  const ModeMatchStats({
    this.wins = 0,
    this.losses = 0,
    this.places = const {},
  });

  final int wins;
  final int losses;

  /// Finish rank → count (1 = first, 2 = second, …).
  final Map<int, int> places;

  int get gamesPlayed => wins + losses;

  bool get isEmpty => wins == 0 && losses == 0 && places.isEmpty;

  ModeMatchStats record({required bool won, int? place}) {
    final nextPlaces = Map<int, int>.from(places);
    if (place != null && place > 0) {
      nextPlaces[place] = (nextPlaces[place] ?? 0) + 1;
    }
    return ModeMatchStats(
      wins: wins + (won ? 1 : 0),
      losses: losses + (won ? 0 : 1),
      places: nextPlaces,
    );
  }

  factory ModeMatchStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ModeMatchStats();
    return ModeMatchStats(
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      places: _intKeyMap(json['places']),
    );
  }

  Map<String, dynamic> toJson() => {
    'wins': wins,
    'losses': losses,
    if (places.isNotEmpty)
      'places': {
        for (final e in places.entries) '${e.key}': e.value,
      },
  };

  static Map<int, int> _intKeyMap(dynamic raw) {
    if (raw is! Map) return {};
    final out = <int, int>{};
    for (final e in raw.entries) {
      final key = int.tryParse(e.key.toString());
      if (key == null || key < 1) continue;
      final value = (e.value as num?)?.toInt() ?? 0;
      if (value > 0) out[key] = value;
    }
    return out;
  }
}

/// Career win/loss record (1st place = win; anything else = loss).
class PlayerMatchStats {
  const PlayerMatchStats({
    this.wins = 0,
    this.losses = 0,
    this.byMode = const {},
  });

  static const empty = PlayerMatchStats();

  final int wins;
  final int losses;
  final Map<String, ModeMatchStats> byMode;

  int get gamesPlayed => wins + losses;

  bool get isEmpty => wins == 0 && losses == 0 && byMode.isEmpty;

  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;

  ModeMatchStats modeStats(String modeName) =>
      byMode[modeName] ?? const ModeMatchStats();

  PlayerMatchStats recordResult({
    required String modeName,
    required bool won,
    int? place,
  }) {
    final mode = modeStats(modeName).record(won: won, place: place);
    return PlayerMatchStats(
      wins: wins + (won ? 1 : 0),
      losses: losses + (won ? 0 : 1),
      byMode: {...byMode, modeName: mode},
    );
  }

  /// Prefer the side with more recorded games; ties keep [preferred].
  static PlayerMatchStats prefer({
    required PlayerMatchStats preferred,
    required PlayerMatchStats other,
  }) {
    if (other.gamesPlayed > preferred.gamesPlayed) return other;
    return preferred;
  }

  factory PlayerMatchStats.fromJson(dynamic raw) {
    if (raw is! Map) return empty;
    final map = Map<String, dynamic>.from(raw);
    final byModeRaw = map['byMode'];
    final byMode = <String, ModeMatchStats>{};
    if (byModeRaw is Map) {
      for (final e in byModeRaw.entries) {
        final key = e.key.toString();
        if (key.isEmpty) continue;
        final value = e.value;
        byMode[key] = ModeMatchStats.fromJson(
          value is Map ? Map<String, dynamic>.from(value) : null,
        );
      }
    }
    return PlayerMatchStats(
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      byMode: byMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'wins': wins,
    'losses': losses,
    if (byMode.isNotEmpty)
      'byMode': {
        for (final e in byMode.entries) e.key: e.value.toJson(),
      },
  };

  /// Aggregate finished archived pills for [pid].
  static PlayerMatchStats fromArchivedGames(
    Iterable<GamePillData> games,
    String pid,
  ) {
    var stats = empty;
    for (final game in games) {
      if (game.gameStatus != GameStatus.gameOver) continue;
      if (!game.containsPlayer(pid)) continue;
      final winner = game.winnerId;
      if (winner == null || winner.isEmpty) continue;
      stats = stats.recordResult(
        modeName: game.gameMode.name,
        won: winner == pid,
        place: game.finishRank(pid),
      );
    }
    return stats;
  }

  /// Returns this with [game] counted for [pid], or unchanged if not applicable.
  PlayerMatchStats withGame(GameState game, String pid) {
    if (game.gameStatus != GameStatus.gameOver) return this;
    if (pid.isEmpty) return this;
    if (!game.playersInfo.containsKey(pid)) return this;
    final winner = game.winnerId;
    if (winner == null || winner.isEmpty) return this;
    return recordResult(
      modeName: game.gameMode.name,
      won: winner == pid,
      place: game.finishRank(pid),
    );
  }
}
