enum DailyChallengeId { tydRounds, casinoClassic }

enum DailyChallengeRewardKind { coins, energy }

class DailyChallengeDef {
  const DailyChallengeDef({
    required this.id,
    required this.goal,
    required this.reward,
    required this.rewardKind,
  });

  final DailyChallengeId id;
  final int goal;
  final int reward;
  final DailyChallengeRewardKind rewardKind;

  String get key => id.name;
}

const dailyChallenges = <DailyChallengeDef>[
  DailyChallengeDef(
    id: DailyChallengeId.tydRounds,
    goal: 3,
    reward: 20,
    rewardKind: DailyChallengeRewardKind.energy,
  ),
  DailyChallengeDef(
    id: DailyChallengeId.casinoClassic,
    goal: 1,
    reward: 10,
    rewardKind: DailyChallengeRewardKind.energy,
  ),
];

DailyChallengeDef? dailyChallengeById(DailyChallengeId id) {
  for (final def in dailyChallenges) {
    if (def.id == id) return def;
  }
  return null;
}

class DailyChallengeState {
  DailyChallengeState({
    required this.dayKey,
    Map<String, int>? counts,
    Set<String>? claimed,
    Set<String>? credited,
  }) : counts = counts ?? {},
       claimed = claimed ?? {},
       credited = credited ?? {};

  factory DailyChallengeState.empty(String dayKey) =>
      DailyChallengeState(dayKey: dayKey);

  factory DailyChallengeState.fromJson(Map<String, dynamic>? json, String today) {
    if (json == null) return DailyChallengeState.empty(today);
    final day = json['day'] as String? ?? '';
    if (day != today) return DailyChallengeState.empty(today);

    final rawCounts = json['counts'];
    final counts = <String, int>{};
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

    return DailyChallengeState(
      dayKey: day,
      counts: counts,
      claimed: claimed,
      credited: credited,
    );
  }

  final String dayKey;
  final Map<String, int> counts;
  final Set<String> claimed;
  final Set<String> credited;

  int countFor(DailyChallengeId id) => counts[id.name] ?? 0;

  bool isClaimed(DailyChallengeId id) => claimed.contains(id.name);

  bool isComplete(DailyChallengeDef def) => countFor(def.id) >= def.goal;

  bool canClaim(DailyChallengeDef def) =>
      isComplete(def) && !isClaimed(def.id);

  DailyChallengeState forDay(String today) {
    if (dayKey == today) return this;
    return DailyChallengeState.empty(today);
  }

  Map<String, dynamic> toJson() => {
    'day': dayKey,
    'counts': counts,
    'claimed': claimed.toList(),
    'credited': credited.toList(),
  };
}
