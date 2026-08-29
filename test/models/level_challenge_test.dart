import 'package:dominican_casino/models/level_challenge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('levelChallenges catalog', () {
    test('covers levels 1 through 10 with two challenges each', () {
      expect(levelChallenges.length, 20);
      expect(maxLevelChallengeLevel, 10);
      for (var level = 1; level <= 10; level++) {
        expect(levelChallengesForLevel(level).length, 2);
      }
    });

    test('reward amounts match the plan', () {
      expect(
        levelChallengeById(LevelChallengeId.completeTutorial)?.xpReward,
        15,
      );
      expect(
        levelChallengeById(LevelChallengeId.completeTutorial)?.coinReward,
        50,
      );
      expect(
        levelChallengeById(LevelChallengeId.winThreeMatches)?.goal,
        3,
      );
      expect(
        levelChallengeById(LevelChallengeId.win300CoinsSingle)?.xpReward,
        40,
      );
      expect(
        levelChallengeById(LevelChallengeId.win300CoinsSingle)?.coinReward,
        150,
      );
    });

    test('levelChallengeById finds every catalog entry', () {
      for (final def in levelChallenges) {
        expect(levelChallengeById(def.id), same(def));
      }
    });
  });

  group('claim eligibility helpers', () {
    test('locked until unlock level', () {
      final def = levelChallengeById(LevelChallengeId.playCasinoMatch)!;
      expect(
        isLevelChallengeClaimable(
          def: def,
          playerLevel: 1,
          progress: 1,
          claimed: {},
        ),
        isFalse,
      );
      expect(
        isLevelChallengeClaimable(
          def: def,
          playerLevel: 2,
          progress: 1,
          claimed: {},
        ),
        isTrue,
      );
    });

    test('requires progress and not claimed', () {
      final def = levelChallengeById(LevelChallengeId.winTwoMatches)!;
      expect(
        isLevelChallengeClaimable(
          def: def,
          playerLevel: 7,
          progress: 1,
          claimed: {},
        ),
        isFalse,
      );
      expect(
        isLevelChallengeClaimable(
          def: def,
          playerLevel: 7,
          progress: 2,
          claimed: {def.key},
        ),
        isFalse,
      );
      expect(
        isLevelChallengeClaimable(
          def: def,
          playerLevel: 7,
          progress: 2,
          claimed: {},
        ),
        isTrue,
      );
    });

    test('unclaimedLevelChallenges filters correctly', () {
      final list = unclaimedLevelChallenges(
        playerLevel: 3,
        counts: {
          LevelChallengeId.completeTutorial.name: 1,
          LevelChallengeId.playAnyMatch.name: 1,
          LevelChallengeId.winCasinoMatch.name: 1,
        },
        claimed: {LevelChallengeId.completeTutorial.name},
      );
      final ids = list.map((d) => d.id).toSet();
      expect(ids, contains(LevelChallengeId.playAnyMatch));
      expect(ids, contains(LevelChallengeId.winCasinoMatch));
      expect(ids, isNot(contains(LevelChallengeId.completeTutorial)));
      expect(ids, isNot(contains(LevelChallengeId.playCasinoMatch)));
    });
  });

  group('LevelChallengeState', () {
    test('round-trips json', () {
      final state = LevelChallengeState(
        counts: {LevelChallengeId.playAnyMatch.name: 1},
        claimed: {LevelChallengeId.completeTutorial.name},
        credited: {'play:abc'},
      );
      final restored = LevelChallengeState.fromJson(state.toJson());
      expect(restored.countFor(LevelChallengeId.playAnyMatch), 1);
      expect(restored.isClaimed(LevelChallengeId.completeTutorial), isTrue);
      expect(restored.credited, contains('play:abc'));
    });

    test('merge takes max counts and unions sets', () {
      final a = LevelChallengeState(
        counts: {'a': 1, 'b': 3},
        claimed: {'x'},
        credited: {'e1'},
      );
      final b = LevelChallengeState(
        counts: {'a': 2, 'c': 1},
        claimed: {'y'},
        credited: {'e2'},
      );
      final m = mergeLevelChallengeStates(a, b);
      expect(m.counts['a'], 2);
      expect(m.counts['b'], 3);
      expect(m.counts['c'], 1);
      expect(m.claimed, {'x', 'y'});
      expect(m.credited, {'e1', 'e2'});
    });
  });
}
