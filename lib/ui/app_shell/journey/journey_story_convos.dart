import 'package:dominican_casino/l10n/journey_l10n.dart';
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
  /// Live locale flag from the Journey board (defaults to English).
  ValueGetter<bool> isEs = () => false;

  JourneyL10n get l10n => JourneyL10n(isEs());

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
          speaker: l10n.queen,
          text: l10n.t(
            'Alright kid, you get to see the King.',
            'Está bien, chico, te toca ver al Rey.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.queen,
          text: l10n.t(
            'Your Highness…',
            'Su Alteza…',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.king,
          text: l10n.t(
            'What is this?',
            '¿Qué es esto?',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: l10n.queen,
          text: l10n.t(
            'This kid is really good at card games. I lost a wager to '
            'have you come see him. His mask has some value that we '
            'could get if he loses… but that dumb Jack said that your '
            'Ace would help him figure out where he\'s from…',
            'Este chico es muy bueno en los juegos de cartas. Perdí una '
            'apuesta para que vinieras a verlo. Su máscara tiene un valor '
            'que podríamos conseguir si pierde… pero esa Jota tonta dijo '
            'que tu As le ayudaría a descubrir de dónde es…',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: l10n.king,
          text: l10n.t(
            'Only I have ever beaten you. And no one will beat my Queen '
            '— or me. Bring him over. I\'ll wager the Ace. I won\'t lose.',
            'Solo yo te he ganado alguna vez. Y nadie va a vencer a mi '
            'Reina — ni a mí. Tráelo. Apostaré el As. No voy a perder.',
          ),
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
          speaker: l10n.king,
          text: l10n.t(
            'Give me that back!',
            '¡Devuélvemelo!',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.you,
          text: l10n.t(
            'No — I won it.',
            'No — lo gané.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.queen,
          text: l10n.t(
            'Highness, you cannot break a wager.',
            'Alteza, no puedes romper una apuesta.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: l10n.king,
          text: l10n.t(
            'I don\'t care — give it back!',
            'No me importa — ¡devuélvelo!',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: l10n.queen,
          text: l10n.t(
            'You cannot take it from him like that. The magic of the '
            'wager will kill you.',
            'No puedes quitárselo así. La magia de la apuesta '
            'te matará.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: l10n.queen,
          text: l10n.t(
            'Guards! Get him!',
            '¡Guardias! ¡Atrápenlo!',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 6,
          section: 2,
          speaker: l10n.you,
          text: l10n.t(
            '...(I need to run)',
            '...(tengo que correr)',
          ),
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
          speaker: l10n.you,
          text: l10n.t(
            'What does that mean?',
            '¿Qué significa eso?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.you,
          text: l10n.t(
            'Magic Ace of Diamonds! Tell me where I\'m from!',
            '¡As mágico de Diamantes! ¡Dime de dónde soy!',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.you,
          text: l10n.t(
            'I knew it! This doesn\'t work!',
            '¡Lo sabía! ¡Esto no funciona!',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: l10n.jack,
          text: l10n.t(
            'Hey you!',
            '¡Oye, tú!',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'Who said that?',
            '¿Quién dijo eso?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: l10n.jack,
          text: l10n.t(
            'Shh… it\'s me… behind the bushes!',
            'Shh… soy yo… ¡detrás de los arbustos!',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 6,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'Huh?',
            '¿Eh?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: l10n.jack,
          text: l10n.t(
            'I can take you where peace and freedom are your allies.',
            'Puedo llevarte a donde la paz y la libertad sean tus aliadas.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 8,
          section: 2,
          speaker: l10n.you,
          text: l10n.t(
            'How can I know I can trust you?',
            '¿Cómo sé que puedo confiar en ti?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 9,
          section: 2,
          speaker: l10n.jack,
          text: l10n.t(
            'Come with me. There\'s no time!',
            'Ven conmigo. ¡No hay tiempo!',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 10,
          section: 2,
          speaker: l10n.you,
          text: l10n.t(
            'No — we\'ll play a card game, and since you cannot break a '
            'wager you will promise you\'re here to help me.',
            'No — jugaremos un juego de cartas, y como no se puede romper '
            'una apuesta, prometes que estás aquí para ayudarme.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 11,
          section: 2,
          speaker: l10n.jack,
          text: l10n.t(
            'Ahh… ok ok, let\'s do this fast!',
            'Ahh… ok ok, ¡hagamos esto rápido!',
          ),
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
          speaker: l10n.jack,
          text: l10n.t(
            'Father, mother — I brought a friend who\'s lost. I found him '
            'wandering at the Clubs kingdom.',
            'Padre, madre — traje a un amigo que está perdido. Lo encontré '
            'vagando por el reino de Tréboles.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.queen,
          text: l10n.t(
            'Jack… you know we cannot accept strangers here.',
            'Jota… sabes que no podemos aceptar extraños aquí.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.you,
          text: l10n.t(
            'Oh no mother — I mean Jack\'s mother. You can trust me. I '
            'don\'t mean any harm. I\'m just trying to find out where I '
            'come from.',
            'Ay no, madre — digo, la madre de la Jota. Pueden confiar en mí. '
            'No quiero hacer daño. Solo estoy tratando de averiguar de '
            'dónde vengo.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'I won this Ace from the Diamonds King, and he was willing to '
            'break a wager and lie to take it from me.',
            'Gané este As del Rey de Diamantes, y él estaba dispuesto a '
            'romper una apuesta y mentir para quitármelo.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'I was told it could help me figure out where I came from, '
            'but I don\'t know how to use it.',
            'Me dijeron que podría ayudarme a descubrir de dónde vengo, '
            'pero no sé cómo usarlo.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: l10n.king,
          text: l10n.t(
            'Yes, that\'s how the Diamonds kingdom works. Cunning and '
            'always trying to take advantage. There was a time when '
            'ambition was in their hearts instead of greed.',
            'Sí, así funciona el reino de Diamantes. Astutos y '
            'siempre tratando de aprovecharse. Hubo un tiempo en que '
            'la ambición estaba en sus corazones en lugar de la codicia.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 6,
          section: 2,
          speaker: l10n.jack,
          text: l10n.t(
            'Hey, wanderer — he\'s my dad. The King of Clubs.',
            'Oye, vagabundo — él es mi papá. El Rey de Tréboles.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: l10n.you,
          text: l10n.t(
            'What? Why are you here and not in your kingdom?',
            '¿Qué? ¿Por qué están aquí y no en su reino?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 8,
          section: 2,
          speaker: l10n.king,
          text: l10n.t(
            'Long story, kid. Let\'s say all kingdoms got corrupted. '
            'Their virtues turned into vices and we wanted no place in '
            'that world. Perhaps running away is our vice.',
            'Historia larga, chico. Digamos que todos los reinos se '
            'corrompieron. Sus virtudes se volvieron vicios y no '
            'quisimos tener lugar en ese mundo. Quizás huir es nuestro '
            'vicio.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 9,
          section: 3,
          speaker: l10n.you,
          text: l10n.t(
            'I want to find out where my place is too. Can you help me?',
            'Yo también quiero averiguar cuál es mi lugar. ¿Me pueden ayudar?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 10,
          section: 3,
          speaker: l10n.king,
          text: l10n.t(
            'Well, the Ace of Diamonds won\'t do anything for you.',
            'Bueno, el As de Diamantes no va a hacer nada por ti.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 11,
          section: 3,
          speaker: l10n.you,
          text: l10n.t(
            'I knew it!',
            '¡Lo sabía!',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 12,
          section: 3,
          speaker: l10n.king,
          text: l10n.t(
            'Not by itself.',
            'No por sí solo.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 13,
          section: 4,
          speaker: l10n.you,
          text: l10n.t(
            'What does that mean?',
            '¿Qué significa eso?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 14,
          section: 4,
          speaker: l10n.king,
          text: l10n.t(
            'You need to collect all 4 Aces to actually use its true power.',
            'Necesitas reunir los 4 Ases para poder usar su verdadero poder.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 15,
          section: 4,
          speaker: l10n.you,
          text: l10n.t(
            'There are more? Where can I find them?',
            '¿Hay más? ¿Dónde puedo encontrarlos?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 16,
          section: 4,
          speaker: l10n.king,
          text: l10n.t(
            'Come — let\'s play a game and I\'ll tell you.',
            'Ven — juguemos una partida y te lo cuento.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 17,
          section: 5,
          speaker: l10n.you,
          text: l10n.t(
            'The only thing I have to wager is this mask, but I can\'t '
            'take it off…',
            'Lo único que tengo para apostar es esta máscara, pero no '
            'puedo quitármela…',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 18,
          section: 5,
          speaker: l10n.you,
          text: l10n.t(
            'Oh — perhaps I can wager this deck of magic cards. It\'s '
            'supposed to give me instructions, but it seems useless.',
            'Ah — quizás puedo apostar este mazo de cartas mágicas. Se '
            'supone que me da instrucciones, pero parece inútil.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 19,
          section: 5,
          speaker: l10n.king,
          text: l10n.t(
            'You\'re a good kiddo. Here we play for fun. But since you '
            'want so badly to find out who you are, I\'ll wager my Ace of '
            'Clubs for your promise that you\'ll do whatever it takes to '
            'not let the kingdoms corrupt you.',
            'Eres un buen chico. Aquí jugamos por diversión. Pero como '
            'quieres tanto saber quién eres, apostaré mi As de '
            'Tréboles a cambio de tu promesa de que harás lo que sea '
            'necesario para que los reinos no te corrompan.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 20,
          section: 5,
          speaker: l10n.you,
          text: l10n.t(
            'Sounds good.',
            'Suena bien.',
          ),
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
            speaker: l10n.king,
            text: l10n.t(
              'Good job, kid…',
              'Buen trabajo, chico…',
            ),
            who: TutorialSpeaker.guide,
            avatarId: kingId,
          ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.king,
          text: l10n.t(
            'You are proven to be worthy of my Ace of Clubs.',
            'Has demostrado ser digno de mi As de Tréboles.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.king,
          text: l10n.t(
            'I\'ve been trying to get rid of it for a long time.',
            'He estado tratando de deshacerme de él desde hace mucho.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 3,
          section: 0,
          speaker: l10n.king,
          text: l10n.t(
            'Here — the Ace of Clubs.',
            'Aquí — el As de Tréboles.',
          ),
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
          speaker: l10n.king,
          text: l10n.t(
            'Jack — take him to the Hearts kingdom entrance.',
            'Jota — llévalo a la entrada del reino de Corazones.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.you,
          text: l10n.t(
            'And what should I do then?',
            '¿Y qué hago entonces?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.king,
          text: l10n.t(
            'Perhaps the instructions card deck will be useful then.',
            'Quizás el mazo de instrucciones te sea útil entonces.',
          ),
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
          speaker: l10n.you,
          text: l10n.t(
            'Well… (if Diamonds ambition turned into greed, and Clubs '
            'freedom turned into running away, then love of Hearts must '
            'have turned into…??)',
            'Bueno… (si la ambición de Diamantes se volvió codicia, y la '
            'libertad de Tréboles se volvió huir, entonces el amor de '
            'Corazones debió volverse…??)',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.someone,
          text: l10n.t(
            'Hey handsome… want me to take that mask off of you…',
            'Oye, guapo… ¿quieres que te quite esa máscara…',
          ),
          who: TutorialSpeaker.guide,
          avatarId: 'moon',
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.someoneElse,
          text: l10n.t(
            'I bet you are pretty on the other side as well.',
            'Apuesto a que también eres lindo del otro lado.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: 'palm',
        ),
        _storyLine(
          step: 3,
          section: 0,
          speaker: l10n.you,
          text: l10n.t(
            'Of course… lust…',
            'Claro… lujuria…',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: l10n.jack,
          text: l10n.t(
            'Okay ladies, leave him alone… he is clearly not from here…',
            'Está bien, damas, déjenlo en paz… claramente no es de aquí…',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'What are you talking about?',
            '¿De qué estás hablando?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 6,
          section: 1,
          speaker: l10n.jack,
          text: l10n.t(
            'Well, that cloth might be from here, but that mask is clearly '
            'from the Clubs kingdom…',
            'Bueno, esa tela tal vez sea de aquí, pero esa máscara '
            'claramente es del reino de Tréboles…',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 7,
          section: 1,
          speaker: l10n.jack,
          text: l10n.t(
            'You know, I have been looking for them… the Queen put a price '
            'on the King of Clubs\' head…',
            'Sabes, los he estado buscando… la Reina puso precio '
            'a la cabeza del Rey de Tréboles…',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 8,
          section: 2,
          speaker: l10n.you,
          text: l10n.t(
            'What\'s the price?',
            '¿Cuál es el precio?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 9,
          section: 2,
          speaker: l10n.jack,
          text: l10n.t(
            'Her love… and I\'m going to win it.',
            'Su amor… y yo lo voy a ganar.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 10,
          section: 2,
          speaker: l10n.jack,
          text: l10n.t(
            'So why don\'t you tell me where you got that mask from already, '
            'wanderer.',
            'Así que por qué no me dices de una vez de dónde sacaste esa '
            'máscara, vagabundo.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 11,
          section: 2,
          speaker: l10n.you,
          text: l10n.t(
            'Well… I would tell you, but I can\'t.',
            'Bueno… te lo diría, pero no puedo.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 12,
          section: 3,
          speaker: l10n.jack,
          text: l10n.t(
            'Ohhh. I see what it is. It\'s the magic mask that you can only '
            'willingly give.',
            'Ohhh. Ya veo qué es. Es la máscara mágica que solo se puede '
            'entregar de propia voluntad.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 13,
          section: 3,
          speaker: l10n.jack,
          text: l10n.t(
            'Let\'s do this. We…',
            'Hagamos esto. Nosotros…',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 14,
          section: 3,
          speaker: l10n.you,
          text: l10n.t(
            'Play a card game — if you win you\'ll have it; if I win you '
            'take me to the King.',
            'Jugamos a las cartas — si ganas te la quedas; si gano yo '
            'me llevas con el Rey.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 15,
          section: 3,
          speaker: l10n.jack,
          text: l10n.t(
            'Oh I like you… but no. If I win, you take me to wherever you '
            'got that mask…',
            'Ah, me caes bien… pero no. Si gano, me llevas a donde '
            'sacaste esa máscara…',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 16,
          section: 3,
          speaker: l10n.you,
          text: l10n.t(
            'Deal…',
            'Trato…',
          ),
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
          speaker: l10n.you,
          text: l10n.t(
            'Where\'s the King? You cannot break a wager.',
            '¿Dónde está el Rey? No puedes romper una apuesta.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.queen,
          text: l10n.t(
            'The King cannot fulfill his role…',
            'El Rey no puede cumplir su rol…',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.queen,
          text: l10n.t(
            'So he didn\'t break the wager. I\'m the King.',
            'Así que él no rompió la apuesta. Yo soy el Rey.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'What? Where\'s the King?',
            '¿Qué? ¿Dónde está el Rey?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: l10n.jack,
          text: l10n.t(
            'Your Highness… his mask. It\'s from the Clubs kingdom.',
            'Su Alteza… su máscara. Es del reino de Tréboles.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: l10n.queen,
          text: l10n.t(
            'Another attempt to win my heart, Jack?',
            '¿Otro intento de ganar mi corazón, Jota?',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 6,
          section: 1,
          speaker: l10n.jack,
          text: l10n.t(
            'If you beat him and wager to find out where he got his mask, '
            'he can take us to the Clubs kingdom.',
            'Si lo derrotas y apuestas para saber de dónde sacó su máscara, '
            'puede llevarnos al reino de Tréboles.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: l10n.queen,
          text: l10n.t(
            'Why not just offer him something else… '
            '(winks at you provocatively)',
            '¿Por qué no simplemente ofrecerle otra cosa… '
            '(te guiña el ojo de forma provocativa)',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 8,
          section: 2,
          speaker: l10n.you,
          text: l10n.t(
            'I don\'t mean to offend you, but I\'m looking for the actual '
            'King… I know how things are run here. If you win I\'ll tell '
            'you where I got this mask from, but if I win I\'ll see the '
            'actual King… alone.',
            'No quiero ofenderte, pero estoy buscando al Rey de '
            'verdad… sé cómo se hacen las cosas aquí. Si ganas te digo '
            'de dónde saqué esta máscara, pero si gano veré al Rey '
            'de verdad… solo.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 9,
          section: 2,
          speaker: l10n.queen,
          text: l10n.t(
            'Well… agreed.',
            'Bueno… de acuerdo.',
          ),
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
          speaker: l10n.queen,
          text: l10n.t(
            'Well, a wager is a wager. Here\'s your King. Good luck… with him.',
            'Bueno, una apuesta es una apuesta. Aquí está tu Rey. Buena suerte… con él.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.you,
          text: l10n.t(
            'King?',
            '¿Rey?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.you,
          text: '…',
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'Your Excellency. I came from afar to find the Ace of Hearts. '
            'I was told it will help me figure out where I am from and '
            'where my place is in this world.',
            'Su Excelencia. Vine de lejos a buscar el As de Corazones. '
            'Me dijeron que me ayudaría a descubrir de dónde soy y '
            'cuál es mi lugar en este mundo.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'I have been to other kingdoms and lust, laziness, and greed '
            'is what I have found. I was hoping that perhaps someone like '
            'you would still have the right virtue in their heart and be '
            'willing to help a lost soul like mine.',
            'He estado en otros reinos y lo que encontré fue lujuria, '
            'pereza y codicia. Esperaba que quizás alguien como '
            'usted aún tuviera la virtud correcta en el corazón y '
            'estuviera dispuesto a ayudar a un alma perdida como la mía.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: l10n.king,
          text: l10n.t(
            'Let\'s play.',
            'Juguemos.',
          ),
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
          speaker: l10n.king,
          text: l10n.t(
            '(with a breaking voice) What makes you think I\'m good?',
            '(con voz quebrada) ¿Qué te hace pensar que soy bueno?',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.you,
          text: l10n.t(
            'The King of Clubs sent me to you…',
            'El Rey de Tréboles me envió a ti…',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.king,
          text: l10n.t(
            'Another liar saying he\'s met my friend.',
            'Otro mentiroso diciendo que conoció a mi amigo.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'He gave me his Ace of Clubs.',
            'Me dio su As de Tréboles.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: l10n.king,
          text: l10n.t(
            'What? That can\'t be. What did you do to him?',
            '¿Qué? Eso no puede ser. ¿Qué le hiciste?',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 5,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'Nothing. I was quite surprised as well. The King of Diamonds '
            'almost killed me when he lost his to a wager with me, and the '
            'King of Clubs just handed his to me.',
            'Nada. Yo también me sorprendí bastante. El Rey de Diamantes '
            'casi me mata cuando perdió el suyo en una apuesta conmigo, y el '
            'Rey de Tréboles simplemente me entregó el suyo.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 6,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'He said he was trying to get rid of it for a while.',
            'Dijo que llevaba tiempo tratando de deshacerse de él.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: l10n.king,
          text: l10n.t(
            'What do you want from me?',
            '¿Qué quieres de mí?',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 8,
          section: 2,
          speaker: l10n.you,
          text: l10n.t(
            'He said that all the Aces will help me find out who I am.',
            'Dijo que todos los Ases me ayudarán a descubrir quién soy.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 9,
          section: 2,
          speaker: l10n.you,
          text: l10n.t(
            'He also told me to give you this. (hands out a piece of paper)',
            'También me dijo que te diera esto. (entrega un papel)',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 10,
          section: 2,
          speaker: l10n.king,
          text: l10n.t(
            'Did you read this?',
            '¿Leíste esto?',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 11,
          section: 3,
          speaker: l10n.you,
          text: l10n.t(
            'No — he told me it was for you alone.',
            'No — me dijo que era solo para ti.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 12,
          section: 3,
          speaker: l10n.king,
          text: l10n.t(
            'Well… I have never had a more loyal friend, so I trust that he '
            'is doing the right thing.',
            'Bueno… nunca he tenido un amigo más leal, así que confío en que '
            'está haciendo lo correcto.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 13,
          section: 3,
          speaker: l10n.king,
          text: l10n.t(
            'My Ace got destroyed a while ago. So I gave my heart to the '
            'card to try to keep lust from coming to the heart of my people.',
            'Mi As fue destruido hace tiempo. Así que di mi corazón a la '
            'carta para intentar que la lujuria no llegara al corazón de mi '
            'pueblo.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 14,
          section: 3,
          speaker: l10n.king,
          text: l10n.t(
            'It is the only reason I\'m alive and that the kingdom hasn\'t '
            'fully fallen apart.',
            'Es la única razón por la que estoy vivo y por la que el reino '
            'no se ha desmoronado del todo.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 15,
          section: 4,
          speaker: l10n.king,
          text: l10n.t(
            'I\'ll give it to you, but you have to promise to find the Spades '
            'kingdom and find out who you are!',
            'Te lo daré, pero tienes que prometer encontrar el reino de '
            'Espadas ¡y descubrir quién eres!',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 16,
          section: 4,
          speaker: l10n.you,
          text: l10n.t(
            'What — but you\'ll die!',
            '¿Qué — ¡pero te vas a morir!',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 17,
          section: 4,
          speaker: l10n.king,
          text: l10n.t(
            'I\'ll live in the spirit of the card.',
            'Viviré en el espíritu de la carta.',
          ),
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
          speaker: l10n.you,
          text: l10n.t(
            'Younger face. Refugee cloth. Three Aces under the mask. '
            'Time to look harmless.',
            'Cara más joven. Tela de refugiado. Tres Ases bajo la máscara. '
            'Hora de parecer inofensivo.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.jack,
          text: l10n.t(
            'Another stray for the camp? Loyalty starts here. You play me — '
            'and you lose. Prove you know your place.',
            '¿Otro perdido para el campamento? La lealtad empieza aquí. '
            'Juegas contra mí — y pierdes. Demuestra que sabes tu lugar.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.you,
          text: l10n.t(
            '…Deal.',
            '…Trato.',
          ),
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
          speaker: l10n.jack,
          text: l10n.t(
            'Good. You know when to fold. Come — the King will see you now.',
            'Bien. Sabes cuándo retirarte. Ven — el Rey te verá ahora.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.jack,
          text: l10n.t(
            'Your Majesty. A refugee who passed my table.',
            'Su Majestad. Un refugiado que pasó por mi mesa.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: jackId,
        ),
        _storyLine(
          step: 2,
          section: 1,
          speaker: l10n.king,
          text: l10n.t(
            'We\'ll play. This time you should not try to lose. '
            'I need to know if you\'re worth the camp — or just another liar.',
            'Jugaremos. Esta vez no intentes perder. '
            'Necesito saber si vales para el campamento — o si eres solo otro mentiroso.',
          ),
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
          speaker: l10n.king,
          text: l10n.t(
            'You fight like someone who has already lived too many lives.',
            'Luchas como alguien que ya ha vivido demasiadas vidas.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.you,
          text: l10n.t(
            'I came for the Ace of Spades. I hold three already. '
            'They said the Aces would tell me who I am.',
            'Vine por el As de Espadas. Ya tengo tres. '
            'Dijeron que los Ases me dirían quién soy.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 1,
          speaker: l10n.king,
          text: l10n.t(
            'Three Aces… Then you are the thief the Diamonds court screamed about.',
            'Tres Ases… Entonces eres el ladrón del que gritaba la corte de Diamantes.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: l10n.you,
          text: l10n.t(
            'I won them fair — mostly. Where is your Queen?',
            'Los gané limpio — casi. ¿Dónde está tu Reina?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: l10n.king,
          text: l10n.t(
            'Don\'t. Speak. Of. Her.',
            'No. Hables. De. Ella.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 5,
          section: 2,
          speaker: l10n.king,
          text: l10n.t(
            '(rage) She was taken by the field — buried with the Ace! '
            'And you stroll in wearing youth like a costume!',
            '(furia) ¡El campo se la llevó — enterrada con el As! '
            '¡Y tú llegas aquí vistiendo juventud como un disfraz!',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 6,
          section: 2,
          speaker: l10n.you,
          text: l10n.t(
            '(the three Aces pulse — pushing him back)',
            '(los tres Ases laten — empujándolo hacia atrás)',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: l10n.king,
          text: l10n.t(
            '…Enough. Calm. If the Aces chose you, maybe you can reach what I cannot.',
            '…Basta. Calma. Si los Ases te eligieron, quizás puedas alcanzar lo que yo no puedo.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 8,
          section: 3,
          speaker: l10n.king,
          text: l10n.t(
            'I\'ll take you to where the Ace sleeps. Keep up — and do not drop those cards.',
            'Te llevaré a donde duerme el As. Mantén el paso — y no sueltes esas cartas.',
          ),
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
          speaker: l10n.king,
          text: l10n.t(
            'Walk toward it. Do what you did with the Aces. '
            'The last one is hidden below.',
            'Camina hacia él. Haz lo que hiciste con los Ases. '
            'El último está oculto debajo.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.you,
          text: l10n.t(
            'What happened here?',
            '¿Qué pasó aquí?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 2,
          section: 0,
          speaker: l10n.king,
          text: l10n.t(
            'Just do as I told you.',
            'Solo haz lo que te dije.',
          ),
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
          speaker: l10n.king,
          text: l10n.t(
            '(grabbing for your Aces — they refuse him) Give them to me! '
            'She\'s under there!',
            '(agarra tus Ases — ellos lo rechazan) ¡Dámelos! '
            '¡Ella está debajo!',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.king,
          text: l10n.t(
            '(lifts you toward the field) Try again. Hold. Longer.',
            '(te alza hacia el campo) Inténtalo de nuevo. Aguanta. Más.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 2,
          section: 1,
          speaker: l10n.someone,
          text: l10n.t(
            'STOP!',
            '¡PARA!',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 3,
          section: 1,
          speaker: l10n.someone,
          text: l10n.t(
            'He\'s just a kid.',
            'Solo es un niño.',
          ),
          who: TutorialSpeaker.guide,
          avatarId: queenId,
        ),
        _storyLine(
          step: 4,
          section: 1,
          speaker: l10n.king,
          text: l10n.t(
            'This can\'t be…',
            'Esto no puede ser…',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 5,
          section: 2,
          speaker: l10n.you,
          text: l10n.t(
            'Queen of Spades?',
            '¿Reina de Espadas?',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 6,
          section: 2,
          speaker: l10n.king,
          text: l10n.t(
            '(runs — hugs her) You\'re alive…',
            '(corre — la abraza) Estás viva…',
          ),
          who: TutorialSpeaker.guide,
          avatarId: kingId,
        ),
        _storyLine(
          step: 7,
          section: 2,
          speaker: l10n.queen,
          text: l10n.t(
            'Oh no… don\'t tell me you have all three Aces with you?',
            'Ay no… ¿no me digas que tienes los tres Ases contigo?',
          ),
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
          speaker: l10n.you,
          text: l10n.t(
            'The fourth Ace settles in your hand — and the magnetic field '
            'screams. Dust. Mist. Something laughs in the dark.',
            'El cuarto As se acomoda en tu mano — y el campo magnético '
            'grita. Polvo. Niebla. Algo ríe en la oscuridad.',
          ),
          who: TutorialSpeaker.player,
        ),
        _storyLine(
          step: 1,
          section: 0,
          speaker: l10n.unknown,
          text: l10n.t(
            'Hello! Did you miss me?',
            '¡Hola! ¿Me extrañaste?',
          ),
          who: TutorialSpeaker.guide,
          avatarId: AvatarCatalog.otherHalfId,
          showSkip: false,
        ),
      ];
}
