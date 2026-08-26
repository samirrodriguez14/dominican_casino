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
/// Pages 1–6 cover Diamonds. Pages 7–18 mirror the same Jack → Queen →
/// King → Ace → next-world cadence for Clubs, Hearts, and Spades.
const List<JourneyInstruction> journeyInstructions = [
  JourneyInstruction(
    id: 1,
    title: 'Welcome, wanderer',
    body:
        'It seems you are lost and looking for your kingdom. '
        'Come to the Diamonds kingdom — where riches the world can offer await. '
        'Enter the kingdom when you are ready — the table theme will follow.',
  ),
  JourneyInstruction(
    id: 2,
    title: 'Prove yourself',
    body:
        'To live here you must reach the Queen — but first complete the Jack\'s challenge. '
        'Drag the face-up card to the center and begin.',
  ),
  JourneyInstruction(
    id: 3,
    title: 'The Queen awaits',
    body:
        'Congratulations — you completed the first challenge. '
        'The Queen of Diamonds now stands open. Face her next.',
  ),
  JourneyInstruction(
    id: 4,
    title: 'The King\'s court',
    body:
        'The Queen falls. The King tests travelers by tradition. '
        'Prove your ambition before his throne.',
  ),
  JourneyInstruction(
    id: 5,
    title: 'Mastery of Ambition',
    body:
        'The King is defeated. Claim the Ace of Diamonds — '
        'mastery of this kingdom\'s ambition.',
  ),
  JourneyInstruction(
    id: 6,
    title: 'The road continues',
    body:
        'The Ace is yours. A path opens toward Clubs — '
        'the next kingdom awaits when you are ready.',
  ),
  // Clubs (pages 7–10)
  JourneyInstruction(
    id: 7,
    title: 'The Queen awaits',
    body:
        'Congratulations — you completed the Clubs challenge. '
        'The Queen of Clubs now stands open. Face her next.',
  ),
  JourneyInstruction(
    id: 8,
    title: 'The King\'s court',
    body:
        'The Queen falls. The King tests travelers by freedom. '
        'Prove your freedom before his throne.',
  ),
  JourneyInstruction(
    id: 9,
    title: 'Mastery of Freedom',
    body:
        'The King is defeated. Claim the Ace of Clubs — '
        'mastery of this kingdom\'s freedom.',
  ),
  JourneyInstruction(
    id: 10,
    title: 'The road continues',
    body:
        'The Ace is yours. A path opens toward Hearts — '
        'the next kingdom awaits when you are ready.',
  ),
  // Hearts (pages 11–14)
  JourneyInstruction(
    id: 11,
    title: 'The Queen awaits',
    body:
        'Congratulations — you completed the Hearts challenge. '
        'The Queen of Hearts now stands open. Face her next.',
  ),
  JourneyInstruction(
    id: 12,
    title: 'The King\'s court',
    body:
        'The Queen falls. The King tests travelers by love. '
        'Prove your love before his throne.',
  ),
  JourneyInstruction(
    id: 13,
    title: 'Mastery of Love',
    body:
        'The King is defeated. Claim the Ace of Hearts — '
        'mastery of this kingdom\'s love.',
  ),
  JourneyInstruction(
    id: 14,
    title: 'The road continues',
    body:
        'The Ace is yours. A path opens toward Spades — '
        'the next kingdom awaits when you are ready.',
  ),
  // Spades (pages 15–18)
  JourneyInstruction(
    id: 15,
    title: 'The Queen awaits',
    body:
        'Congratulations — you completed the Spades challenge. '
        'The Queen of Spades now stands open. Face her next.',
  ),
  JourneyInstruction(
    id: 16,
    title: 'The King\'s court',
    body:
        'The Queen falls. The King tests travelers by strength. '
        'Prove your strength before his throne.',
  ),
  JourneyInstruction(
    id: 17,
    title: 'Mastery of Strength',
    body:
        'The King is defeated. Claim the Ace of Spades — '
        'mastery of this kingdom\'s strength.',
  ),
  JourneyInstruction(
    id: 18,
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
/// world's "road continues" page as their entry guide.
int _worldInstructionBase(JourneyWorld world) => switch (world) {
      JourneyWorld.diamonds => 2,
      JourneyWorld.clubs => 6,
      JourneyWorld.hearts => 10,
      JourneyWorld.spades => 14,
    };

/// How many pages are unlocked for the current session board state.
///
/// Always unlocks page 1. Page 2 unlocks after the Journey coach finishes
/// (or immediately when [tutorialDone] is already true). Pages 3–6 unlock
/// as Jack → Queen → King → Ace are cleared in Diamonds. Pages 7–18 unlock
/// the same way across Clubs, Hearts, and Spades.
int journeyUnlockedThrough({
  required JourneyDisplaySnapshot snapshot,
  required bool tutorialDone,
}) {
  JourneyCardState? stateOf(JourneyWorld world, JourneyRank rank) =>
      snapshot.worldOf(world).cardOf(rank)?.state;

  bool defeated(JourneyWorld world, JourneyRank rank) =>
      stateOf(world, rank) == JourneyCardState.defeated;

  // Walk worlds in order; stop at the first whose Ace is not yet claimed.
  for (final world in JourneyWorld.values) {
    if (!defeated(world, JourneyRank.ace)) {
      final base = _worldInstructionBase(world);
      if (defeated(world, JourneyRank.king)) return base + 3;
      if (defeated(world, JourneyRank.queen)) return base + 2;
      if (defeated(world, JourneyRank.jack)) return base + 1;
      // World available but Jack not yet beaten.
      if (world == JourneyWorld.diamonds) {
        return tutorialDone ? 2 : 1;
      }
      return base;
    }
  }

  // All four Aces claimed.
  return 18;
}
