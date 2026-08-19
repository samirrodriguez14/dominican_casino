import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:flutter/cupertino.dart';

List<TutorialStep> getCasinoTutorialSteps({
  required AppLocalizations l10n,
  required GlobalKey tableContentKey,
  required GlobalKey myDeckKey,
  required GlobalKey addButtonKey,
  required GlobalKey takeStackButtonKey,
  required GlobalKey Function(String cardId) handCardKey,
  required GlobalKey Function(String cardId) tableCardKey,
  required GlobalKey? Function() firstStackKey,
}) {
  List<GlobalKey> tableCardsOrArea() {
    final keys = <GlobalKey>[];
    for (final id in const ['table_3', 'table_9', 'table_J', 'opp_2', 'opp_4']) {
      final key = tableCardKey(id);
      if (key.currentContext != null) keys.add(key);
    }
    final stack = firstStackKey();
    if (stack != null) keys.add(stack);
    return keys.isEmpty ? [tableContentKey] : keys;
  }

  return [
    // 0
    TutorialStep(
      step: 0,
      section: 0,
      title: "Welcome",
      description: l10n.tutorialWelcome,
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 1
    TutorialStep(
      step: 1,
      section: 1,
      title: "Select your card",
      description: l10n.tutorialTapFive,
      targetKey: handCardKey("tutorial_5"),
      expectedAction: TutorialAction.selectHandCard,
      expectedCardId: "tutorial_5",
      dragIds: const ["tutorial_5"],
      dropAction: TutorialAction.addStack,
      dropToStep: 4,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.selectHandCard],
    ),

    // 2
    TutorialStep(
      step: 2,
      section: 1,
      title: "Choose a table card",
      description: l10n.tutorialTapThree,
      targetKey: tableCardKey("table_3"),
      resolveTargets: () => [tableCardKey("table_3")],
      expectedAction: TutorialAction.selectTableCard,
      expectedCardId: "table_3",
      dragIds: const ["tutorial_5", "table_3"],
      dropAction: TutorialAction.addStack,
      dropToStep: 4,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      promptAboveTable: true,
      allowedActions: [TutorialAction.selectTableCard],
    ),

    // 3
    TutorialStep(
      step: 3,
      section: 1,
      title: "Create a stack",
      description: l10n.tutorialPressAdd,
      targetKey: addButtonKey,
      expectedAction: TutorialAction.addStack,
      dragIds: const ["tutorial_5", "table_3"],
      dropAction: TutorialAction.addStack,
      dropToStep: 4,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      promptAboveTable: true,
      allowedActions: [TutorialAction.addStack],
    ),

    // 4
    TutorialStep(
      step: 4,
      section: 2,
      title: "Opponent's turn",
      description: l10n.tutorialPuliTookNine,
      targetKey: tableContentKey,
      resolveTargets: tableCardsOrArea,
      allowInteraction: false,
      blockGameInteraction: true,
      playOpponent: true,
      promptAboveTable: true,
      allowedActions: [],
    ),

    // 5
    TutorialStep(
      step: 5,
      section: 2,
      title: "Select your 8",
      description: l10n.tutorialTapEight,
      targetKey: handCardKey("tutorial_8"),
      expectedAction: TutorialAction.selectHandCard,
      expectedCardId: "tutorial_8",
      dragIds: const ["tutorial_8"],
      dropAction: TutorialAction.takeStack,
      dropToStep: 8,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.selectHandCard],
    ),

    // 6
    TutorialStep(
      step: 6,
      section: 2,
      title: "Select the stack",
      description: l10n.tutorialTapStackEight,
      targetKey: tableContentKey,
      resolveTargets: () {
        final stack = firstStackKey();
        return [stack ?? tableContentKey];
      },
      expectedAction: TutorialAction.selectStack,
      dragIds: const ["tutorial_8"],
      dropAction: TutorialAction.takeStack,
      dropToStep: 8,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      promptAboveTable: true,
      allowedActions: [TutorialAction.selectStack],
    ),

    // 7
    TutorialStep(
      step: 7,
      section: 2,
      title: "Take the stack",
      description: l10n.tutorialPressTake,
      targetKey: takeStackButtonKey,
      expectedAction: TutorialAction.takeStack,
      dragIds: const ["tutorial_8"],
      dropAction: TutorialAction.takeStack,
      dropToStep: 8,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      promptAboveTable: true,
      allowedActions: [TutorialAction.takeStack],
    ),

    // 8
    TutorialStep(
      step: 8,
      section: 3,
      title: "Opponent's turn",
      description: l10n.tutorialPuliPlayedTwo,
      targetKey: tableContentKey,
      resolveTargets: tableCardsOrArea,
      allowInteraction: false,
      blockGameInteraction: true,
      playOpponent: true,
      promptAboveTable: true,
      allowedActions: [],
    ),

    // 9 — Sweep (virao)
    TutorialStep(
      step: 9,
      section: 4,
      title: "Sweep (virao)",
      description: l10n.tutorialSweep,
      targetKey: myDeckKey,
      playOpponent: true,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 10 — overlay hidden; Round Complete popup
    TutorialStep(
      step: 10,
      section: 4,
      title: "End of round",
      description: "",
      awaitRoundStatus: true,
      showNextButton: false,
      showSkipButton: false,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 11
    TutorialStep(
      step: 11,
      section: 4,
      title: "You're ready!",
      description: l10n.tutorialReady,
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      showSkipButton: false,
      showNextButton: false,
      allowedActions: [],
    ),
  ];
}
