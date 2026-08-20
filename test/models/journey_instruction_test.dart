import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/models/journey_instruction.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('journeyUnlockedThrough follows Diamonds defeat chain', () {
    var snap = journeyBoardSnapshot;
    expect(
      journeyUnlockedThrough(snapshot: snap, tutorialDone: false),
      1,
    );
    expect(
      journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
      2,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.diamonds, JourneyRank.jack).worlds,
    );
    expect(
      journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
      3,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.diamonds, JourneyRank.queen).worlds,
    );
    expect(
      journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
      4,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.diamonds, JourneyRank.king).worlds,
    );
    expect(
      journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
      5,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.diamonds, JourneyRank.ace).worlds,
    );
    expect(
      journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
      6,
    );
  });
}
