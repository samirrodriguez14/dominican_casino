import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/models/journey_progress.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter_test/flutter_test.dart';

JourneyDisplaySnapshot _openDiamondsBoard({int playerLevel = 2}) {
  return hydrateJourneyBoard(
    progress: JourneyProgress(
      diamondsEntered: true,
      diamondsJackUnlocked: true,
    ),
    playerLevel: playerLevel,
  );
}

void main() {
  test('snapshot starts with Diamonds kingdom sealed', () {
    expect(journeyBoardSnapshot.worldOf(JourneyWorld.diamonds).unlocked, isFalse);
    expect(
      journeyBoardSnapshot
          .worldOf(JourneyWorld.diamonds)
          .cardOf(JourneyRank.jack)!
          .state,
      JourneyCardState.levelLocked,
    );
  });

  test('gates: enter unlocks kingdom but keeps Jack face-down', () {
    final entered = hydrateJourneyBoard(
      progress: JourneyProgress(diamondsEntered: true),
      playerLevel: 2,
    );
    final diamonds = entered.worldOf(JourneyWorld.diamonds);
    expect(diamonds.unlocked, isTrue);
    expect(
      diamonds.cardOf(JourneyRank.jack)!.state,
      JourneyCardState.levelLocked,
    );
  });

  test('gates: jack unlock flips Jack face-up at level 1', () {
    final snap = hydrateJourneyBoard(
      progress: JourneyProgress(
        diamondsEntered: true,
        diamondsJackUnlocked: true,
      ),
      playerLevel: 1,
    );
    expect(
      snap.worldOf(JourneyWorld.diamonds).cardOf(JourneyRank.jack)!.state,
      JourneyCardState.available,
    );
  });

  test('defeat unlocks next rank and Ace unlocks next world', () {
    var snap = _openDiamondsBoard();

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

  test('hydrateJourneyBoard applies defeats then level gate', () {
    final progress = JourneyProgress(
      diamondsEntered: true,
      diamondsJackUnlocked: true,
    )..recordDefeat(JourneyWorld.diamonds, JourneyRank.jack);
    final snap = hydrateJourneyBoard(progress: progress, playerLevel: 1);
    final diamonds = snap.worldOf(JourneyWorld.diamonds);
    expect(diamonds.unlocked, isTrue);
    expect(diamonds.cardOf(JourneyRank.jack)!.state, JourneyCardState.defeated);
    expect(diamonds.cardOf(JourneyRank.queen)!.state, JourneyCardState.available);
    expect(diamonds.cardOf(JourneyRank.queen)!.gameMode, GameMode.rummy);
  });

  test('journey themes unlock only after prior Ace', () {
    final progress = JourneyProgress.empty();
    expect(progress.canUnlockThemeFor(JourneyWorld.diamonds), isTrue);
    expect(progress.canUnlockThemeFor(JourneyWorld.clubs), isFalse);
    expect(progress.canUnlockThemeFor(JourneyWorld.spades), isFalse);

    progress.recordDefeat(JourneyWorld.hearts, JourneyRank.ace);
    expect(progress.canUnlockThemeFor(JourneyWorld.spades), isTrue);
    expect(progress.hasEntered(JourneyWorld.spades), isFalse);
    expect(progress.hasEntered(JourneyWorld.hearts), isTrue);
  });

  test('diamondsJackIntroSeen persists and migrates with jack unlock', () {
    final fresh = JourneyProgress(diamondsJackIntroSeen: true);
    final roundTrip = JourneyProgress.fromJson(fresh.toJson());
    expect(roundTrip.diamondsJackIntroSeen, isTrue);

    final legacy = JourneyProgress.fromJson({
      'diamondsEntered': true,
      'diamondsJackUnlocked': true,
    });
    expect(legacy.diamondsJackIntroSeen, isTrue);
  });

  test('diamondsQueenIntroSeen persists and migrates past Queen', () {
    final fresh = JourneyProgress(diamondsQueenIntroSeen: true);
    expect(JourneyProgress.fromJson(fresh.toJson()).diamondsQueenIntroSeen, isTrue);

    final pastQueen = JourneyProgress.fromJson({
      'defeatedByWorld': {
        'diamonds': ['jack', 'queen'],
      },
    });
    expect(pastQueen.diamondsQueenIntroSeen, isTrue);

    final onlyJack = JourneyProgress.fromJson({
      'defeatedByWorld': {
        'diamonds': ['jack'],
      },
    });
    expect(onlyJack.diamondsQueenIntroSeen, isFalse);
  });
}
