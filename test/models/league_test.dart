import 'package:dominican_casino/models/league.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('highestUnlockedLeague', () {
    test('null when no kingdoms entered', () {
      expect(highestUnlockedLeague(enteredWorlds: {}), isNull);
    });

    test('diamonds when diamonds entered', () {
      expect(
        highestUnlockedLeague(enteredWorlds: {JourneyWorld.diamonds}),
        JourneyWorld.diamonds,
      );
    });

    test('highest entered kingdom wins', () {
      expect(
        highestUnlockedLeague(
          enteredWorlds: {
            JourneyWorld.diamonds,
            JourneyWorld.clubs,
            JourneyWorld.hearts,
          },
        ),
        JourneyWorld.hearts,
      );
    });

    test('entering alone unlocks without ace', () {
      expect(
        highestUnlockedLeague(enteredWorlds: {JourneyWorld.clubs}),
        JourneyWorld.clubs,
      );
    });
  });

  group('leaguePageStatus', () {
    test('all locked when no current', () {
      expect(
        leaguePageStatus(
          world: JourneyWorld.diamonds,
          currentLeague: null,
        ),
        LeaguePageStatus.locked,
      );
    });

    test('past current and locked relative to hearts', () {
      expect(
        leaguePageStatus(
          world: JourneyWorld.diamonds,
          currentLeague: JourneyWorld.hearts,
        ),
        LeaguePageStatus.past,
      );
      expect(
        leaguePageStatus(
          world: JourneyWorld.hearts,
          currentLeague: JourneyWorld.hearts,
        ),
        LeaguePageStatus.current,
      );
      expect(
        leaguePageStatus(
          world: JourneyWorld.spades,
          currentLeague: JourneyWorld.hearts,
        ),
        LeaguePageStatus.locked,
      );
    });
  });

  group('nextLeagueToUnlock', () {
    test('diamonds when none entered', () {
      expect(nextLeagueToUnlock(enteredWorlds: {}), JourneyWorld.diamonds);
    });

    test('clubs after diamonds entered', () {
      expect(
        nextLeagueToUnlock(enteredWorlds: {JourneyWorld.diamonds}),
        JourneyWorld.clubs,
      );
    });

    test('null after all entered', () {
      expect(
        nextLeagueToUnlock(enteredWorlds: JourneyWorld.values.toSet()),
        isNull,
      );
    });
  });

  group('compareFriendsByLeagueThenWins', () {
    test('higher league sorts first', () {
      final hearts = const PublicProfile(
        uid: 'a',
        wins: 1,
        league: JourneyWorld.hearts,
      );
      final clubs = const PublicProfile(
        uid: 'b',
        wins: 99,
        league: JourneyWorld.clubs,
      );
      expect(compareFriendsByLeagueThenWins(hearts, clubs), lessThan(0));
    });

    test('same league sorts by wins desc', () {
      final more = const PublicProfile(
        uid: 'a',
        wins: 10,
        league: JourneyWorld.diamonds,
      );
      final less = const PublicProfile(
        uid: 'b',
        wins: 3,
        league: JourneyWorld.diamonds,
      );
      expect(compareFriendsByLeagueThenWins(more, less), lessThan(0));
    });

    test('no league sorts last', () {
      final none = const PublicProfile(uid: 'a', wins: 50);
      final diamonds = const PublicProfile(
        uid: 'b',
        wins: 1,
        league: JourneyWorld.diamonds,
      );
      expect(compareFriendsByLeagueThenWins(none, diamonds), greaterThan(0));
    });
  });

  group('leagueRankFromHigherWinCount', () {
    test('first place when none have more wins', () {
      expect(leagueRankFromHigherWinCount(0), 1);
    });

    test('rank is one plus higher count', () {
      expect(leagueRankFromHigherWinCount(4), 5);
    });
  });
}
