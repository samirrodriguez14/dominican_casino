import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/journey_worlds.dart';

/// One stage-guide page in the Journey instruction deck.
class JourneyInstruction {
  const JourneyInstruction({
    required this.id,
    required this.title,
    required this.body,
  });

  /// 1-based page id matching UI pager copy.
  final int id;
  final String title;
  final String body;
}

/// Full Journey instruction catalog (session-local unlocks).
///
/// Pages 1–7 cover Diamonds through the Clubs court. Page 8 is the Hearts
/// entrance (Clubs Queen/King instruction pages are skipped — the court match
/// gifts the Ace directly). Pages 9–16 continue Hearts and Spades.
const List<JourneyInstruction> journeyInstructions = [
  JourneyInstruction(
    id: 1,
    title: 'A letter',
    body:
        'Life is a mystery that unfolds through one\'s journey.\n'
        'For some that journey is finding their way back home.\n'
        'If you can\'t remember how to get there, perhaps someone can help.',
  ),
  JourneyInstruction(
    id: 2,
    title: 'The court awaits',
    body:
        'Your path leads through the Diamond Kingdom\'s court. '
        'The Ace of Diamonds is said to hold answers — but the Jack '
        'stands between you and the King. Face him when you are ready.',
  ),
  JourneyInstruction(
    id: 3,
    title: 'The Queen awaits',
    body:
        'Jack\'s wager had a loophole — the Queen of Diamonds stands before '
        'you now. Beat her at cards, and she will take you to the King. '
        'No more tricks.',
  ),
  JourneyInstruction(
    id: 4,
    title: 'The King\'s court',
    body:
        'The Queen keeps her word — mostly. You stand before the King of '
        'Diamonds. He wagers the Ace itself. Beat him, and the path home '
        'may open.',
  ),
  JourneyInstruction(
    id: 5,
    title: 'The Ace of Diamonds',
    body:
        'You won the King\'s wager. Claim the Ace of Diamonds — the most '
        'powerful card in the world.',
  ),
  JourneyInstruction(
    id: 6,
    title: 'The Clubs road',
    body:
        'You outran the guards. Here is the entrance of what used to be '
        'the Clubs kingdom.\n'
        'They are missing, but come in and see what you can find. '
        'Remember — you are looking for a place where peace and freedom '
        'are your allies.',
  ),
  JourneyInstruction(
    id: 7,
    title: 'The Clubs court',
    body:
        'Jack led you to his family — the Queen and King of Clubs. '
        'They fled a world that traded virtue for vice. Listen carefully; '
        'their wager may open the next path home.',
  ),
  // Hearts (pages 8–11) — Clubs Queen/King letter pages skipped.
  JourneyInstruction(
    id: 8,
    title: 'The Hearts entrance',
    body:
        'Here is the entrance of the Hearts kingdom.\n'
        'You\'ll need a costume.\n'
        'Luckily with 2 Aces you hold the power to make yourself look older. '
        'Use it to go to the Hearts kingdom. Find the Jack and use what '
        'you\'ve learned to wager your way to the King to find the next Ace.',
  ),
  JourneyInstruction(
    id: 9,
    title: 'The Queen awaits',
    body:
        'Congratulations — you completed the Hearts challenge. '
        'The Queen of Hearts now stands open. Face her next.',
  ),
  JourneyInstruction(
    id: 10,
    title: 'The King\'s court',
    body:
        'The Queen falls. The King tests travelers by love. '
        'Prove your love before his throne.',
  ),
  JourneyInstruction(
    id: 11,
    title: 'Mastery of Love',
    body:
        'The King is defeated. Claim the Ace of Hearts — '
        'mastery of this kingdom\'s love.',
  ),
  JourneyInstruction(
    id: 12,
    title: 'The Spades entrance',
    body:
        'The King gave you his heart and died. You must run to the Spades '
        'kingdom before the Queen finds out.',
  ),
  // Spades (pages 13–16)
  JourneyInstruction(
    id: 13,
    title: 'The Queen awaits',
    body:
        'Congratulations — you completed the Spades challenge. '
        'The Queen of Spades now stands open. Face her next.',
  ),
  JourneyInstruction(
    id: 14,
    title: 'The King\'s court',
    body:
        'The Queen falls. The King tests travelers by strength. '
        'Prove your strength before his throne.',
  ),
  JourneyInstruction(
    id: 15,
    title: 'Mastery of Strength',
    body:
        'The King is defeated. Claim the Ace of Spades — '
        'mastery of this kingdom\'s strength.',
  ),
  JourneyInstruction(
    id: 16,
    title: 'Four Aces complete',
    body:
        'The Ace of Spades is yours. All four Aces are complete — '
        'rest until the next chapter.',
  ),
];

/// Highest instruction id in the catalog.
int get journeyInstructionCatalogSize => journeyInstructions.length;

JourneyInstruction? journeyInstructionById(int id) {
  for (final page in journeyInstructions) {
    if (page.id == id) return page;
  }
  return null;
}

/// Base page unlocked when [world]'s prior Ace is claimed (before its Jack).
///
/// Diamonds starts at page 2 after tutorial; later worlds use the prior
/// world's entry / road page as their guide.
int _worldInstructionBase(JourneyWorld world) => switch (world) {
      JourneyWorld.diamonds => 2,
      JourneyWorld.clubs => 6,
      JourneyWorld.hearts => 8,
      JourneyWorld.spades => 12,
    };

/// How many pages are unlocked for the current session board state.
///
/// Always unlocks page 1. Page 2 unlocks after Diamonds kingdom is entered.
/// Pages 3–5 unlock as Jack → Queen → King are cleared in Diamonds.
/// Page 6 (Clubs road) unlocks only after the Ace escape dialogue is finished.
/// Page 7 unlocks after Clubs Jack; page 8 (Hearts entrance) waits for the
/// Clubs Ace gift dialogue. Pages 9–16 continue across Hearts and Spades.
int journeyUnlockedThrough({
  required JourneyDisplaySnapshot snapshot,
  required bool tutorialDone,
  bool diamondsEntered = false,
  bool diamondsAceEscapeSeen = true,
  bool clubsAceGiftSeen = true,
  bool heartsAceGiftSeen = true,
}) {
  JourneyCardState? stateOf(JourneyWorld world, JourneyRank rank) =>
      snapshot.worldOf(world).cardOf(rank)?.state;

  bool defeated(JourneyWorld world, JourneyRank rank) =>
      stateOf(world, rank) == JourneyCardState.defeated;

  // Walk worlds in order; stop at the first whose Ace is not yet claimed.
  for (final world in JourneyWorld.values) {
    if (!defeated(world, JourneyRank.ace)) {
      final base = _worldInstructionBase(world);
      // Clubs: Jack unlocks court letter; Queen/King letters skipped.
      // Hearts: stay on entrance until Ace gift unlocks Spades.
      if (world == JourneyWorld.clubs) {
        if (defeated(world, JourneyRank.jack)) return base + 1; // 7
        return base; // 6
      }
      if (world == JourneyWorld.hearts) {
        return base; // 8
      }
      if (defeated(world, JourneyRank.king)) return base + 3;
      if (defeated(world, JourneyRank.queen)) return base + 2;
      if (defeated(world, JourneyRank.jack)) return base + 1;
      // World available but Jack not yet beaten.
      if (world == JourneyWorld.diamonds) {
        if (!tutorialDone || !diamondsEntered) return 1;
        return 2;
      }
      return base;
    }
    // Diamonds Ace claimed — Clubs road waits for the escape dialogue.
    if (world == JourneyWorld.diamonds && !diamondsAceEscapeSeen) {
      return 5;
    }
    // Clubs Ace claimed — Hearts letter waits for the gift dialogue.
    if (world == JourneyWorld.clubs && !clubsAceGiftSeen) {
      return 7;
    }
    // Hearts Ace claimed — Spades letter waits for the gift dialogue.
    if (world == JourneyWorld.hearts && !heartsAceGiftSeen) {
      return 8;
    }
  }

  // All four Aces claimed.
  return 16;
}
