import 'package:dominican_casino/models/level_rewards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('levelRewards catalog', () {
    test('covers levels 1 through 30', () {
      expect(levelRewards.length, 30);
      expect(levelRewards.first.level, 1);
      expect(levelRewards.last.level, 30);
      for (var i = 0; i < levelRewards.length; i++) {
        expect(levelRewards[i].level, i + 1);
      }
    });

    test('every 3rd level is energy; others are coins', () {
      for (final def in levelRewards) {
        if (def.level % 3 == 0) {
          expect(def.kind, LevelRewardKind.energy);
          expect(def.amount, energyForLevel(def.level));
        } else {
          expect(def.kind, LevelRewardKind.coins);
          expect(def.amount, coinsForLevel(def.level));
        }
      }
    });

    test('amount formulas match plan defaults', () {
      expect(coinsForLevel(1), 65);
      expect(coinsForLevel(10), 200);
      expect(coinsForLevel(29), 485);
      expect(energyForLevel(3), 9);
      expect(energyForLevel(15), 13);
      expect(energyForLevel(30), 18);
    });

    test('rewardForLevel bounds', () {
      expect(rewardForLevel(0), isNull);
      expect(rewardForLevel(31), isNull);
      expect(rewardForLevel(5)?.kind, LevelRewardKind.coins);
      expect(rewardForLevel(6)?.kind, LevelRewardKind.energy);
    });
  });

  group('claim eligibility helpers', () {
    test('unlocked levels without claim are unclaimed', () {
      final levels = unclaimedLevelRewardLevels(
        playerLevel: 5,
        claimed: {1, 3},
      );
      expect(levels, [2, 4, 5]);
    });

    test('caps unclaimed at max catalog level', () {
      final levels = unclaimedLevelRewardLevels(
        playerLevel: 99,
        claimed: {},
      );
      expect(levels.length, maxLevelRewardLevel);
      expect(levels.last, maxLevelRewardLevel);
    });

    test('isLevelRewardClaimable respects level and claimed set', () {
      expect(
        isLevelRewardClaimable(level: 4, playerLevel: 3, claimed: {}),
        isFalse,
      );
      expect(
        isLevelRewardClaimable(level: 3, playerLevel: 5, claimed: {3}),
        isFalse,
      );
      expect(
        isLevelRewardClaimable(level: 3, playerLevel: 5, claimed: {}),
        isTrue,
      );
      expect(
        isLevelRewardClaimable(level: 0, playerLevel: 5, claimed: {}),
        isFalse,
      );
      expect(
        isLevelRewardClaimable(level: 31, playerLevel: 40, claimed: {}),
        isFalse,
      );
    });

    test('claiming all unlocked clears unclaimed count', () {
      const playerLevel = 7;
      final claimed = <int>{};
      expect(
        unclaimedLevelRewardLevels(
          playerLevel: playerLevel,
          claimed: claimed,
        ).length,
        7,
      );
      for (final level in List<int>.generate(playerLevel, (i) => i + 1)) {
        expect(
          isLevelRewardClaimable(
            level: level,
            playerLevel: playerLevel,
            claimed: claimed,
          ),
          isTrue,
        );
        claimed.add(level);
      }
      expect(
        unclaimedLevelRewardLevels(
          playerLevel: playerLevel,
          claimed: claimed,
        ),
        isEmpty,
      );
      // Double-claim is rejected.
      expect(
        isLevelRewardClaimable(
          level: 1,
          playerLevel: playerLevel,
          claimed: claimed,
        ),
        isFalse,
      );
    });
  });
}
