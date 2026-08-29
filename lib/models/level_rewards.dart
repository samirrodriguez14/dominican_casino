import 'package:dominican_casino/style/journey_worlds.dart';

/// Per-level coin/energy rewards players claim from the rewards popup.
enum LevelRewardKind { coins, energy }

/// How a kingdom reward should read on the level roadmap.
enum JourneyKingdomRewardStatus {
  /// Player has not reached the required level yet.
  lockedByLevel,

  /// Level is met, but the prior Ace has not been defeated.
  needsPriorAce,

  /// Level + story gates clear; player has not entered yet.
  readyToEnter,

  /// Player has already entered the kingdom.
  entered,
}

JourneyKingdomRewardStatus journeyKingdomRewardStatus({
  required JourneyWorld world,
  required int playerLevel,
  required bool hasEntered,
  required bool canUnlock,
}) {
  if (hasEntered) return JourneyKingdomRewardStatus.entered;
  if (playerLevel < world.requiredLevel) {
    return JourneyKingdomRewardStatus.lockedByLevel;
  }
  if (canUnlock) return JourneyKingdomRewardStatus.readyToEnter;
  return JourneyKingdomRewardStatus.needsPriorAce;
}

class LevelRewardDef {
  const LevelRewardDef({
    required this.level,
    required this.kind,
    required this.amount,
    this.unlocksJourneyWorld,
  });

  final int level;
  final LevelRewardKind kind;
  final int amount;

  /// Optional Journey kingdom that becomes level-eligible at this level.
  final JourneyWorld? unlocksJourneyWorld;

  bool get isEnergy => kind == LevelRewardKind.energy;
  bool get isCoins => kind == LevelRewardKind.coins;
}

/// Highest level with a defined reward in the current catalog.
const int maxLevelRewardLevel = 30;

bool isEnergyLevel(int level) => level > 0 && level % 3 == 0;

int coinsForLevel(int level) => 50 + 15 * level;

int energyForLevel(int level) => 8 + level ~/ 3;

LevelRewardDef levelRewardFor(int level) {
  final kingdom = journeyWorldUnlockedAtLevel(level);
  if (isEnergyLevel(level)) {
    return LevelRewardDef(
      level: level,
      kind: LevelRewardKind.energy,
      amount: energyForLevel(level),
      unlocksJourneyWorld: kingdom,
    );
  }
  return LevelRewardDef(
    level: level,
    kind: LevelRewardKind.coins,
    amount: coinsForLevel(level),
    unlocksJourneyWorld: kingdom,
  );
}

/// Fixed catalog for levels 1–[maxLevelRewardLevel].
final List<LevelRewardDef> levelRewards = [
  for (var level = 1; level <= maxLevelRewardLevel; level++)
    levelRewardFor(level),
];

LevelRewardDef? rewardForLevel(int level) {
  if (level < 1 || level > maxLevelRewardLevel) return null;
  return levelRewards[level - 1];
}

/// Levels with a catalog entry that are unlocked but not yet claimed.
List<int> unclaimedLevelRewardLevels({
  required int playerLevel,
  required Set<int> claimed,
}) {
  final out = <int>[];
  final capped = playerLevel.clamp(0, maxLevelRewardLevel);
  for (var level = 1; level <= capped; level++) {
    if (!claimed.contains(level)) out.add(level);
  }
  return out;
}

bool isLevelRewardClaimable({
  required int level,
  required int playerLevel,
  required Set<int> claimed,
}) {
  if (level < 1 || level > maxLevelRewardLevel) return false;
  if (playerLevel < level) return false;
  return !claimed.contains(level);
}
