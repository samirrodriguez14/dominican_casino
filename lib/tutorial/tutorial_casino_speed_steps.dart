import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:dominican_casino/tutorial/tutorial_casino_steps.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_how_to_overlay.dart';
import 'package:flutter/cupertino.dart';

List<TutorialStep> getCasinoSpeedTutorialSteps({
  required AppLocalizations l10n,
  required GlobalKey tableContentKey,
  required GlobalKey myDeckKey,
  required GlobalKey addButtonKey,
  required GlobalKey takeStackButtonKey,
  required GlobalKey Function(String cardId) handCardKey,
  required GlobalKey Function(String cardId) tableCardKey,
  required GlobalKey? Function() firstStackKey,
}) {
  final base = getCasinoTutorialSteps(
    l10n: l10n,
    tableContentKey: tableContentKey,
    myDeckKey: myDeckKey,
    addButtonKey: addButtonKey,
    takeStackButtonKey: takeStackButtonKey,
    handCardKey: handCardKey,
    tableCardKey: tableCardKey,
    firstStackKey: firstStackKey,
  );

  final timerStep = TutorialStep(
    step: 3,
    section: 0,
    title: 'Turn timer',
    description: l10n.tutorialSpeedTimer,
    blockGameInteraction: true,
    allowedActions: const [],
  );

  final instructionsStep = base[2].copyWith(
    onShow: (ctx) => showGameModeHowTo(
      ctx,
      GameMode.casinoSpeed,
      cardWidth: 200,
      showPlay: false,
    ),
  );

  final shifted = <TutorialStep>[
    base[0],
    base[1],
    instructionsStep,
    timerStep,
    ...base.skip(3).map((s) {
      return TutorialStep(
        step: s.step + 1,
        section: s.section,
        title: s.title,
        description: s.description,
        targetKey: s.targetKey,
        speaker: s.speaker,
        avatarId: s.avatarId,
        expectedAction: s.expectedAction,
        expectedCardId: s.expectedCardId,
        expectedStackId: s.expectedStackId,
        expectedCardIds: s.expectedCardIds,
        allowInteraction: s.allowInteraction,
        autoAdvance: s.autoAdvance,
        showSkipButton: s.showSkipButton,
        showNextButton: s.showNextButton,
        playOpponent: s.playOpponent,
        awaitRoundStatus: s.awaitRoundStatus,
        dropAction: s.dropAction,
        dropToStep: s.dropToStep == null ? null : s.dropToStep! + 1,
        dragIds: s.dragIds,
        resolveTargets: s.resolveTargets,
        promptAboveTable: s.promptAboveTable,
        promptClearance: s.promptClearance,
        onShow: s.onShow,
        blockGameInteraction: s.blockGameInteraction,
        allowedActions: s.allowedActions,
      );
    }),
  ];

  return shifted;
}

extension on TutorialStep {
  TutorialStep copyWith({TutorialStepCallback? onShow}) {
    return TutorialStep(
      step: step,
      section: section,
      title: title,
      description: description,
      targetKey: targetKey,
      speaker: speaker,
      avatarId: avatarId,
      expectedAction: expectedAction,
      expectedCardId: expectedCardId,
      expectedStackId: expectedStackId,
      expectedCardIds: expectedCardIds,
      allowInteraction: allowInteraction,
      autoAdvance: autoAdvance,
      showSkipButton: showSkipButton,
      showNextButton: showNextButton,
      playOpponent: playOpponent,
      awaitRoundStatus: awaitRoundStatus,
      dropAction: dropAction,
      dropToStep: dropToStep,
      dragIds: dragIds,
      resolveTargets: resolveTargets,
      promptAboveTable: promptAboveTable,
      promptClearance: promptClearance,
      onShow: onShow ?? this.onShow,
      blockGameInteraction: blockGameInteraction,
      allowedActions: allowedActions,
    );
  }
}
