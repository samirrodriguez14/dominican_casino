import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/models/journey_progress.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defeat unlocks next rank and Ace unlocks next world', () {
    var snap = journeyBoardSnapshot.withLevelApplied(2);

    expect(
      snap.worldOf(JourneyWorld.diamonds).cardOf(JourneyRank.jack)!.state,
      JourneyCardState.available,
    );
    expect(
      snap.worldOf(JourneyWorld.diamonds).cardOf(JourneyRank.jack)!.gameMode,
      GameMode.tresydos,
    );

    var r = snap.withDefeat(
      JourneyWorld.diamonds,
      JourneyRank.jack,
      playerLevel: 2,
    );
    expect(
      r.worlds
          .firstWhere((w) => w.world == JourneyWorld.diamonds)
          .cardOf(JourneyRank.jack)!
          .state,
      JourneyCardState.defeated,
    );
    expect(r.revealedCard?.rank, JourneyRank.queen);
    expect(r.revealedCard?.state, JourneyCardState.available);
    expect(r.revealedCard?.gameMode, GameMode.rummy);

    snap = JourneyDisplaySnapshot(worlds: r.worlds);
    r = snap.withDefeat(
      JourneyWorld.diamonds,
      JourneyRank.queen,
      playerLevel: 2,
    );
    expect(r.revealedCard?.gameMode, GameMode.casinoSpeed);
    snap = JourneyDisplaySnapshot(worlds: r.worlds);
    r = snap.withDefeat(
      JourneyWorld.diamonds,
      JourneyRank.king,
      playerLevel: 2,
    );
    expect(r.revealedCard?.rank, JourneyRank.ace);

    snap = JourneyDisplaySnapshot(worlds: r.worlds);
    r = snap.withDefeat(
      JourneyWorld.diamonds,
      JourneyRank.ace,
      playerLevel: 2,
    );
    expect(r.unlockedWorld, JourneyWorld.clubs);
    expect(r.revealedCard?.world, JourneyWorld.clubs);
    expect(r.revealedCard?.rank, JourneyRank.jack);
    expect(r.revealedCard?.gameMode, GameMode.tresydos);

    final clubs = r.worlds.firstWhere((w) => w.world == JourneyWorld.clubs);
    expect(clubs.unlocked, isTrue);
    expect(clubs.cardOf(JourneyRank.jack)!.state, JourneyCardState.available);
  });

  test('level gate unlocks Jack at level 1', () {
    final snap = journeyBoardSnapshot.withLevelApplied(1);
    expect(
      snap.worldOf(JourneyWorld.diamonds).cardOf(JourneyRank.jack)!.state,
      JourneyCardState.available,
    );
  });

  test('hydrateJourneyBoard applies defeats then level gate', () {
    final progress = JourneyProgress.empty()
      ..recordDefeat(JourneyWorld.diamonds, JourneyRank.jack);
    final snap = hydrateJourneyBoard(progress: progress, playerLevel: 1);
    final diamonds = snap.worldOf(JourneyWorld.diamonds);
    expect(diamonds.cardOf(JourneyRank.jack)!.state, JourneyCardState.defeated);
    expect(diamonds.cardOf(JourneyRank.queen)!.state, JourneyCardState.available);
    expect(diamonds.cardOf(JourneyRank.queen)!.gameMode, GameMode.rummy);
  });

  test('journeyGameForRank maps royals to modes', () {
    expect(journeyGameForRank(JourneyRank.jack), GameMode.tresydos);
    expect(journeyGameForRank(JourneyRank.queen), GameMode.rummy);
    expect(journeyGameForRank(JourneyRank.king), GameMode.casinoSpeed);
    expect(journeyGameForRank(JourneyRank.ace), isNull);
  });
}
