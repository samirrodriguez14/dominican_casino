/// One-time per-level missions unlocked at a player level.
///
/// Separate from passive [level_rewards] (coins/energy on level reach) and
/// from rotating daily challenges.
enum LevelChallengeId {
  completeTutorial,
  playAnyMatch,
  playCasinoMatch,
  playOnlineMatch,
  winCasinoMatch,
  startJourney,
  playTresYDos,
  winVsPuli,
  win100CoinsSingle,
  defeatJourneyOnce,
  winOnlineMatch,
  playRummyOrBs,
  winTwoMatches,
  playStake100,
  win200CasinoCoins,
  tydRoundsThree,
  defeatJourneyTwice,
  sendReaction,
  winThreeMatches,
  win300CoinsSingle,
}

class LevelChallengeDef {
  const LevelChallengeDef({
    required this.id,
    required this.unlockLevel,
    required this.goal,
    required this.xpReward,
    required this.coinReward,
  });

  final LevelChallengeId id;
  final int unlockLevel;
  final int goal;
  final int xpReward;
  final int coinReward;

  String get key => id.name;
}

/// Highest unlock level with defined challenges in the current catalog.
const int maxLevelChallengeLevel = 10;

const levelChallenges = <LevelChallengeDef>[
  // Level 1 — Get into the game
  LevelChallengeDef(
    id: LevelChallengeId.completeTutorial,
    unlockLevel: 1,
    goal: 1,
    xpReward: 15,
    coinReward: 50,
  ),
  LevelChallengeDef(
    id: LevelChallengeId.playAnyMatch,
    unlockLevel: 1,
    goal: 1,
    xpReward: 10,
    coinReward: 25,
  ),
  // Level 2 — Modes & friends
  LevelChallengeDef(
    id: LevelChallengeId.playCasinoMatch,
    unlockLevel: 2,
    goal: 1,
    xpReward: 15,
    coinReward: 40,
  ),
  LevelChallengeDef(
    id: LevelChallengeId.playOnlineMatch,
    unlockLevel: 2,
    goal: 1,
    xpReward: 20,
    coinReward: 50,
  ),
  // Level 3 — Win & Journey
  LevelChallengeDef(
    id: LevelChallengeId.winCasinoMatch,
    unlockLevel: 3,
    goal: 1,
    xpReward: 25,
    coinReward: 75,
  ),
  LevelChallengeDef(
    id: LevelChallengeId.startJourney,
    unlockLevel: 3,
    goal: 1,
    xpReward: 15,
    coinReward: 40,
  ),
  // Level 4 — Broaden the table
  LevelChallengeDef(
    id: LevelChallengeId.playTresYDos,
    unlockLevel: 4,
    goal: 1,
    xpReward: 20,
    coinReward: 50,
  ),
  LevelChallengeDef(
    id: LevelChallengeId.winVsPuli,
    unlockLevel: 4,
    goal: 1,
    xpReward: 25,
    coinReward: 60,
  ),
  // Level 5 — Coin chase
  LevelChallengeDef(
    id: LevelChallengeId.win100CoinsSingle,
    unlockLevel: 5,
    goal: 1,
    xpReward: 25,
    coinReward: 75,
  ),
  LevelChallengeDef(
    id: LevelChallengeId.defeatJourneyOnce,
    unlockLevel: 5,
    goal: 1,
    xpReward: 30,
    coinReward: 80,
  ),
  // Level 6 — Social + variety
  LevelChallengeDef(
    id: LevelChallengeId.winOnlineMatch,
    unlockLevel: 6,
    goal: 1,
    xpReward: 30,
    coinReward: 100,
  ),
  LevelChallengeDef(
    id: LevelChallengeId.playRummyOrBs,
    unlockLevel: 6,
    goal: 1,
    xpReward: 20,
    coinReward: 50,
  ),
  // Level 7 — Streaks & stakes
  LevelChallengeDef(
    id: LevelChallengeId.winTwoMatches,
    unlockLevel: 7,
    goal: 2,
    xpReward: 30,
    coinReward: 100,
  ),
  LevelChallengeDef(
    id: LevelChallengeId.playStake100,
    unlockLevel: 7,
    goal: 1,
    xpReward: 20,
    coinReward: 75,
  ),
  // Level 8 — Mastery bites
  LevelChallengeDef(
    id: LevelChallengeId.win200CasinoCoins,
    unlockLevel: 8,
    goal: 1,
    xpReward: 35,
    coinReward: 120,
  ),
  LevelChallengeDef(
    id: LevelChallengeId.tydRoundsThree,
    unlockLevel: 8,
    goal: 3,
    xpReward: 25,
    coinReward: 80,
  ),
  // Level 9 — Journey push
  LevelChallengeDef(
    id: LevelChallengeId.defeatJourneyTwice,
    unlockLevel: 9,
    goal: 2,
    xpReward: 35,
    coinReward: 120,
  ),
  LevelChallengeDef(
    id: LevelChallengeId.sendReaction,
    unlockLevel: 9,
    goal: 1,
    xpReward: 10,
    coinReward: 40,
  ),
  // Level 10 — Early-game capstone
  LevelChallengeDef(
    id: LevelChallengeId.winThreeMatches,
    unlockLevel: 10,
    goal: 3,
    xpReward: 40,
    coinReward: 150,
  ),
  LevelChallengeDef(
    id: LevelChallengeId.win300CoinsSingle,
    unlockLevel: 10,
    goal: 1,
    xpReward: 40,
    coinReward: 150,
  ),
];

LevelChallengeDef? levelChallengeById(LevelChallengeId id) {
  for (final def in levelChallenges) {
    if (def.id == id) return def;
  }
  return null;
}

List<LevelChallengeDef> levelChallengesForLevel(int level) {
  return [
    for (final def in levelChallenges)
      if (def.unlockLevel == level) def,
  ];
}

/// Levels that have at least one challenge, highest first (UI roadmap order).
List<int> levelChallengeUnlockLevelsReversed() {
  final levels = <int>{
    for (final def in levelChallenges) def.unlockLevel,
  }.toList()
    ..sort((a, b) => b.compareTo(a));
  return levels;
}

bool isLevelChallengeUnlocked({
  required LevelChallengeDef def,
  required int playerLevel,
}) =>
    playerLevel >= def.unlockLevel;

bool isLevelChallengeClaimable({
  required LevelChallengeDef def,
  required int playerLevel,
  required int progress,
  required Set<String> claimed,
}) {
  if (!isLevelChallengeUnlocked(def: def, playerLevel: playerLevel)) {
    return false;
  }
  if (claimed.contains(def.key)) return false;
  return progress >= def.goal;
}

List<LevelChallengeDef> unclaimedLevelChallenges({
  required int playerLevel,
  required Map<String, int> counts,
  required Set<String> claimed,
}) {
  return [
    for (final def in levelChallenges)
      if (isLevelChallengeClaimable(
        def: def,
        playerLevel: playerLevel,
        progress: counts[def.key] ?? 0,
        claimed: claimed,
      ))
        def,
  ];
}

class LevelChallengeState {
  LevelChallengeState({
    Map<String, int>? counts,
    Set<String>? claimed,
    Set<String>? credited,
  })  : counts = counts ?? {},
        claimed = claimed ?? {},
        credited = credited ?? {};

  factory LevelChallengeState.empty() => LevelChallengeState();

  factory LevelChallengeState.fromJson(Map<String, dynamic>? json) {
    if (json == null) return LevelChallengeState.empty();

    final counts = <String, int>{};
    final rawCounts = json['counts'];
    if (rawCounts is Map) {
      rawCounts.forEach((key, value) {
        final n = (value as num?)?.toInt() ?? 0;
        if (n > 0) counts[key.toString()] = n;
      });
    }

    final claimed = <String>{};
    final rawClaimed = json['claimed'];
    if (rawClaimed is List) {
      for (final item in rawClaimed) {
        if (item is String && item.isNotEmpty) claimed.add(item);
      }
    }

    final credited = <String>{};
    final rawCredited = json['credited'];
    if (rawCredited is List) {
      for (final item in rawCredited) {
        if (item is String && item.isNotEmpty) credited.add(item);
      }
    }

    return LevelChallengeState(
      counts: counts,
      claimed: claimed,
      credited: credited,
    );
  }

  final Map<String, int> counts;
  final Set<String> claimed;
  final Set<String> credited;

  int countFor(LevelChallengeId id) => counts[id.name] ?? 0;

  bool isClaimed(LevelChallengeId id) => claimed.contains(id.name);

  bool isComplete(LevelChallengeDef def) => countFor(def.id) >= def.goal;

  bool canClaim(LevelChallengeDef def, int playerLevel) =>
      isLevelChallengeClaimable(
        def: def,
        playerLevel: playerLevel,
        progress: countFor(def.id),
        claimed: claimed,
      );

  Map<String, dynamic> toJson() => {
        'counts': counts,
        'claimed': claimed.toList(),
        'credited': credited.toList(),
      };
}

/// Merge remote + local: take max counts, union claimed/credited.
LevelChallengeState mergeLevelChallengeStates(
  LevelChallengeState a,
  LevelChallengeState b,
) {
  final counts = Map<String, int>.from(a.counts);
  b.counts.forEach((key, value) {
    final cur = counts[key] ?? 0;
    if (value > cur) counts[key] = value;
  });
  return LevelChallengeState(
    counts: counts,
    claimed: {...a.claimed, ...b.claimed},
    credited: {...a.credited, ...b.credited},
  );
}
