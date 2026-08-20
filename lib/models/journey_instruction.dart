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

/// Diamonds v1 instruction catalog (session-local unlocks).
const List<JourneyInstruction> journeyInstructions = [
  JourneyInstruction(
    id: 1,
    title: 'Welcome, wanderer',
    body:
        'It seems you are lost and looking for your kingdom. '
        'Come to the Diamonds kingdom — where riches the world can offer await. '
        'Swipe or tap the open challenger to enter the kingdom.',
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
];

/// Highest instruction id in the catalog.
int get journeyInstructionCatalogSize => journeyInstructions.length;

JourneyInstruction? journeyInstructionById(int id) {
  for (final page in journeyInstructions) {
    if (page.id == id) return page;
  }
  return null;
}

/// How many pages are unlocked for the current session board state.
///
/// Always unlocks page 1. Page 2 unlocks after the Journey coach finishes
/// (or immediately when [tutorialDone] is already true). Pages 3–6 unlock
/// as Jack → Queen → King → Ace are cleared in Diamonds.
int journeyUnlockedThrough({
  required JourneyDisplaySnapshot snapshot,
  required bool tutorialDone,
}) {
  final diamonds = snapshot.worldOf(JourneyWorld.diamonds);
  JourneyCardState? stateOf(JourneyRank rank) =>
      diamonds.cardOf(rank)?.state;

  if (stateOf(JourneyRank.ace) == JourneyCardState.defeated) return 6;
  if (stateOf(JourneyRank.king) == JourneyCardState.defeated) return 5;
  if (stateOf(JourneyRank.queen) == JourneyCardState.defeated) return 4;
  if (stateOf(JourneyRank.jack) == JourneyCardState.defeated) return 3;
  if (tutorialDone) return 2;
  return 1;
}
