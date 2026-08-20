import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defeat unlocks next rank and Ace unlocks next world', () {
    var snap = journeyBoardSnapshot;

    var r = snap.withDefeat(JourneyWorld.diamonds, JourneyRank.jack);
    expect(
      r.worlds
          .firstWhere((w) => w.world == JourneyWorld.diamonds)
          .cardOf(JourneyRank.jack)!
          .state,
      JourneyCardState.defeated,
    );
    expect(r.revealedCard?.rank, JourneyRank.queen);
    expect(r.revealedCard?.state, JourneyCardState.available);

    snap = JourneyDisplaySnapshot(worlds: r.worlds);
    r = snap.withDefeat(JourneyWorld.diamonds, JourneyRank.queen);
    snap = JourneyDisplaySnapshot(worlds: r.worlds);
    r = snap.withDefeat(JourneyWorld.diamonds, JourneyRank.king);
    expect(r.revealedCard?.rank, JourneyRank.ace);

    snap = JourneyDisplaySnapshot(worlds: r.worlds);
    r = snap.withDefeat(JourneyWorld.diamonds, JourneyRank.ace);
    expect(r.unlockedWorld, JourneyWorld.clubs);
    expect(r.revealedCard?.world, JourneyWorld.clubs);
    expect(r.revealedCard?.rank, JourneyRank.jack);

    final clubs = r.worlds.firstWhere((w) => w.world == JourneyWorld.clubs);
    expect(clubs.unlocked, isTrue);
    expect(clubs.cardOf(JourneyRank.jack)!.state, JourneyCardState.available);
  });
}
