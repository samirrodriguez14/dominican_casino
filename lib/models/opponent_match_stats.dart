import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/player_match_stats.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';

/// Head-to-head career record against one human opponent.
class OpponentMatchStats {
  const OpponentMatchStats({
    required this.opponentUid,
    this.name,
    this.avatarId,
    this.avatarAsset,
    this.wins = 0,
    this.losses = 0,
    this.byMode = const {},
    this.lastPlayedAt,
  });

  final String opponentUid;
  final String? name;
  final String? avatarId;
  final String? avatarAsset;
  final int wins;
  final int losses;
  final Map<String, ModeMatchStats> byMode;
  final DateTime? lastPlayedAt;

  int get gamesPlayed => wins + losses;

  bool get isEmpty => wins == 0 && losses == 0 && byMode.isEmpty;

  ModeMatchStats modeStats(String modeName) =>
      byMode[modeName] ?? const ModeMatchStats();

  GameSeatLook get seatLook => GameSeatLook(
        avatarId: avatarId,
        avatarAsset: avatarAsset,
      );

  OpponentMatchStats recordResult({
    required String modeName,
    required bool won,
    int? place,
    String? name,
    String? avatarId,
    String? avatarAsset,
    DateTime? playedAt,
  }) {
    final mode = modeStats(modeName).record(won: won, place: place);
    return OpponentMatchStats(
      opponentUid: opponentUid,
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      wins: wins + (won ? 1 : 0),
      losses: losses + (won ? 0 : 1),
      byMode: {...byMode, modeName: mode},
      lastPlayedAt: playedAt ?? lastPlayedAt ?? DateTime.now().toUtc(),
    );
  }

  factory OpponentMatchStats.fromDoc(String id, Map<String, dynamic> data) {
    final byModeRaw = data['byMode'];
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
    return OpponentMatchStats(
      opponentUid: (data['opponentUid'] as String?) ?? id,
      name: data['name'] as String?,
      avatarId: data['avatarId'] as String?,
      avatarAsset: data['avatarAsset'] as String?,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      losses: (data['losses'] as num?)?.toInt() ?? 0,
      byMode: byMode,
      lastPlayedAt: _parseDate(data['lastPlayedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'opponentUid': opponentUid,
        if (name != null) 'name': name,
        if (avatarId != null) 'avatarId': avatarId,
        if (avatarAsset != null) 'avatarAsset': avatarAsset,
        'wins': wins,
        'losses': losses,
        if (byMode.isNotEmpty)
          'byMode': {
            for (final e in byMode.entries) e.key: e.value.toJson(),
          },
        if (lastPlayedAt != null)
          'lastPlayedAt': Timestamp.fromDate(lastPlayedAt!.toUtc()),
      };

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

/// Lightweight invite seat snapshot (not a paid / turn-order seat).
class InvitedSeat {
  const InvitedSeat({
    required this.id,
    this.name,
    this.avatarId,
    this.avatarAsset,
    this.defeatedAces = const {},
    this.wearJourneyAccessories = true,
  });

  final String id;
  final String? name;
  final String? avatarId;
  final String? avatarAsset;
  final Set<JourneyWorld> defeatedAces;
  final bool wearJourneyAccessories;

  factory InvitedSeat.fromMap(String id, Map<String, dynamic> map) {
    final look = GameSeatLook.fromMap(map);
    return InvitedSeat(
      id: id,
      name: map['name'] as String?,
      avatarId: look.avatarId,
      avatarAsset: look.avatarAsset,
      defeatedAces: look.defeatedAces,
      wearJourneyAccessories: look.wearJourneyAccessories,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        if (name != null) 'name': name,
        if (avatarId != null) 'avatarId': avatarId,
        if (avatarAsset != null) 'avatarAsset': avatarAsset,
        if (defeatedAces.isNotEmpty)
          'defeatedAces': defeatedAces.map((w) => w.name).toList(),
        'wearJourneyAccessories': wearJourneyAccessories,
      };

  GameSeatLook get seatLook => GameSeatLook(
        avatarId: avatarId,
        avatarAsset: avatarAsset,
        defeatedAces: defeatedAces,
        wearJourneyAccessories: wearJourneyAccessories,
      );
}
