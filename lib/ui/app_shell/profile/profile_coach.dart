import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_hint_pulse.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Short first-visit tip for the Profile leagues button.
class ProfileCoachController extends ChangeNotifier {
  ProfileCoachController({required this.leagueKey});

  final GlobalKey leagueKey;

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
          title: 'Your leagues',
          description:
              'Tap here to see your league standings and friends. '
              'Enter Journey kingdoms to climb into new leagues.',
          targetKey: leagueKey,
          promptClearance: 52,
          blockGameInteraction: true,
          allowedActions: const <TutorialAction>[],
          showSkipButton: true,
          showNextButton: true,
        ),
      ];

  TutorialStep get currentStep => steps[_step.clamp(0, steps.length - 1)];

  int get totalSections => 1;

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
    finish();
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

/// Overlay host for [ProfileCoachController].
class ProfileCoachOverlay extends StatelessWidget {
  const ProfileCoachOverlay({
    super.key,
    required this.controller,
    required this.onCompleted,
  });

  final ProfileCoachController controller;
  final VoidCallback onCompleted;

  Future<void> _complete(BuildContext context) async {
    controller.finish();
    await context.read<AppRepo>().completeProfileTutorial();
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
              isLastScreen: true,
              lastPrimaryLabel: 'Got it',
              topClearance: shellTopBarHeight(context),
              bottomClearance: shellBottomNavClearance(context),
              onPlay: () => _complete(context),
              onNext: () => _complete(context),
              onSkip: () => _complete(context),
            ),
          ],
        );
      },
    );
  }
}

/// Pulses a Profile coach target without requiring [TutorialViewModel].
class ProfileCoachPulse extends StatelessWidget {
  const ProfileCoachPulse({
    super.key,
    required this.controller,
    required this.targetKey,
    required this.child,
    this.bounce = false,
  });

  final ProfileCoachController controller;
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
