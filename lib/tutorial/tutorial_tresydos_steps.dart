import 'package:barajando/l10n/app_localizations.dart';
import 'package:barajando/models/game_state.dart';
import 'package:barajando/models/tutorial_step.dart';
import 'package:barajando/ui/app_shell/games/game_mode_how_to_overlay.dart';
import 'package:flutter/cupertino.dart';

List<TutorialStep> getTresydosTutorialSteps({required AppLocalizations l10n}) {
  return [
    TutorialStep(
      step: 0,
      section: 0,
      title: 'Tres y Dos',
      description: l10n.tutorialTresydosIntro,
      blockGameInteraction: true,
      allowedActions: const [],
    ),
    TutorialStep(
      step: 1,
      section: 0,
      title: 'Objective',
      description: l10n.tutorialTresydosObjective,
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
        GameMode.tresydos,
        cardWidth: 200,
        showPlay: false,
      ),
    ),
    TutorialStep(
      step: 3,
      section: 1,
      title: 'Draw & discard',
      description: l10n.tutorialTresydosDraw,
      blockGameInteraction: true,
      allowedActions: const [],
    ),
    TutorialStep(
      step: 4,
      section: 1,
      title: 'Form 3 and 2',
      description: l10n.tutorialTresydosForm,
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
