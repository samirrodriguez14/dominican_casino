import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/models/journey_instruction.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog has pages 1–18', () {
    expect(journeyInstructionCatalogSize, 18);
    for (var id = 1; id <= 18; id++) {
      expect(journeyInstructionById(id), isNotNull, reason: 'missing id $id');
      expect(journeyInstructionById(id)!.id, id);
    }
  });

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

  test('journeyUnlockedThrough continues through Clubs Hearts Spades', () {
    var snap = journeyBoardSnapshot;
    // Clear Diamonds fully so Clubs is the active story world.
    for (final rank in JourneyRank.values) {
      snap = JourneyDisplaySnapshot(
        worlds: snap.withDefeat(JourneyWorld.diamonds, rank).worlds,
      );
    }
    expect(
      journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
      6,
    );

    final laterWorlds = [
      (JourneyWorld.clubs, 6),
      (JourneyWorld.hearts, 10),
      (JourneyWorld.spades, 14),
    ];

    for (final (world, base) in laterWorlds) {
      expect(
        journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
        base,
        reason: '$world entry page',
      );

      snap = JourneyDisplaySnapshot(
        worlds: snap.withDefeat(world, JourneyRank.jack).worlds,
      );
      expect(
        journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
        base + 1,
      );

      snap = JourneyDisplaySnapshot(
        worlds: snap.withDefeat(world, JourneyRank.queen).worlds,
      );
      expect(
        journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
        base + 2,
      );

      snap = JourneyDisplaySnapshot(
        worlds: snap.withDefeat(world, JourneyRank.king).worlds,
      );
      expect(
        journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
        base + 3,
      );

      snap = JourneyDisplaySnapshot(
        worlds: snap.withDefeat(world, JourneyRank.ace).worlds,
      );
      expect(
        journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
        base + 4,
      );
    }

    expect(
      journeyUnlockedThrough(snapshot: snap, tutorialDone: true),
      18,
    );
  });
}
