import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:flutter/cupertino.dart';

List<TutorialStep> getCasinoTutorialSteps({
  required GlobalKey deckKey,
  required GlobalKey tableKey,
  required GlobalKey handKey,
  required GlobalKey myDeckKey,
  required GlobalKey oppDeckKey,
  required GlobalKey playButtonKey,
  required GlobalKey addButtonKey,
  required GlobalKey takeStackButtonKey,
  required GlobalKey scoreKey,
}) {
  return [
    // 0
    TutorialStep(
      step: 0,
      title: "Welcome",
      description:
          "Let's learn how to play Casino! You'll learn how to capture cards, build stacks, sweep the table, and score points.",
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 1
    TutorialStep(
      step: 1,
      title: "Select your card",
      description: "Tap the 5♦ card in your hand.",
      targetKey: handKey,
      expectedAction: TutorialAction.selectHandCard,
      expectedCardId: "tutorial_5",
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.selectHandCard],
    ),

    // 2
    TutorialStep(
      step: 2,
      title: "Choose a table card",
      description: "Tap the 3♥ on the table. We'll use this to create a stack.",
      targetKey: tableKey,
      expectedAction: TutorialAction.selectTableCard,
      expectedCardId: "table_3",
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.selectTableCard],
    ),

    // 3
    TutorialStep(
      step: 3,
      title: "Create a stack",
      description: "Press Add to combine your selected cards into a stack.",
      targetKey: addButtonKey,
      expectedAction: TutorialAction.addStack,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.addStack],
    ),

    // 4
    TutorialStep(
      step: 4,
      title: "Opponent's turn",
      description:
          "Your opponent captured the 9♠. Your stack of 8 is still on the table — you'll take it next.",
      targetKey: tableKey,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 5
    TutorialStep(
      step: 5,
      title: "Select your 8",
      description: "Now tap the 8♠ in your hand.",
      targetKey: handKey,
      expectedAction: TutorialAction.selectHandCard,
      expectedCardId: "tutorial_8",
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.selectHandCard],
    ),

    // 6
    TutorialStep(
      step: 6,
      title: "Select the stack",
      description:
          "Tap the stack that totals 8. Since you created it, you can take it.",
      targetKey: tableKey,
      expectedAction: TutorialAction.selectStack,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.selectStack],
    ),

    // 7
    TutorialStep(
      step: 7,
      title: "Take the stack",
      description: "Press Take Stack to collect the cards.",
      targetKey: takeStackButtonKey,
      expectedAction: TutorialAction.takeStack,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.takeStack],
    ),

    // 8
    TutorialStep(
      step: 8,
      title: "Collected cards",
      description:
          "Captured cards go here. These cards count toward scoring at the end of the round.",
      targetKey: myDeckKey,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 9
    TutorialStep(
      step: 9,
      title: "Opponent collection",
      description:
          "Opponent captures appear here. The highlighted collection means that player captured cards last. At the end of the round, they receive any remaining cards on the table.",
      targetKey: oppDeckKey,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 10
    TutorialStep(
      step: 10,
      title: "Sweep the table",
      description:
          "Only the K♣ is left. Tap your K♣ — capturing the last card on the table is a sweep (virao).",
      targetKey: handKey,
      expectedAction: TutorialAction.selectHandCard,
      expectedCardId: "tutorial_13",
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.selectHandCard],
    ),

    // 11
    TutorialStep(
      step: 11,
      title: "Select the last card",
      description: "Tap the K♣ on the table.",
      targetKey: tableKey,
      expectedAction: TutorialAction.selectTableCard,
      expectedCardId: "table_13",
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.selectTableCard],
    ),

    // 12
    TutorialStep(
      step: 12,
      title: "Take to sweep",
      description:
          "Press Take. Clearing every card from the table is a sweep and scores a virao.",
      targetKey: playButtonKey,
      expectedAction: TutorialAction.sweepTable,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.sweepTable],
    ),

    // 13
    TutorialStep(
      step: 13,
      title: "Sweep bonus",
      targetKey: myDeckKey,
      description:
          "The extra card on your collection is a virao. Only one player can hold viraos. If you sweep while the opponent has one, they lose it; your next sweep then earns you one.",
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 14
    TutorialStep(
      step: 14,
      title: "Round scoring",
      description:
          "The round is over. Open scores to see points for sweeps, most cards, special cards, and more.",
      targetKey: scoreKey,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 15
    TutorialStep(
      step: 15,
      title: "You're ready!",
      description:
          "You know the basics: build stacks, capture cards, sweep the table, and score. Finish to play Puli for real, or head home.",
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      showSkipButton: false,
      allowedActions: [],
    ),
  ];
}
