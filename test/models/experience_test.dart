import 'package:dominican_casino/models/experience.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExperienceConfig', () {
    test('match awards more XP for a win than a loss', () {
      expect(ExperienceConfig.xpForMatch(won: true), ExperienceConfig.winXp);
      expect(ExperienceConfig.xpForMatch(won: false), ExperienceConfig.lossXp);
      expect(ExperienceConfig.winXp, greaterThan(ExperienceConfig.lossXp));
      expect(ExperienceConfig.winXp, 25);
      expect(ExperienceConfig.lossXp, 10);
    });

    test('xp to advance grows by 20 each level', () {
      expect(ExperienceConfig.xpToAdvance(1), 40);
      expect(ExperienceConfig.xpToAdvance(2), 60);
      expect(ExperienceConfig.xpToAdvance(3), 80);
      expect(ExperienceConfig.xpToAdvance(10), 220);
    });

    test('total XP to reach level 5 is cumulative thresholds', () {
      // 40+60+80+100
      expect(ExperienceConfig.totalXpToReachLevel(5), 280);
      expect(ExperienceProgress.fromTotal(280).level, 5);
      expect(ExperienceConfig.totalXpToReachLevel(1), 0);
    });
  });

  group('ExperienceProgress', () {
    test('zero XP is level 1 with empty ring', () {
      final p = ExperienceProgress.fromTotal(0);
      expect(p.level, 1);
      expect(p.xpInLevel, 0);
      expect(p.xpToNext, 40);
      expect(p.progress, 0);
    });

    test('partial level fills progress', () {
      final p = ExperienceProgress.fromTotal(20);
      expect(p.level, 1);
      expect(p.xpInLevel, 20);
      expect(p.xpToNext, 40);
      expect(p.progress, 0.5);
    });

    test('exact threshold reaches next level', () {
      final p = ExperienceProgress.fromTotal(40);
      expect(p.level, 2);
      expect(p.xpInLevel, 0);
      expect(p.xpToNext, 60);
      expect(p.progress, 0);
    });

    test('multi-level accumulation', () {
      // 40 to clear L1 + 30 into L2
      final p = ExperienceProgress.fromTotal(70);
      expect(p.level, 2);
      expect(p.xpInLevel, 30);
      expect(p.xpToNext, 60);
      expect(p.progress, 0.5);
    });

    test('negative total is treated as zero', () {
      final p = ExperienceProgress.fromTotal(-5);
      expect(p.totalXp, 0);
      expect(p.level, 1);
    });
  });

  group('Player xp', () {
    test('missing xp defaults to 0', () {
      final p = Player.fromDto({'id': 'abc', 'name': 'Sam'});
      expect(p.xp, 0);
    });

    test('JSON round-trip keeps xp', () {
      final original = Player(id: 'u1', name: 'Sam', xp: 123);
      final restored = Player.fromDto(original.toJson());
      expect(restored.xp, 123);
      expect(restored.id, 'u1');
      expect(restored.name, 'Sam');
    });

    test('copyWith updates xp', () {
      final p = Player(id: 'u1', xp: 10).copyWith(xp: 40);
      expect(p.xp, 40);
    });
  });

  group('HomeXpClaim', () {
    test('fromJson rejects empty or non-positive amounts', () {
      expect(HomeXpClaim.fromJson(null), isNull);
      expect(HomeXpClaim.fromJson({'gameId': '', 'amount': 10}), isNull);
      expect(HomeXpClaim.fromJson({'gameId': 'g1', 'amount': 0}), isNull);
      expect(HomeXpClaim.fromJson({'gameId': 'g1', 'amount': -1}), isNull);
    });

    test('fromJson / toJson round-trip', () {
      const claim = HomeXpClaim(gameId: 'g1', amount: 25);
      final restored = HomeXpClaim.fromJson(claim.toJson());
      expect(restored?.gameId, 'g1');
      expect(restored?.amount, 25);
    });
  });
}
