import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/models/journey_progress.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trail progress counts all defeated ranks including Aces', () {
    final progress = JourneyProgress.empty();
    expect(progress.trailStepsCompleted, 0);
    expect(progress.trailProgress, 0);

    progress.recordDefeat(JourneyWorld.diamonds, JourneyRank.jack);
    progress.recordDefeat(JourneyWorld.diamonds, JourneyRank.queen);
    expect(progress.trailStepsCompleted, 2);

    progress.recordDefeat(JourneyWorld.diamonds, JourneyRank.king);
    progress.recordDefeat(JourneyWorld.diamonds, JourneyRank.ace);
    expect(progress.trailStepsCompleted, 4);
    expect(progress.defeatedAceWorlds, {JourneyWorld.diamonds});
  });

  test('defeatedAceWorlds maps all four suits', () {
    final progress = JourneyProgress.empty();
    for (final world in JourneyWorld.values) {
      progress.recordDefeat(world, JourneyRank.ace);
    }
    expect(progress.defeatedAceWorlds, JourneyWorld.values.toSet());
    expect(progress.trailStepsCompleted, 4);
  });

  test('defeatedRoyals excludes Ace from pile UI list', () {
    var snap = hydrateJourneyBoard(
      progress: JourneyProgress(
        diamondsEntered: true,
        diamondsJackUnlocked: true,
      ),
      playerLevel: 2,
    );
    for (final rank in JourneyRank.values) {
      final r = snap.withDefeat(
        JourneyWorld.diamonds,
        rank,
        playerLevel: 2,
      );
      snap = JourneyDisplaySnapshot(worlds: r.worlds);
    }
    final diamonds = snap.worldOf(JourneyWorld.diamonds);
    expect(diamonds.defeatedCards.length, 4);
    expect(diamonds.defeatedRoyals.length, 3);
    expect(
      diamonds.defeatedRoyals.every((c) => c.rank != JourneyRank.ace),
      isTrue,
    );
  });

  test('journeyTrailStepIndex maps world and rank', () {
    expect(journeyTrailStepIndex(JourneyWorld.diamonds, JourneyRank.jack), 0);
    expect(journeyTrailStepIndex(JourneyWorld.diamonds, JourneyRank.queen), 1);
    expect(journeyTrailStepIndex(JourneyWorld.diamonds, JourneyRank.king), 2);
    expect(journeyTrailStepIndex(JourneyWorld.clubs, JourneyRank.jack), 4);
    expect(journeyTrailStepIndex(JourneyWorld.spades, JourneyRank.ace), 15);
  });
}
