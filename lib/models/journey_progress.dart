import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/journey_worlds.dart';

/// Pointer to a Journey challenger (and optional live match id).
class JourneyChallengeRef {
  const JourneyChallengeRef({
    required this.world,
    required this.rank,
    this.gameId,
  });

  final JourneyWorld world;
  final JourneyRank rank;
  final String? gameId;

  Map<String, dynamic> toJson() => {
    'world': world.name,
    'rank': rank.name,
    if (gameId != null && gameId!.isNotEmpty) 'gameId': gameId,
  };

  static JourneyChallengeRef? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final worldName = json['world'] as String?;
    final rankName = json['rank'] as String?;
    if (worldName == null || rankName == null) return null;
    JourneyWorld? world;
    JourneyRank? rank;
    for (final w in JourneyWorld.values) {
      if (w.name == worldName) world = w;
    }
    for (final r in JourneyRank.values) {
      if (r.name == rankName) rank = r;
    }
    if (world == null || rank == null) return null;
    final gameId = json['gameId'] as String?;
    return JourneyChallengeRef(
      world: world,
      rank: rank,
      gameId: (gameId != null && gameId.isNotEmpty) ? gameId : null,
    );
  }

  JourneyChallengeRef copyWith({
    JourneyWorld? world,
    JourneyRank? rank,
    String? gameId,
  }) {
    return JourneyChallengeRef(
      world: world ?? this.world,
      rank: rank ?? this.rank,
      gameId: gameId ?? this.gameId,
    );
  }
}

/// Persisted Journey board progress + pending match/taunt flags.
class JourneyProgress {
  JourneyProgress({
    Map<String, List<String>>? defeatedByWorld,
    this.pendingChallenge,
    this.pendingLossTaunt,
    this.pendingWinCelebration,
  }) : defeatedByWorld = {
         for (final e in (defeatedByWorld ?? {}).entries)
           e.key: List<String>.from(e.value),
       };

  factory JourneyProgress.empty() => JourneyProgress();

  factory JourneyProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JourneyProgress.empty();
    final raw = json['defeatedByWorld'];
    final defeated = <String, List<String>>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is! List) return;
        final ranks = <String>[
          for (final item in value)
            if (item is String && item.isNotEmpty) item,
        ];
        if (ranks.isNotEmpty) defeated[key.toString()] = ranks;
      });
    }
    return JourneyProgress(
      defeatedByWorld: defeated,
      pendingChallenge: JourneyChallengeRef.fromJson(
        json['pendingChallenge'] is Map
            ? Map<String, dynamic>.from(json['pendingChallenge'] as Map)
            : null,
      ),
      pendingLossTaunt: JourneyChallengeRef.fromJson(
        json['pendingLossTaunt'] is Map
            ? Map<String, dynamic>.from(json['pendingLossTaunt'] as Map)
            : null,
      ),
      pendingWinCelebration: JourneyChallengeRef.fromJson(
        json['pendingWinCelebration'] is Map
            ? Map<String, dynamic>.from(json['pendingWinCelebration'] as Map)
            : null,
      ),
    );
  }

  final Map<String, List<String>> defeatedByWorld;
  JourneyChallengeRef? pendingChallenge;
  JourneyChallengeRef? pendingLossTaunt;
  /// Defeated challenger awaiting instruction unlock + next-card reveal.
  JourneyChallengeRef? pendingWinCelebration;

  List<JourneyRank> defeatedRanksFor(JourneyWorld world) {
    final raw = defeatedByWorld[world.name] ?? const <String>[];
    final out = <JourneyRank>[];
    for (final name in raw) {
      for (final rank in JourneyRank.values) {
        if (rank.name == name) {
          out.add(rank);
          break;
        }
      }
    }
    return out;
  }

  bool isDefeated(JourneyWorld world, JourneyRank rank) {
    return defeatedRanksFor(world).contains(rank);
  }

  /// Append [rank] for [world] if not already recorded (order preserved).
  void recordDefeat(JourneyWorld world, JourneyRank rank) {
    final list = defeatedByWorld.putIfAbsent(world.name, () => <String>[]);
    if (!list.contains(rank.name)) list.add(rank.name);
  }

  /// Remove [rank] and any later ranks in that world (progression must stay ordered).
  void clearDefeat(JourneyWorld world, JourneyRank rank) {
    final list = defeatedByWorld[world.name];
    if (list == null || list.isEmpty) return;
    final order = JourneyRank.values;
    final idx = order.indexOf(rank);
    if (idx < 0) return;
    list.removeWhere((name) {
      final rIdx = order.indexWhere((r) => r.name == name);
      return rIdx < 0 || rIdx >= idx;
    });
    if (list.isEmpty) defeatedByWorld.remove(world.name);
  }

  Map<String, dynamic> toJson() => {
    'defeatedByWorld': {
      for (final e in defeatedByWorld.entries)
        if (e.value.isNotEmpty) e.key: List<String>.from(e.value),
    },
    if (pendingChallenge != null) 'pendingChallenge': pendingChallenge!.toJson(),
    if (pendingLossTaunt != null) 'pendingLossTaunt': pendingLossTaunt!.toJson(),
    if (pendingWinCelebration != null)
      'pendingWinCelebration': pendingWinCelebration!.toJson(),
  };
}

/// Rebuild the board from the static snapshot + stored defeats + level.
///
/// When a pending win celebration exists (and [deferPendingWin] is true), the
/// next challenger after that defeat stays locked until the unlock CTA runs.
JourneyDisplaySnapshot hydrateJourneyBoard({
  required JourneyProgress progress,
  required int playerLevel,
  bool deferPendingWin = true,
}) {
  var snap = journeyBoardSnapshot;
  for (final world in JourneyWorld.values) {
    final defeated = progress.defeatedRanksFor(world);
    for (final rank in defeated) {
      final result = snap.withDefeat(world, rank, playerLevel: playerLevel);
      snap = JourneyDisplaySnapshot(worlds: result.worlds);
    }
  }
  snap = snap.withLevelApplied(playerLevel);
  final defer =
      deferPendingWin ? progress.pendingWinCelebration : null;
  if (defer != null) {
    snap = snap.withDeferredNext(defer);
  }
  return snap;
}

extension on JourneyDisplaySnapshot {
  JourneyDisplaySnapshot withDeferredNext(JourneyChallengeRef defeated) {
    if (defeated.rank == JourneyRank.ace) {
      final idx = JourneyWorld.values.indexOf(defeated.world);
      if (idx < 0 || idx + 1 >= JourneyWorld.values.length) return this;
      final nextWorld = JourneyWorld.values[idx + 1];
      return JourneyDisplaySnapshot(
        worlds: [
          for (final w in worlds)
            if (w.world != nextWorld)
              w
            else
              w.copyWith(
                cards: [
                  for (final c in w.cards)
                    if (c.rank == JourneyRank.jack)
                      c.copyWith(state: JourneyCardState.levelLocked)
                    else
                      c,
                ],
              ),
        ],
      );
    }
    final next = defeated.rank.next;
    if (next == null) return this;
    return JourneyDisplaySnapshot(
      worlds: [
        for (final w in worlds)
          if (w.world != defeated.world)
            w
          else
            w.copyWith(
              cards: [
                for (final c in w.cards)
                  if (c.rank == next)
                    c.copyWith(
                      state: next == JourneyRank.ace
                          ? JourneyCardState.mysteryLocked
                          : JourneyCardState.levelLocked,
                    )
                  else
                    c,
              ],
            ),
      ],
    );
  }
}

/// Next card that should unlock after [defeated] (from a fully promoted board).
JourneyCardDef? journeyNextAfterDefeat({
  required JourneyProgress progress,
  required int playerLevel,
  required JourneyChallengeRef defeated,
}) {
  final full = hydrateJourneyBoard(
    progress: progress,
    playerLevel: playerLevel,
    deferPendingWin: false,
  );
  if (defeated.rank == JourneyRank.ace) {
    final idx = JourneyWorld.values.indexOf(defeated.world);
    if (idx < 0 || idx + 1 >= JourneyWorld.values.length) return null;
    return full.worldOf(JourneyWorld.values[idx + 1]).cardOf(JourneyRank.jack);
  }
  final next = defeated.rank.next;
  if (next == null) return null;
  return full.worldOf(defeated.world).cardOf(next);
}
