import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_how_to_overlay.dart';
import 'package:flutter/cupertino.dart';

List<TutorialStep> getRummyTutorialSteps({required AppLocalizations l10n}) {
  return [
    TutorialStep(
      step: 0,
      section: 0,
      title: 'Rummy',
      description: l10n.tutorialRummyIntro,
      blockGameInteraction: true,
      allowedActions: const [],
    ),
    TutorialStep(
      step: 1,
      section: 0,
      title: 'Objective',
      description: l10n.tutorialRummyObjective,
      blockGameInteraction: true,
      allowedActions: const [],
    ),
    TutorialStep(
      step: 2,
      section: 0,
      title: 'Instructions',
      description: l10n.readInstructions,
      blockGameInteraction: true,
      allowedActions: const [],
      onShow: (ctx) => showGameModeHowTo(
        ctx,
        GameMode.rummy,
        cardWidth: 200,
        showPlay: false,
      ),
    ),
    TutorialStep(
      step: 3,
      section: 1,
      title: 'Draw',
      description: l10n.tutorialRummyDraw,
      blockGameInteraction: true,
      allowedActions: const [],
    ),
    TutorialStep(
      step: 4,
      section: 1,
      title: 'Form groups',
      description: l10n.tutorialRummyBoxes,
      blockGameInteraction: true,
      allowedActions: const [],
    ),
    TutorialStep(
      step: 5,
      section: 1,
      title: 'Discard & win',
      description: l10n.tutorialRummyWin,
      blockGameInteraction: true,
      allowedActions: const [],
    ),
    TutorialStep(
      step: 6,
      section: 2,
      title: 'Ready',
      description: l10n.tutorialReady,
      blockGameInteraction: true,
      showSkipButton: false,
      showNextButton: false,
      allowedActions: const [],
    ),
  ];
}
