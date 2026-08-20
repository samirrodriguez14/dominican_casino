import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_hint_pulse.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Short first-visit coach for the Journey table (not the Casino match tutorial).
class JourneyCoachController extends ChangeNotifier {
  JourneyCoachController({
    required this.pilesKey,
    required this.centerKey,
    required this.defeatedKey,
    required this.deckKey,
  });

  final GlobalKey pilesKey;
  final GlobalKey centerKey;
  final GlobalKey defeatedKey;
  final GlobalKey deckKey;

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
          title: 'The Journey',
          description:
              'This table is your path through the kingdoms. '
              'Challengers wait above, victories below.',
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: true,
          showNextButton: true,
        ),
        TutorialStep(
          step: 1,
          section: 1,
          title: 'World piles',
          description:
              'Your open challenger lives here — face-up when ready, '
              'face-down while sealed.',
          targetKey: pilesKey,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: true,
          showNextButton: true,
        ),
        TutorialStep(
          step: 2,
          section: 1,
          title: 'Challenge stage',
          description:
              'Drag or tap the face-up card into the center to challenge. '
              'Swipe the stacked card to peek at rewards.',
          targetKey: centerKey,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: true,
          showNextButton: true,
        ),
        TutorialStep(
          step: 3,
          section: 2,
          title: 'Defeated',
          description:
              'Victories gather here. Tap a defeated card anytime to replay.',
          targetKey: defeatedKey,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: true,
          showNextButton: true,
        ),
        TutorialStep(
          step: 4,
          section: 2,
          title: 'Stage guide',
          description:
              'Your instruction deck grows as you advance. '
              'Open it now to see what\'s next on your path.',
          targetKey: deckKey,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: false,
          showNextButton: true,
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
}

/// Overlay host for [JourneyCoachController].
class JourneyCoachOverlay extends StatelessWidget {
  const JourneyCoachOverlay({
    super.key,
    required this.controller,
    required this.onCompleted,
  });

  final JourneyCoachController controller;
  final VoidCallback onCompleted;

  Future<void> _complete(BuildContext context) async {
    controller.finish();
    await context.read<AppRepo>().completeJourneyTutorial();
    onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isActive) return const SizedBox.shrink();
        final step = controller.currentStep;
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
              currentStep: controller.currentSection,
              totalSteps: controller.totalSections,
              canGoNext: true,
              isLastScreen: controller.stepIndex >= controller.steps.length - 1,
              lastPrimaryLabel: 'Open instructions',
              onPlay: () => _complete(context),
              onNext: () {
                if (controller.stepIndex >= controller.steps.length - 1) {
                  _complete(context);
                } else {
                  controller.next();
                }
              },
              onSkip: () => _complete(context),
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
  });

  final JourneyCoachController controller;
  final GlobalKey targetKey;
  final Widget child;
  final bool bounce;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return TutorialHintPulse(
          active: controller.pulsesKey(targetKey),
          bounce: bounce,
          child: child,
        );
      },
    );
  }
}
