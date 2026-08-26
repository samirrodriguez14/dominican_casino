import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/models/avatar_catalog.dart';
import 'package:dominican_casino/models/theme_avatar_unlocks.dart';
import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_overlay.dart';
import 'package:flutter/cupertino.dart';

TutorialStep _storyLine({
  required int step,
  required int section,
  required String speaker,
  required String text,
  required TutorialSpeaker who,
  String? avatarId,
  bool showSkip = true,
}) {
  return TutorialStep(
    step: step,
    section: section,
    title: speaker,
    description: text,
    speaker: who,
    avatarId: avatarId,
    blockGameInteraction: true,
    allowedActions: const <TutorialAction>[],
    showSkipButton: showSkip,
    showNextButton: true,
  );
}

/// Shared coach-style overlay for Journey story conversations.
class JourneyStoryOverlay extends StatelessWidget {
  const JourneyStoryOverlay({
    super.key,
    required this.listenable,
    required this.isActive,
    required this.currentStep,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onComplete,
    this.lastPrimaryLabel = 'Challenge',
  });

  final Listenable listenable;
  final bool Function() isActive;
  final TutorialStep Function() currentStep;
  final int Function() stepIndex;
  final int Function() totalSteps;
  final VoidCallback onNext;
  final Future<void> Function() onComplete;
  final String lastPrimaryLabel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        if (!isActive()) return const SizedBox.shrink();
        final step = currentStep();
        final isLast = stepIndex() >= totalSteps() - 1;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: ColoredBox(
                  color: CupertinoColors.black.withValues(alpha: .28),
                ),
              ),
            ),
            TutorialOverlay(
              step: step,
              currentStep: stepIndex(),
              totalSteps: totalSteps(),
              canGoNext: true,
              isLastScreen: isLast,
              lastPrimaryLabel: lastPrimaryLabel,
              onPlay: () {
                onComplete();
              },
              onNext: () {
                if (isLast) {
                  onComplete();
                } else {
                  onNext();
                }
              },
              onSkip: () {
                onComplete();
              },
            ),
          ],
        );
      },
    );
  }
}

mixin _StoryCoachController on ChangeNotifier {
  int _step = 0;
  bool _active = false;
  bool _finished = false;

  bool get isActive => _active;
  bool get isFinished => _finished;
  int get stepIndex => _step;

  List<TutorialStep> get steps;

  TutorialStep get currentStep => steps[_step.clamp(0, steps.length - 1)];

  void start() {
    if (_finished || _active) return;
    _step = 0;
    _active = true;
    notifyListeners();
  }

  void next() {
    if (!_active) return;
    if (_step >= steps.length - 1) {
      finish();
      return;
    }
    _step += 1;
    notifyListeners();
  }

  void finish() {
    _active = false;
    _finished = true;
    notifyListeners();
  }

  void reset() {
    _step = 0;
    _active = false;
    _finished = false;
    notifyListeners();
  }
}

/// After Queen defeat: Queen presents you to the King → Challenge.
class JourneyKingIntroController extends ChangeNotifier
    with _StoryCoachController {
  static final String queenId =
      journeyAvatarId(JourneyWorld.diamonds, JourneyRank.queen);
  static final String kingId =
      journeyAvatarId(JourneyWorld.diamonds, JourneyRank.king);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'Queen',
          text: 'Alright kid, you get to see the King.',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'Queen',
          text: 'Your Highness…',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'King',
          text: 'What is this?',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: 'Queen',
          text:
              'This kid is really good at card games. I lost a wager to '
              'have you come see him. His mask has some value that we '
              'could get if he loses… but that dumb Jack said that your '
              'Ace would help him figure out where he\'s from…',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: 'King',
          text:
              'Only I have ever beaten you. And no one will beat my Queen '
              '— or me. Bring him over. I\'ll wager the Ace. I won\'t lose.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
          showSkip: false,
        ),
      ];
}

/// After claiming the Ace: court erupts → Run away.
class JourneyAceEscapeController extends ChangeNotifier
    with _StoryCoachController {
  static final String queenId =
      journeyAvatarId(JourneyWorld.diamonds, JourneyRank.queen);
  static final String kingId =
      journeyAvatarId(JourneyWorld.diamonds, JourneyRank.king);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'King',
          text: 'Give me that back!',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'You',
          text: 'No — I won it.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'Queen',
          text: 'Highness, you cannot break a wager.',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: 'King',
          text: 'I don\'t care — give it back!',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: 'Queen',
          text:
              'You cannot take it from him like that. The magic of the '
              'wager will kill you.',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: 'Queen',
          text: 'Guards! Get him!',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 6,
          section: 2,
          speaker: 'You',
          text: '...(I need to run)',
          who: TutorialSpeaker.player,
          showSkip: false,
        ),
      ];
}

/// After Enter Clubs: Jack of Clubs in the bushes → Challenge.
class JourneyClubsJackIntroController extends ChangeNotifier
    with _StoryCoachController {
  static final String jackId =
      journeyAvatarId(JourneyWorld.clubs, JourneyRank.jack);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'You',
          text: 'What does that mean?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'You',
          text: 'Magic Ace of Diamonds! Tell me where I\'m from!',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'You',
          text: 'I knew it! This doesn\'t work!',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: 'Jack',
          text: 'Hey you!',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: 'You',
          text: 'Who said that?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: 'Jack',
          text: 'Shh… it\'s me… behind the bushes!',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 6,
          section: 1,
          speaker: 'You',
          text: 'Huh?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: 'Jack',
          text:
              'I can take you where peace and freedom are your allies.',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 8,
          section: 2,
          speaker: 'You',
          text: 'How can I know I can trust you?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 9,
          section: 2,
          speaker: 'Jack',
          text: 'Come with me. There\'s no time!',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 10,
          section: 2,
          speaker: 'You',
          text:
              'No — we\'ll play a card game, and since you cannot break a '
              'wager you will promise you\'re here to help me.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 11,
          section: 2,
          speaker: 'Jack',
          text: 'Ahh… ok ok, let\'s do this fast!',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
          showSkip: false,
        ),
      ];
}

/// After beating Clubs Jack: meet the Clubs court → Challenge the King.
class JourneyClubsCourtController extends ChangeNotifier
    with _StoryCoachController {
  static final String jackId =
      journeyAvatarId(JourneyWorld.clubs, JourneyRank.jack);
  static final String queenId =
      journeyAvatarId(JourneyWorld.clubs, JourneyRank.queen);
  static final String kingId =
      journeyAvatarId(JourneyWorld.clubs, JourneyRank.king);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'Jack',
          text:
              'Father, mother — I brought a friend who\'s lost. I found him '
              'wandering at the Clubs kingdom.',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'Queen',
          text: 'Jack… you know we cannot accept strangers here.',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'You',
          text:
              'Oh no mother — I mean Jack\'s mother. You can trust me. I '
              'don\'t mean any harm. I\'m just trying to find out where I '
              'come from.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: 'You',
          text:
              'I won this Ace from the Diamonds King, and he was willing to '
              'break a wager and lie to take it from me.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: 'You',
          text:
              'I was told it could help me figure out where I came from, '
              'but I don\'t know how to use it.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: 'King',
          text:
              'Yes, that\'s how the Diamonds kingdom works. Cunning and '
              'always trying to take advantage. There was a time when '
              'ambition was in their hearts instead of greed.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 6,
          section: 2,
          speaker: 'Jack',
          text: 'Hey, wanderer — he\'s my dad. The King of Clubs.',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: 'You',
          text: 'What? Why are you here and not in your kingdom?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 8,
          section: 2,
          speaker: 'King',
          text:
              'Long story, kid. Let\'s say all kingdoms got corrupted. '
              'Their virtues turned into vices and we wanted no place in '
              'that world. Perhaps running away is our vice.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 9,
          section: 3,
          speaker: 'You',
          text: 'I want to find out where my place is too. Can you help me?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 10,
          section: 3,
          speaker: 'King',
          text: 'Well, the Ace of Diamonds won\'t do anything for you.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 11,
          section: 3,
          speaker: 'You',
          text: 'I knew it!',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 12,
          section: 3,
          speaker: 'King',
          text: 'Not by itself.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 13,
          section: 4,
          speaker: 'You',
          text: 'What does that mean?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 14,
          section: 4,
          speaker: 'King',
          text:
              'You need to collect all 4 Aces to actually use its true power.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 15,
          section: 4,
          speaker: 'You',
          text: 'There are more? Where can I find them?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 16,
          section: 4,
          speaker: 'King',
          text: 'Come — let\'s play a game and I\'ll tell you.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 17,
          section: 5,
          speaker: 'You',
          text:
              'The only thing I have to wager is this mask, but I can\'t '
              'take it off…',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 18,
          section: 5,
          speaker: 'You',
          text:
              'Oh — perhaps I can wager this deck of magic cards. It\'s '
              'supposed to give me instructions, but it seems useless.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 19,
          section: 5,
          speaker: 'King',
          text:
              'You\'re a good kiddo. Here we play for fun. But since you '
              'want so badly to find out who you are, I\'ll wager my Ace of '
              'Clubs for your promise that you\'ll do whatever it takes to '
              'not let the kingdoms corrupt you.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 20,
          section: 5,
          speaker: 'You',
          text: 'Sounds good.',
          who: TutorialSpeaker.player,
          showSkip: false,
        ),
      ];
}

/// After the Clubs court match: King offers the Ace (Claim interrupts after).
class JourneyClubsAceOfferController extends ChangeNotifier
    with _StoryCoachController {
  static final String kingId =
      journeyAvatarId(JourneyWorld.clubs, JourneyRank.king);

  bool matchWon = true;

  void configure({required bool won}) {
    matchWon = won;
  }

  @override
  List<TutorialStep> get steps => [
        if (matchWon)
          _storyLine(
            step: 0,
            section: 0,
            speaker: 'King',
            text: 'Good job, kid…',
            who: TutorialSpeaker.guide,
            avatarId: kingId,
          ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'King',
          text: 'You are proven to be worthy of my Ace of Clubs.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'King',
          text: 'I\'ve been trying to get rid of it for a long time.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 3,
          section: 0,
          speaker: 'King',
          text: 'Here — the Ace of Clubs.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
          showSkip: false,
        ),
      ];
}

/// After claiming the Clubs Ace: King sends you toward Hearts.
class JourneyClubsHeartsSendoffController extends ChangeNotifier
    with _StoryCoachController {
  static final String kingId =
      journeyAvatarId(JourneyWorld.clubs, JourneyRank.king);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'King',
          text: 'Jack — take him to the Hearts kingdom entrance.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'You',
          text: 'And what should I do then?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'King',
          text:
              'Perhaps the instructions card deck will be useful then.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
          showSkip: false,
        ),
      ];
}

/// Enter Hearts: lusty court + Jack of Hearts → Challenge.
class JourneyHeartsJackIntroController extends ChangeNotifier
    with _StoryCoachController {
  static final String jackId =
      journeyAvatarId(JourneyWorld.hearts, JourneyRank.jack);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'You',
          text:
              'Well… (if Diamonds ambition turned into greed, and Clubs '
              'freedom turned into running away, then love of Hearts must '
              'have turned into…??)',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'Someone',
          text: 'Hey handsome… want me to take that mask off of you…',
          who: TutorialSpeaker.guide,
          avatarId: 'moon',
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'Someone else',
          text: 'I bet you are pretty on the other side as well.',
          who: TutorialSpeaker.guide,
          avatarId: 'palm',
        ),
        _storyLine(
          step: 3,
          section: 0,
          speaker: 'You',
          text: 'Of course… lust…',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: 'Jack',
          text:
              'Okay ladies, leave him alone… he is clearly not from here…',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: 'You',
          text: 'What are you talking about?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 6,
          section: 1,
          speaker: 'Jack',
          text:
              'Well, that cloth might be from here, but that mask is clearly '
              'from the Clubs kingdom…',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 7,
          section: 1,
          speaker: 'Jack',
          text:
              'You know, I have been looking for them… the Queen put a price '
              'on the King of Clubs\' head…',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 8,
          section: 2,
          speaker: 'You',
          text: 'What\'s the price?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 9,
          section: 2,
          speaker: 'Jack',
          text: 'Her love… and I\'m going to win it.',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 10,
          section: 2,
          speaker: 'Jack',
          text:
              'So why don\'t you tell me where you got that mask from already, '
              'wanderer.',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 11,
          section: 2,
          speaker: 'You',
          text: 'Well… I would tell you, but I can\'t.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 12,
          section: 3,
          speaker: 'Jack',
          text:
              'Ohhh. I see what it is. It\'s the magic mask that you can only '
              'willingly give.',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 13,
          section: 3,
          speaker: 'Jack',
          text: 'Let\'s do this. We…',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 14,
          section: 3,
          speaker: 'You',
          text:
              'Play a card game — if you win you\'ll have it; if I win you '
              'take me to the King.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 15,
          section: 3,
          speaker: 'Jack',
          text:
              'Oh I like you… but no. If I win, you take me to wherever you '
              'got that mask…',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 16,
          section: 3,
          speaker: 'You',
          text: 'Deal…',
          who: TutorialSpeaker.player,
          showSkip: false,
        ),
      ];
}

/// After beating Hearts Jack: escort to the Queen → Challenge.
class JourneyHeartsQueenEscortController extends ChangeNotifier
    with _StoryCoachController {
  static final String jackId =
      journeyAvatarId(JourneyWorld.hearts, JourneyRank.jack);
  static final String queenId =
      journeyAvatarId(JourneyWorld.hearts, JourneyRank.queen);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'You',
          text: 'Where\'s the King? You cannot break a wager.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'Queen',
          text: 'The King cannot fulfill his role…',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'Queen',
          text: 'So he didn\'t break the wager. I\'m the King.',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: 'You',
          text: 'What? Where\'s the King?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: 'Jack',
          text: 'Your Highness… his mask. It\'s from the Clubs kingdom.',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: 'Queen',
          text: 'Another attempt to win my heart, Jack?',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 6,
          section: 1,
          speaker: 'Jack',
          text:
              'If you beat him and wager to find out where he got his mask, '
              'he can take us to the Clubs kingdom.',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: 'Queen',
          text:
              'Why not just offer him something else… '
              '(winks at you provocatively)',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 8,
          section: 2,
          speaker: 'You',
          text:
              'I don\'t mean to offend you, but I\'m looking for the actual '
              'King… I know how things are run here. If you win I\'ll tell '
              'you where I got this mask from, but if I win I\'ll see the '
              'actual King… alone.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 9,
          section: 2,
          speaker: 'Queen',
          text: 'Well… agreed.',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
          showSkip: false,
        ),
      ];
}

/// After beating Hearts Queen: she presents the silent King → Challenge.
class JourneyHeartsKingIntroController extends ChangeNotifier
    with _StoryCoachController {
  static final String queenId =
      journeyAvatarId(JourneyWorld.hearts, JourneyRank.queen);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'Queen',
          text: 'Well, a wager is a wager. Here\'s your King. Good luck… with him.',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'You',
          text: 'King?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'You',
          text: '…',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: 'You',
          text:
              'Your Excellency. I came from afar to find the Ace of Hearts. '
              'I was told it will help me figure out where I am from and '
              'where my place is in this world.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: 'You',
          text:
              'I have been to other kingdoms and lust, laziness, and greed '
              'is what I have found. I was hoping that perhaps someone like '
              'you would still have the right virtue in their heart and be '
              'willing to help a lost soul like mine.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: 'King',
          text: 'Let\'s play.',
          who: TutorialSpeaker.guide,
          avatarId: journeyAvatarId(JourneyWorld.hearts, JourneyRank.king),
          showSkip: false,
        ),
      ];
}

/// After Hearts King match: Ace gift dialogue → Claim.
class JourneyHeartsAceOfferController extends ChangeNotifier
    with _StoryCoachController {
  static final String kingId =
      journeyAvatarId(JourneyWorld.hearts, JourneyRank.king);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'King',
          text: '(with a breaking voice) What makes you think I\'m good?',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'You',
          text: 'The King of Clubs sent me to you…',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'King',
          text: 'Another liar saying he\'s met my friend.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: 'You',
          text: 'He gave me his Ace of Clubs.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: 'King',
          text: 'What? That can\'t be. What did you do to him?',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: 'You',
          text:
              'Nothing. I was quite surprised as well. The King of Diamonds '
              'almost killed me when he lost his to a wager with me, and the '
              'King of Clubs just handed his to me.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 6,
          section: 1,
          speaker: 'You',
          text: 'He said he was trying to get rid of it for a while.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: 'King',
          text: 'What do you want from me?',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 8,
          section: 2,
          speaker: 'You',
          text: 'He said that all the Aces will help me find out who I am.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 9,
          section: 2,
          speaker: 'You',
          text: 'He also told me to give you this. (hands out a piece of paper)',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 10,
          section: 2,
          speaker: 'King',
          text: 'Did you read this?',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 11,
          section: 3,
          speaker: 'You',
          text: 'No — he told me it was for you alone.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 12,
          section: 3,
          speaker: 'King',
          text:
              'Well… I have never had a more loyal friend, so I trust that he '
              'is doing the right thing.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 13,
          section: 3,
          speaker: 'King',
          text:
              'My Ace got destroyed a while ago. So I gave my heart to the '
              'card to try to keep lust from coming to the heart of my people.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 14,
          section: 3,
          speaker: 'King',
          text:
              'It is the only reason I\'m alive and that the kingdom hasn\'t '
              'fully fallen apart.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 15,
          section: 4,
          speaker: 'King',
          text:
              'I\'ll give it to you, but you have to promise to find the Spades '
              'kingdom and find out who you are!',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 16,
          section: 4,
          speaker: 'You',
          text: 'What — but you\'ll die!',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 17,
          section: 4,
          speaker: 'King',
          text: 'I\'ll live in the spirit of the card.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
          showSkip: false,
        ),
      ];
}

/// Enter Spades briefing → Challenge the Jack.
class JourneySpadesJackIntroController extends ChangeNotifier
    with _StoryCoachController {
  static final String jackId =
      journeyAvatarId(JourneyWorld.spades, JourneyRank.jack);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'You',
          text:
              'Younger face. Refugee cloth. Three Aces under the mask. '
              'Time to look harmless.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'Jack',
          text:
              'Another stray for the camp? Loyalty starts here. You play me — '
              'and you lose. Prove you know your place.',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'You',
          text: '…Deal.',
          who: TutorialSpeaker.player,
          showSkip: false,
        ),
      ];
}

/// After losing to Spades Jack: escort to the King → Challenge.
class JourneySpadesKingEscortController extends ChangeNotifier
    with _StoryCoachController {
  static final String jackId =
      journeyAvatarId(JourneyWorld.spades, JourneyRank.jack);
  static final String kingId =
      journeyAvatarId(JourneyWorld.spades, JourneyRank.king);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'Jack',
          text:
              'Good. You know when to fold. Come — the King will see you now.',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'Jack',
          text: 'Your Majesty. A refugee who passed my table.',
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 2,
          section: 1,
          speaker: 'King',
          text:
              'We\'ll play. This time you should not try to lose. '
              'I need to know if you\'re worth the camp — or just another liar.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
          showSkip: false,
        ),
      ];
}

/// After beating Spades King: camp origins → lead to the ruins.
class JourneySpadesCampController extends ChangeNotifier
    with _StoryCoachController {
  static final String kingId =
      journeyAvatarId(JourneyWorld.spades, JourneyRank.king);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'King',
          text: 'You fight like someone who has already lived too many lives.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'You',
          text:
              'I came for the Ace of Spades. I hold three already. '
              'They said the Aces would tell me who I am.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 1,
          speaker: 'King',
          text:
              'Three Aces… Then you are the thief the Diamonds court screamed about.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: 'You',
          text: 'I won them fair — mostly. Where is your Queen?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: 'King',
          text: 'Don\'t. Speak. Of. Her.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 5,
          section: 2,
          speaker: 'King',
          text:
              '(rage) She was taken by the field — buried with the Ace! '
              'And you stroll in wearing youth like a costume!',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 6,
          section: 2,
          speaker: 'You',
          text: '(the three Aces pulse — pushing him back)',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: 'King',
          text:
              '…Enough. Calm. If the Aces chose you, maybe you can reach what I cannot.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 8,
          section: 3,
          speaker: 'King',
          text:
              'I\'ll take you to where the Ace sleeps. Keep up — and do not drop those cards.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
          showSkip: false,
        ),
      ];
}

/// Ruins approach: spoken lines after the ruins instruction letter.
class JourneySpadesRuinsApproachController extends ChangeNotifier
    with _StoryCoachController {
  static final String kingId =
      journeyAvatarId(JourneyWorld.spades, JourneyRank.king);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'King',
          text:
              'Walk toward it. Do what you did with the Aces. '
              'The last one is hidden below.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'You',
          text: 'What happened here?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: 'King',
          text: 'Just do as I told you.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
          showSkip: false,
        ),
      ];
}

/// Ruins climax: Queen reunion → Ace claims you.
class JourneySpadesRuinsClimaxController extends ChangeNotifier
    with _StoryCoachController {
  static final String kingId =
      journeyAvatarId(JourneyWorld.spades, JourneyRank.king);
  static final String queenId =
      journeyAvatarId(JourneyWorld.spades, JourneyRank.queen);

  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'King',
          text:
              '(grabbing for your Aces — they refuse him) Give them to me! '
              'She\'s under there!',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: 'King',
          text:
              '(lifts you toward the field) Try again. Hold. Longer.',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 2,
          section: 1,
          speaker: 'Someone',
          text: 'STOP!',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: 'Someone',
          text: 'He\'s just a kid.',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: 'King',
          text: 'This can\'t be…',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 5,
          section: 2,
          speaker: 'You',
          text: 'Queen of Spades?',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 6,
          section: 2,
          speaker: 'King',
          text: '(runs — hugs her) You\'re alive…',
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: 'Queen',
          text:
              'Oh no… don\'t tell me you have all three Aces with you?',
          who: TutorialSpeaker.guide,
          avatarId: queenId,
          showSkip: false,
        ),
      ];
}

/// After claiming the Spades Ace: field breaks; the other half appears.
class JourneySpadesFinaleController extends ChangeNotifier
    with _StoryCoachController {
  @override
  List<TutorialStep> get steps => [
        _storyLine(
          step: 0,
          section: 0,
          speaker: 'You',
          text:
              'The fourth Ace settles in your hand — and the magnetic field '
              'screams. Dust. Mist. Something laughs in the dark.',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: '???',
          text: 'Hello! Did you miss me?',
          who: TutorialSpeaker.guide,
          avatarId: AvatarCatalog.otherHalfId,
          showSkip: false,
        ),
      ];
}
