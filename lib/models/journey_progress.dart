import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/journey_worlds.dart';

/// Jack + Queen + King + Ace across all four kingdoms.
const journeyTrailStepCount = 16;

/// Global trail index for a world/rank (0…15).
int journeyTrailStepIndex(JourneyWorld world, JourneyRank rank) {
  final wi = JourneyWorld.values.indexOf(world).clamp(0, 3);
  final ri = JourneyRank.values.indexOf(rank).clamp(0, 3);
  return wi * 4 + ri;
}

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

/// Theme / avatar unlocks earned from a Journey victory (shown after coins/XP).
class JourneyUnlockReward {
  const JourneyUnlockReward({
    required this.world,
    required this.rank,
    this.avatarId,
    this.themeId,
  });

  final JourneyWorld world;
  final JourneyRank rank;
  /// Newly unlocked Journey face avatar id (`journey_…`).
  final String? avatarId;
  /// Newly unlocked play theme (usually the next world after an Ace).
  final String? themeId;

  bool get hasContent =>
      (avatarId != null && avatarId!.isNotEmpty) ||
      (themeId != null && themeId!.isNotEmpty);

  Map<String, dynamic> toJson() => {
    'world': world.name,
    'rank': rank.name,
    if (avatarId != null) 'avatarId': avatarId,
    if (themeId != null) 'themeId': themeId,
  };

  static JourneyUnlockReward? fromJson(Map<String, dynamic>? json) {
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
    final reward = JourneyUnlockReward(
      world: world,
      rank: rank,
      avatarId: json['avatarId'] as String?,
      themeId: json['themeId'] as String?,
    );
    return reward.hasContent ? reward : null;
  }
}

/// Persisted Journey board progress + pending match/taunt flags.
class JourneyProgress {
  JourneyProgress({
    Map<String, List<String>>? defeatedByWorld,
    Set<String>? enteredWorlds,
    this.pendingChallenge,
    this.pendingLossTaunt,
    this.pendingWinCelebration,
    this.pendingReplayPraise,
    this.pendingUnlockReward,
    this.diamondsEntered = false,
    this.diamondsJackUnlocked = false,
  }) : defeatedByWorld = {
         for (final e in (defeatedByWorld ?? {}).entries)
           e.key: List<String>.from(e.value),
       },
       enteredWorlds = {...?enteredWorlds};

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
    final entered = <String>{};
    final rawEntered = json['enteredWorlds'];
    if (rawEntered is List) {
      for (final item in rawEntered) {
        if (item is String && item.isNotEmpty) entered.add(item);
      }
    }
    final progress = JourneyProgress(
      defeatedByWorld: defeated,
      enteredWorlds: entered,
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
      pendingReplayPraise: JourneyChallengeRef.fromJson(
        json['pendingReplayPraise'] is Map
            ? Map<String, dynamic>.from(json['pendingReplayPraise'] as Map)
            : null,
      ),
      pendingUnlockReward: JourneyUnlockReward.fromJson(
        json['pendingUnlockReward'] is Map
            ? Map<String, dynamic>.from(json['pendingUnlockReward'] as Map)
            : null,
      ),
      diamondsEntered: json['diamondsEntered'] == true,
      diamondsJackUnlocked: json['diamondsJackUnlocked'] == true,
    );
    // Migrate older saves that already beat Diamonds content.
    if (progress.isDefeated(JourneyWorld.diamonds, JourneyRank.jack) ||
        progress.isDefeated(JourneyWorld.diamonds, JourneyRank.ace)) {
      progress.diamondsEntered = true;
      progress.diamondsJackUnlocked = true;
    }
    if (progress.diamondsEntered) {
      progress.enteredWorlds.add(JourneyWorld.diamonds.name);
    }
    // Any fight in a world counts as having entered that kingdom.
    for (final world in JourneyWorld.values) {
      if (progress.defeatedRanksFor(world).isNotEmpty) {
        progress.enteredWorlds.add(world.name);
      }
    }
    return progress;
  }

  final Map<String, List<String>> defeatedByWorld;
  /// Kingdoms the player has entered (theme unlock + board access for Diamonds).
  final Set<String> enteredWorlds;
  JourneyChallengeRef? pendingChallenge;
  JourneyChallengeRef? pendingLossTaunt;
  /// Defeated challenger awaiting instruction unlock + next-card reveal.
  JourneyChallengeRef? pendingWinCelebration;
  /// Replay win: praise dialog only (no journey unlock / instruction).
  JourneyChallengeRef? pendingReplayPraise;
  /// Avatar / theme unlocks to show after coins & XP.
  JourneyUnlockReward? pendingUnlockReward;
  /// Player confirmed Enter Diamonds kingdom (theme + world unlocked).
  bool diamondsEntered;
  /// Prove-yourself CTA revealed the Diamonds Jack face-up.
  bool diamondsJackUnlocked;

  bool hasEntered(JourneyWorld world) {
    if (enteredWorlds.contains(world.name)) return true;
    if (world == JourneyWorld.diamonds && diamondsEntered) return true;
    return defeatedRanksFor(world).isNotEmpty;
  }

  void markEntered(JourneyWorld world) {
    enteredWorlds.add(world.name);
    if (world == JourneyWorld.diamonds) diamondsEntered = true;
  }

  /// Play-locked theme may unlock only after the prior Ace (Diamonds: anytime).
  bool canUnlockThemeFor(JourneyWorld world) {
    if (world == JourneyWorld.diamonds) return true;
    final idx = JourneyWorld.values.indexOf(world);
    if (idx <= 0) return false;
    return isDefeated(JourneyWorld.values[idx - 1], JourneyRank.ace);
  }

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

  /// Worlds whose Ace has been claimed (avatar suit accessories).
  Set<JourneyWorld> get defeatedAceWorlds => {
        for (final world in JourneyWorld.values)
          if (isDefeated(world, JourneyRank.ace)) world,
      };

  /// Trail steps completed (Jack–Ace across four kingdoms), 0…16.
  int get trailStepsCompleted {
    var n = 0;
    for (final world in JourneyWorld.values) {
      n += defeatedRanksFor(world).length;
    }
    return n.clamp(0, journeyTrailStepCount);
  }

  double get trailProgress => trailStepsCompleted / journeyTrailStepCount;

  /// Append [rank] for [world] if not already recorded (order preserved).
  void recordDefeat(JourneyWorld world, JourneyRank rank) {
    final list = defeatedByWorld.putIfAbsent(world.name, () => <String>[]);
    if (!list.contains(rank.name)) list.add(rank.name);
    enteredWorlds.add(world.name);
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
    if (pendingReplayPraise != null)
      'pendingReplayPraise': pendingReplayPraise!.toJson(),
    if (pendingUnlockReward != null)
      'pendingUnlockReward': pendingUnlockReward!.toJson(),
    'diamondsEntered': diamondsEntered,
    'diamondsJackUnlocked': diamondsJackUnlocked,
    if (enteredWorlds.isNotEmpty) 'enteredWorlds': enteredWorlds.toList(),
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
  snap = snap.withDiamondsGates(
    entered: progress.diamondsEntered,
    jackUnlocked: progress.diamondsJackUnlocked,
    playerLevel: playerLevel,
  );
  final defer =
      deferPendingWin ? progress.pendingWinCelebration : null;
  if (defer != null) {
    snap = snap.withDeferredNext(defer);
  }
  return snap;
}

extension on JourneyDisplaySnapshot {
  /// Apply first-kingdom tutorial gates before the Jack is playable.
  JourneyDisplaySnapshot withDiamondsGates({
    required bool entered,
    required bool jackUnlocked,
    int playerLevel = 1,
  }) {
    return JourneyDisplaySnapshot(
      worlds: [
        for (final w in worlds)
          if (w.world != JourneyWorld.diamonds)
            w
          else if (!entered)
            w.copyWith(
              unlocked: false,
              cards: [
                for (final c in w.cards)
                  if (c.rank == JourneyRank.jack)
                    c.copyWith(state: JourneyCardState.levelLocked)
                  else if (c.state == JourneyCardState.available)
                    c.copyWith(state: JourneyCardState.levelLocked)
                  else
                    c,
              ],
            )
          else if (!jackUnlocked)
            w.copyWith(
              unlocked: true,
              cards: [
                for (final c in w.cards)
                  if (c.rank == JourneyRank.jack &&
                      c.state != JourneyCardState.defeated)
                    c.copyWith(state: JourneyCardState.levelLocked)
                  else
                    c,
              ],
            )
          else
            // Snapshot starts locked; re-apply level once both gates clear.
            w.copyWith(unlocked: true).withLevelApplied(playerLevel),
      ],
    );
  }

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
