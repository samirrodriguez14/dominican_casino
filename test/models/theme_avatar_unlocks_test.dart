import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/models/theme_avatar_unlocks.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('unlockedAvatarIdsForPack', () {
    test('Sage starts with palm only at low level', () {
      expect(
        unlockedAvatarIdsForPack(Theme.sage, level: 1),
        ['palm'],
      );
      expect(
        lockedAvatarIdsForPack(Theme.sage, level: 1),
        ['leaf', 'star'],
      );
    });

    test('Sage unlocks leaf at 5 and star at 10', () {
      expect(
        unlockedAvatarIdsForPack(Theme.sage, level: 5),
        ['palm', 'leaf'],
      );
      expect(
        unlockedAvatarIdsForPack(Theme.sage, level: 10),
        ['palm', 'leaf', 'star'],
      );
      expect(lockedAvatarIdsForPack(Theme.sage, level: 10), isEmpty);
    });

    test('Diamonds starter only with no defeats', () {
      expect(
        unlockedAvatarIdsForPack(Theme.casino, level: 1),
        ['diamond'],
      );
      expect(
        lockedAvatarIdsForPack(Theme.casino, level: 1),
        [
          'acorn',
          journeyAvatarId(JourneyWorld.diamonds, JourneyRank.jack),
          journeyAvatarId(JourneyWorld.diamonds, JourneyRank.queen),
          journeyAvatarId(JourneyWorld.diamonds, JourneyRank.king),
          journeyAvatarId(JourneyWorld.diamonds, JourneyRank.ace),
        ],
      );
    });

    test('Diamonds unlocks faces on defeat and acorn at level 5', () {
      final defeated = {
        JourneyWorld.diamonds.name: [
          JourneyRank.jack.name,
          JourneyRank.queen.name,
        ],
      };
      expect(
        unlockedAvatarIdsForPack(
          Theme.casino,
          level: 5,
          defeatedByWorld: defeated,
        ),
        [
          'diamond',
          'acorn',
          journeyAvatarId(JourneyWorld.diamonds, JourneyRank.jack),
          journeyAvatarId(JourneyWorld.diamonds, JourneyRank.queen),
        ],
      );
    });

    test('Ace claim unlocks ace avatar', () {
      final defeated = {
        JourneyWorld.diamonds.name: [
          for (final r in JourneyRank.values) r.name,
        ],
      };
      final unlocked = unlockedAvatarIdsForPack(
        Theme.casino,
        level: 20,
        defeatedByWorld: defeated,
      );
      expect(
        unlocked,
        contains(journeyAvatarId(JourneyWorld.diamonds, JourneyRank.ace)),
      );
      expect(lockedAvatarIdsForPack(
        Theme.casino,
        level: 20,
        defeatedByWorld: defeated,
      ), isEmpty);
    });

    test('Clubs / Hearts / Spades level extras', () {
      expect(
        unlockedAvatarIdsForPack(Theme.dune, level: 10),
        contains('leaf'),
      );
      expect(
        unlockedAvatarIdsForPack(Theme.fig, level: 15),
        contains('sun'),
      );
      expect(
        unlockedAvatarIdsForPack(Theme.midnight, level: 20),
        contains('moon'),
      );
      expect(
        unlockedAvatarIdsForPack(Theme.dune, level: 9),
        isNot(contains('leaf')),
      );
    });
  });

  group('journey avatar helpers', () {
    test('journeyAvatarAssetPath resolves cutouts', () {
      expect(
        journeyAvatarAssetPath('journey_hearts_queen'),
        'assets/images/journey/avatars_transparent_challengers/hearts_queen.png',
      );
      expect(journeyAvatarAssetPath('palm'), isNull);
      expect(journeyAvatarAssetPath('journey_nope_jack'), isNull);
    });

    test('paintedAvatarIdFor maps journey ids to suit paints', () {
      expect(paintedAvatarIdFor('journey_diamonds_king'), 'diamond');
      expect(paintedAvatarIdFor('journey_clubs_ace'), 'club');
      expect(paintedAvatarIdFor('palm'), 'palm');
    });
  });

  group('lock messaging helpers', () {
    test('hasLockedJourneyAvatars when faces remain', () {
      expect(
        hasLockedJourneyAvatars(Theme.casino, level: 99),
        isTrue,
      );
      expect(
        hasLockedJourneyAvatars(
          Theme.casino,
          level: 99,
          defeatedByWorld: {
            JourneyWorld.diamonds.name: [
              for (final r in JourneyRank.values) r.name,
            ],
          },
        ),
        isFalse,
      );
    });

    test('nextLevelAvatarUnlock returns lowest remaining', () {
      expect(nextLevelAvatarUnlock(Theme.sage, level: 1), 5);
      expect(nextLevelAvatarUnlock(Theme.sage, level: 5), 10);
      expect(nextLevelAvatarUnlock(Theme.sage, level: 10), isNull);
      expect(nextLevelAvatarUnlock(Theme.midnight, level: 19), 20);
    });
  });
}
