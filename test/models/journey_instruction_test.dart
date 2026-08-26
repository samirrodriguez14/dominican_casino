import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/models/journey_instruction.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog has pages 1–16', () {
    expect(journeyInstructionCatalogSize, 16);
    for (var id = 1; id <= 16; id++) {
      expect(journeyInstructionById(id), isNotNull, reason: 'missing id $id');
      expect(journeyInstructionById(id)!.id, id);
    }
  });

  test('first instruction is the opening letter', () {
    final page = journeyInstructionById(1)!;
    expect(page.title, 'A letter');
    expect(page.body, contains('Life is a mystery'));
    expect(page.body, contains('finding their way back home'));
  });

  test('second instruction points toward the Ace without Jack CTA copy', () {
    final page = journeyInstructionById(2)!;
    expect(page.title, 'The court awaits');
    expect(page.body, contains('Ace of Diamonds'));
    expect(page.body.toLowerCase(), isNot(contains('unlock the next')));
  });

  test('third instruction covers Queen loophole wager', () {
    final page = journeyInstructionById(3)!;
    expect(page.title, 'The Queen awaits');
    expect(page.body, contains('loophole'));
    expect(page.body, contains('King'));
  });

  test('Clubs road letter mentions peace and freedom', () {
    final page = journeyInstructionById(6)!;
    expect(page.title, 'The Clubs road');
    expect(page.body, contains('outran the guards'));
    expect(page.body, contains('peace and freedom'));
  });

  test('Hearts entrance letter mentions costume and two Aces', () {
    final page = journeyInstructionById(8)!;
    expect(page.title, 'The Hearts entrance');
    expect(page.body, contains('costume'));
    expect(page.body, contains('2 Aces'));
  });

  test('Spades entrance letter after Hearts Ace gift', () {
    final page = journeyInstructionById(12)!;
    expect(page.title, 'The Spades entrance');
    expect(page.body, contains('gave you his heart'));
    expect(page.body, contains('Spades'));
  });

  test('journeyUnlockedThrough gates Diamonds on enter + tutorial', () {
    final snap = journeyBoardSnapshot;
    expect(
      journeyUnlockedThrough(snapshot: snap, tutorialDone: false),
      1,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: false,
      ),
      1,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
      ),
      2,
    );
  });

  test('journeyUnlockedThrough follows Diamonds defeat chain', () {
    var snap = journeyBoardSnapshot;

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.diamonds, JourneyRank.jack).worlds,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
      ),
      3,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.diamonds, JourneyRank.queen).worlds,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
      ),
      4,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.diamonds, JourneyRank.king).worlds,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
      ),
      5,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.diamonds, JourneyRank.ace).worlds,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: false,
      ),
      5,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
      ),
      6,
    );
  });

  test('Clubs skips Queen/King letters and holds Hearts until gift', () {
    var snap = journeyBoardSnapshot;
    for (final rank in JourneyRank.values) {
      snap = JourneyDisplaySnapshot(
        worlds: snap.withDefeat(JourneyWorld.diamonds, rank).worlds,
      );
    }
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
      ),
      6,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.clubs, JourneyRank.jack).worlds,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
      ),
      7,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.clubs, JourneyRank.queen).worlds,
    );
    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.clubs, JourneyRank.king).worlds,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
      ),
      7,
      reason: 'Queen/King defeats do not unlock Club letter pages',
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.clubs, JourneyRank.ace).worlds,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
        clubsAceGiftSeen: false,
      ),
      7,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
        clubsAceGiftSeen: true,
      ),
      8,
    );
  });

  test('Hearts stays on entrance until Ace gift unlocks Spades', () {
    var snap = journeyBoardSnapshot;
    for (final world in [JourneyWorld.diamonds, JourneyWorld.clubs]) {
      for (final rank in JourneyRank.values) {
        snap = JourneyDisplaySnapshot(
          worlds: snap.withDefeat(world, rank).worlds,
        );
      }
    }
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
        clubsAceGiftSeen: true,
      ),
      8,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.hearts, JourneyRank.jack).worlds,
    );
    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.hearts, JourneyRank.queen).worlds,
    );
    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.hearts, JourneyRank.king).worlds,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
        clubsAceGiftSeen: true,
      ),
      8,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.hearts, JourneyRank.ace).worlds,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
        clubsAceGiftSeen: true,
        heartsAceGiftSeen: false,
      ),
      8,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
        clubsAceGiftSeen: true,
        heartsAceGiftSeen: true,
      ),
      12,
    );
  });

  test('journeyUnlockedThrough gates Spades story pages', () {
    var snap = journeyBoardSnapshot;
    for (final world in [
      JourneyWorld.diamonds,
      JourneyWorld.clubs,
      JourneyWorld.hearts,
    ]) {
      for (final rank in JourneyRank.values) {
        snap = JourneyDisplaySnapshot(
          worlds: snap.withDefeat(world, rank).worlds,
        );
      }
    }

    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
        clubsAceGiftSeen: true,
        heartsAceGiftSeen: true,
        spadesEntered: false,
      ),
      12,
    );

    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
        clubsAceGiftSeen: true,
        heartsAceGiftSeen: true,
        spadesEntered: true,
      ),
      13,
    );

    // Court defeats do not advance Spades letters past briefing.
    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.spades, JourneyRank.jack).worlds,
    );
    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.spades, JourneyRank.queen).worlds,
    );
    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.spades, JourneyRank.king).worlds,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
        clubsAceGiftSeen: true,
        heartsAceGiftSeen: true,
        spadesEntered: true,
      ),
      13,
    );

    snap = JourneyDisplaySnapshot(
      worlds: snap.withDefeat(JourneyWorld.spades, JourneyRank.ace).worlds,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
        clubsAceGiftSeen: true,
        heartsAceGiftSeen: true,
        spadesEntered: true,
        spadesFinaleSeen: false,
      ),
      15,
    );
    expect(
      journeyUnlockedThrough(
        snapshot: snap,
        tutorialDone: true,
        diamondsEntered: true,
        diamondsAceEscapeSeen: true,
        clubsAceGiftSeen: true,
        heartsAceGiftSeen: true,
        spadesEntered: true,
        spadesFinaleSeen: true,
      ),
      16,
    );
  });
}
