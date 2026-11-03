import 'package:youareup/l10n/app_localizations.dart';
import 'package:youareup/models/game_state.dart';
import 'package:youareup/models/tutorial_step.dart';
import 'package:youareup/ui/app_shell/games/game_mode_how_to_overlay.dart';
import 'package:flutter/cupertino.dart';

List<TutorialStep> getBsTutorialSteps({required AppLocalizations l10n}) {
  return [
    TutorialStep(
      step: 0,
      section: 0,
      title: 'BS',
      description: l10n.tutorialBsIntro,
      blockGameInteraction: true,
      allowedActions: const [],
    ),
    TutorialStep(
      step: 1,
      section: 0,
      title: 'Objective',
      description: l10n.tutorialBsObjective,
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
        GameMode.bs,
        cardWidth: 200,
        showPlay: false,
      ),
    ),
    TutorialStep(
      step: 3,
      section: 1,
      title: 'Call BS',
      description: l10n.tutorialBsCall,
      blockGameInteraction: true,
      allowedActions: const [],
    ),
    TutorialStep(
      step: 4,
      section: 1,
      title: 'Play honestly',
      description: l10n.tutorialBsHonest,
      blockGameInteraction: true,
      allowedActions: const [],
    ),
    TutorialStep(
      step: 5,
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
