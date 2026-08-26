import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/models/theme_avatar_unlocks.dart';
import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_hint_pulse.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Opening story coach: Pulilo wake dialogue → letter → enter cue.
enum JourneyCoachPhase {
  /// Wake conversation before the letter.
  phaseA,

  /// Letter is open; coach is paused.
  waitingLetter,

  /// "So can you help?" → enter Diamonds cue.
  phaseB,

  finished,
}

/// Short first-visit coach for the Journey table (not the Casino match tutorial).
class JourneyCoachController extends ChangeNotifier {
  JourneyCoachController({
    required this.trailKey,
    required this.deckKey,
  });

  final GlobalKey trailKey;
  final GlobalKey deckKey;

  int _step = 0;
  bool _active = false;
  bool _finished = false;
  JourneyCoachPhase _phase = JourneyCoachPhase.finished;

  bool get isActive =>
      _active &&
      (_phase == JourneyCoachPhase.phaseA || _phase == JourneyCoachPhase.phaseB);
  bool get isFinished => _finished;
  bool get isWaitingForLetter => _phase == JourneyCoachPhase.waitingLetter;
  int get stepIndex => _step;
  JourneyCoachPhase get phase => _phase;

  static TutorialStep _line({
    required int step,
    required int section,
    required String speaker,
    required String text,
    required TutorialSpeaker who,
    GlobalKey? targetKey,
    bool showSkip = true,
    bool showNext = true,
  }) {
    return TutorialStep(
      step: step,
      section: section,
      title: speaker,
      description: text,
      speaker: who,
      targetKey: targetKey,
      blockGameInteraction: true,
      allowedActions: const <TutorialAction>[],
      showSkipButton: showSkip,
      showNextButton: showNext,
    );
  }

  List<TutorialStep> get phaseASteps => [
        _line(
          step: 0,
          section: 0,
          speaker: 'Pulilo',
          text: 'Oh, hi. You finally woke up.',
          who: TutorialSpeaker.guide,
        ),
        _line(
          step: 1,
          section: 0,
          speaker: 'You',
          text: 'Where am I?',
          who: TutorialSpeaker.player,
        ),
        _line(
          step: 2,
          section: 0,
          speaker: 'Pulilo',
          text:
              'You are at the entrance of the Diamond Kingdom. '
              'You seemed to be dead, but luckily my tea did its miracle '
              'one more time.',
          who: TutorialSpeaker.guide,
          targetKey: trailKey,
        ),
        _line(
          step: 3,
          section: 0,
          speaker: 'You',
          text: 'My head hurts… why am I here?',
          who: TutorialSpeaker.player,
        ),
        _line(
          step: 4,
          section: 1,
          speaker: 'Pulilo',
          text:
              'Well, I don\'t know, but these things were with you when I '
              'found you. This magical deck of cards has hidden instructions '
              'that only its owner can read.',
          who: TutorialSpeaker.guide,
          targetKey: deckKey,
        ),
        _line(
          step: 5,
          section: 1,
          speaker: 'You',
          text: 'How did I get here?',
          who: TutorialSpeaker.player,
        ),
        _line(
          step: 6,
          section: 1,
          speaker: 'Pulilo',
          text:
              'Well, follow these instructions and you might find out.',
          who: TutorialSpeaker.guide,
          targetKey: deckKey,
          showSkip: false,
        ),
      ];

  List<TutorialStep> get phaseBSteps => [
        _line(
          step: 0,
          section: 2,
          speaker: 'You',
          text: 'So can you help?',
          who: TutorialSpeaker.player,
        ),
        _line(
          step: 1,
          section: 2,
          speaker: 'Pulilo',
          text:
              'Oh no… That card has a Diamonds suit on it. Your help lies '
              'there in the Diamond Kingdom, my friend. Go on, and start '
              'your journey.',
          who: TutorialSpeaker.guide,
          showSkip: false,
        ),
      ];

  List<TutorialStep> get steps {
    switch (_phase) {
      case JourneyCoachPhase.phaseA:
      case JourneyCoachPhase.waitingLetter:
        return phaseASteps;
      case JourneyCoachPhase.phaseB:
        return phaseBSteps;
      case JourneyCoachPhase.finished:
        return phaseASteps;
    }
  }

  TutorialStep get currentStep {
    final list = steps;
    return list[_step.clamp(0, list.length - 1)];
  }

  int get totalSections => 3;

  int get currentSection => currentStep.section;

  bool pulsesKey(GlobalKey? key) {
    if (!isActive || key == null) return false;
    return currentStep.highlightKeys.contains(key);
  }

  void start() {
    if (_finished || _active) return;
    if (_phase == JourneyCoachPhase.waitingLetter ||
        _phase == JourneyCoachPhase.phaseB) {
      return;
    }
    _step = 0;
    _active = true;
    _phase = JourneyCoachPhase.phaseA;
    notifyListeners();
  }

  /// Pause coach and open the letter (caller expands the guide).
  void openLetter() {
    if (_phase != JourneyCoachPhase.phaseA) return;
    _active = false;
    _phase = JourneyCoachPhase.waitingLetter;
    notifyListeners();
  }

  /// Resume "so can you help?" after the letter guide closes.
  void resumePhaseB() {
    if (_phase != JourneyCoachPhase.waitingLetter) return;
    _step = 0;
    _active = true;
    _phase = JourneyCoachPhase.phaseB;
    notifyListeners();
  }

  void next() {
    if (!isActive) return;
    final list = steps;
    if (_step >= list.length - 1) {
      if (_phase == JourneyCoachPhase.phaseA) {
        openLetter();
      } else {
        finish();
      }
      return;
    }
    _step += 1;
    notifyListeners();
  }

  /// Skip remaining lines in the current phase.
  void skipPhase() {
    if (_phase == JourneyCoachPhase.phaseA) {
      openLetter();
      return;
    }
    if (_phase == JourneyCoachPhase.phaseB) {
      finish();
    }
  }

  void finish() {
    _active = false;
    _finished = true;
    _phase = JourneyCoachPhase.finished;
    notifyListeners();
  }

  /// Clears finished/active state so the coach can run again after a story reset.
  void reset() {
    _step = 0;
    _active = false;
    _finished = false;
    _phase = JourneyCoachPhase.finished;
    notifyListeners();
  }
}

/// Overlay host for [JourneyCoachController].
class JourneyCoachOverlay extends StatelessWidget {
  const JourneyCoachOverlay({
    super.key,
    required this.controller,
    required this.onOpenLetter,
    required this.onCompleted,
  });

  final JourneyCoachController controller;
  final VoidCallback onOpenLetter;
  final VoidCallback onCompleted;

  Future<void> _finishPhaseB(BuildContext context) async {
    controller.finish();
    await context.read<AppRepo>().completeJourneyTutorial();
    onCompleted();
  }

  void _openLetter() {
    controller.openLetter();
    onOpenLetter();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isActive) return const SizedBox.shrink();
        final step = controller.currentStep;
        final isPhaseA = controller.phase == JourneyCoachPhase.phaseA;
        final isLast =
            controller.stepIndex >= controller.steps.length - 1;
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
              currentStep: controller.stepIndex,
              totalSteps: controller.steps.length,
              canGoNext: true,
              isLastScreen: isLast,
              lastPrimaryLabel: isPhaseA
                  ? 'Open instructions'
                  : 'Open instructions',
              onPlay: () {
                if (isPhaseA) {
                  _openLetter();
                } else {
                  _finishPhaseB(context);
                }
              },
              onNext: () {
                if (isLast) {
                  if (isPhaseA) {
                    _openLetter();
                  } else {
                    _finishPhaseB(context);
                  }
                } else {
                  controller.next();
                }
              },
              onSkip: () {
                if (isPhaseA) {
                  _openLetter();
                } else {
                  _finishPhaseB(context);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

/// Pulses a Journey coach target without requiring [TutorialViewModel].
class JourneyCoachPulse extends StatelessWidget {
  const JourneyCoachPulse({
    super.key,
    required this.controller,
    required this.targetKey,
    required this.child,
    this.bounce = false,
    this.extraController,
  });

  final JourneyCoachController controller;
  final GlobalKey targetKey;
  final Widget child;
  final bool bounce;
  /// Optional second coach (Jack intro) that can also pulse this key.
  final JourneyJackIntroController? extraController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        ?extraController,
      ]),
      builder: (context, _) {
        final active = controller.pulsesKey(targetKey) ||
            (extraController?.pulsesKey(targetKey) ?? false);
        return TutorialHintPulse(
          active: active,
          bounce: bounce,
          child: child,
        );
      },
    );
  }
}

/// Post-profile Jack conversation before the first Diamonds challenge.
class JourneyJackIntroController extends ChangeNotifier {
  JourneyJackIntroController();

  static final String jackAvatarId =
      journeyAvatarId(JourneyWorld.diamonds, JourneyRank.jack);

  int _step = 0;
  bool _active = false;
  bool _finished = false;

  bool get isActive => _active;
  bool get isFinished => _finished;
  int get stepIndex => _step;

  List<TutorialStep> get steps => [
        TutorialStep(
          step: 0,
          section: 0,
          title: 'Jack',
          description:
              'Hi kid. Pricey mask you have there. Where did you get it from?',
          speaker: TutorialSpeaker.guide,
          avatarId: jackAvatarId,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: true,
          showNextButton: true,
        ),
        TutorialStep(
          step: 1,
          section: 0,
          title: 'You',
          description: 'That\'s what I\'m trying to figure out.',
          speaker: TutorialSpeaker.player,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: true,
          showNextButton: true,
        ),
        TutorialStep(
          step: 2,
          section: 0,
          title: 'Jack',
          description:
              'Oh well, I know that the King holds the most powerful card '
              'in the world. It\'s the Ace of Diamonds. He can certainly '
              'help you figure that out.',
          speaker: TutorialSpeaker.guide,
          avatarId: jackAvatarId,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: true,
          showNextButton: true,
        ),
        TutorialStep(
          step: 3,
          section: 1,
          title: 'You',
          description: 'How can I see the king?',
          speaker: TutorialSpeaker.player,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: true,
          showNextButton: true,
        ),
        TutorialStep(
          step: 4,
          section: 1,
          title: 'Jack',
          description:
              'Oh I can take you to him, if you beat me at this card game.',
          speaker: TutorialSpeaker.guide,
          avatarId: jackAvatarId,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: true,
          showNextButton: true,
        ),
        TutorialStep(
          step: 5,
          section: 1,
          title: 'You',
          description: 'Really?',
          speaker: TutorialSpeaker.player,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: true,
          showNextButton: true,
        ),
        TutorialStep(
          step: 6,
          section: 1,
          title: 'Jack',
          description:
              'Yes, silly isn\'t it? I\'ll take you there if you win. '
              'But you\'ll have to give me your pricey mask if you lose.',
          speaker: TutorialSpeaker.guide,
          avatarId: jackAvatarId,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: false,
          showNextButton: true,
        ),
      ];

  TutorialStep get currentStep => steps[_step.clamp(0, steps.length - 1)];

  int get totalSections => 2;

  int get currentSection => currentStep.section;

  bool pulsesKey(GlobalKey? key) {
    if (!_active || key == null) return false;
    return currentStep.highlightKeys.contains(key);
  }

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

/// Overlay host for [JourneyJackIntroController].
class JourneyJackIntroOverlay extends StatelessWidget {
  const JourneyJackIntroOverlay({
    super.key,
    required this.controller,
    required this.onChallenge,
  });

  final JourneyJackIntroController controller;
  final Future<void> Function() onChallenge;

  Future<void> _complete() async {
    controller.finish();
    await onChallenge();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isActive) return const SizedBox.shrink();
        final step = controller.currentStep;
        final isLast =
            controller.stepIndex >= controller.steps.length - 1;
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
              currentStep: controller.stepIndex,
              totalSteps: controller.steps.length,
              canGoNext: true,
              isLastScreen: isLast,
              lastPrimaryLabel: 'Challenge',
              onPlay: _complete,
              onNext: () {
                if (isLast) {
                  _complete();
                } else {
                  controller.next();
                }
              },
              onSkip: _complete,
            ),
          ],
        );
      },
    );
  }
}

/// After defeating Diamonds Jack: Jack loophole → Queen wager → Challenge.
class JourneyQueenIntroController extends ChangeNotifier {
  JourneyQueenIntroController();

  static final String jackAvatarId =
      journeyAvatarId(JourneyWorld.diamonds, JourneyRank.jack);
  static final String queenAvatarId =
      journeyAvatarId(JourneyWorld.diamonds, JourneyRank.queen);

  int _step = 0;
  bool _active = false;
  bool _finished = false;

  bool get isActive => _active;
  bool get isFinished => _finished;
  int get stepIndex => _step;

  static TutorialStep _line({
    required int step,
    required int section,
    required String speaker,
    required String text,
    required String? avatarId,
    required TutorialSpeaker who,
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

  List<TutorialStep> get steps => [
        _line(
          step: 0,
          section: 0,
          speaker: 'You',
          text: 'Well, where\'s the King?',
          avatarId: null,
          who: TutorialSpeaker.player,
        ),
        _line(
          step: 1,
          section: 0,
          speaker: 'Jack',
          text:
              'I know I said I\'d take you there, but first you need to '
              'see the Queen.',
          avatarId: jackAvatarId,
          who: TutorialSpeaker.guide,
        ),
        _line(
          step: 2,
          section: 0,
          speaker: 'You',
          text: 'You cheated!',
          avatarId: null,
          who: TutorialSpeaker.player,
        ),
        _line(
          step: 3,
          section: 0,
          speaker: 'Jack',
          text:
              'Well, now you see how things are run here in the Diamonds '
              'kingdom. Your Queen awaits.',
          avatarId: jackAvatarId,
          who: TutorialSpeaker.guide,
        ),
        _line(
          step: 4,
          section: 1,
          speaker: 'Queen',
          text: 'What\'s this, Jack?',
          avatarId: queenAvatarId,
          who: TutorialSpeaker.guide,
        ),
        _line(
          step: 5,
          section: 1,
          speaker: 'Jack',
          text:
              'This kid beat me at my card game. I wagered that he would '
              'see the King if he beat me, and you know we can\'t break a '
              'wager, so I used the loophole and brought him to you instead.',
          avatarId: jackAvatarId,
          who: TutorialSpeaker.guide,
        ),
        _line(
          step: 6,
          section: 1,
          speaker: 'Queen',
          text: 'You lost, huh? And why did he want to see the King?',
          avatarId: queenAvatarId,
          who: TutorialSpeaker.guide,
        ),
        _line(
          step: 7,
          section: 1,
          speaker: 'Jack',
          text:
              'Well, he seems to be just another wanderer from the Spades '
              'kingdom, but he\'s lost his memory and is trying to find his '
              'home. And he\'s got a pricey magic mask that can\'t be taken '
              'from him — he needs to willingly give it away.',
          avatarId: jackAvatarId,
          who: TutorialSpeaker.guide,
        ),
        _line(
          step: 8,
          section: 2,
          speaker: 'Queen',
          text:
              'Mmm, is that so? Well, I\'ve only ever lost a wager against '
              'my husband. Bring him over.',
          avatarId: queenAvatarId,
          who: TutorialSpeaker.guide,
        ),
        _line(
          step: 9,
          section: 2,
          speaker: 'You',
          text: 'Hello, I came here to talk to the King.',
          avatarId: null,
          who: TutorialSpeaker.player,
        ),
        _line(
          step: 10,
          section: 2,
          speaker: 'Queen',
          text:
              'I heard you were good with card games. If you win, I\'ll '
              'take you to him.',
          avatarId: queenAvatarId,
          who: TutorialSpeaker.guide,
        ),
        _line(
          step: 11,
          section: 2,
          speaker: 'You',
          text: 'You\'ll take me directly to him. No more tricks.',
          avatarId: null,
          who: TutorialSpeaker.player,
        ),
        _line(
          step: 12,
          section: 2,
          speaker: 'Queen',
          text:
              'Yes of course, but you\'ll owe me that mask if you lose.',
          avatarId: queenAvatarId,
          who: TutorialSpeaker.guide,
        ),
        _line(
          step: 13,
          section: 2,
          speaker: 'You',
          text: 'Alright, let\'s do that.',
          avatarId: null,
          who: TutorialSpeaker.player,
          showSkip: false,
        ),
      ];

  TutorialStep get currentStep => steps[_step.clamp(0, steps.length - 1)];

  int get totalSections => 3;

  int get currentSection => currentStep.section;

  bool pulsesKey(GlobalKey? key) {
    if (!_active || key == null) return false;
    return currentStep.highlightKeys.contains(key);
  }

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

/// Overlay host for [JourneyQueenIntroController].
class JourneyQueenIntroOverlay extends StatelessWidget {
  const JourneyQueenIntroOverlay({
    super.key,
    required this.controller,
    required this.onChallenge,
  });

  final JourneyQueenIntroController controller;
  final Future<void> Function() onChallenge;

  Future<void> _complete() async {
    controller.finish();
    await onChallenge();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isActive) return const SizedBox.shrink();
        final step = controller.currentStep;
        final isLast =
            controller.stepIndex >= controller.steps.length - 1;
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
              currentStep: controller.stepIndex,
              totalSteps: controller.steps.length,
              canGoNext: true,
              isLastScreen: isLast,
              lastPrimaryLabel: 'Challenge',
              onPlay: _complete,
              onNext: () {
                if (isLast) {
                  _complete();
                } else {
                  controller.next();
                }
              },
              onSkip: _complete,
            ),
          ],
        );
      },
    );
  }
}
