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
      section: 0,
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
      section: 1,
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
      section: 1,
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
      section: 1,
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
      section: 2,
      title: "Opponent's turn",
      description:
          "Your opponent captured the 9♠. Your stack of 8 is still on the table — you'll take it next.",
      targetKey: tableKey,
      allowInteraction: false,
      blockGameInteraction: true,
      playOpponent: true,
      allowedActions: [],
    ),

    // 5
    TutorialStep(
      step: 5,
      section: 2,
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
      section: 2,
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
      section: 2,
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
      section: 3,
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
      section: 3,
      title: "Opponent collection",
      description:
          "Opponent captures appear here. The highlighted collection means that player captured cards last. At the end of the round, leftover table cards go to whoever captured last.",
      targetKey: oppDeckKey,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 10
    TutorialStep(
      step: 10,
      section: 4,
      title: "Opponent's turn",
      description:
          "Your opponent played a 2♥ next to the J♣. You can combine those with your King.",
      targetKey: tableKey,
      allowInteraction: false,
      blockGameInteraction: true,
      playOpponent: true,
      allowedActions: [],
    ),

    // 11
    TutorialStep(
      step: 11,
      section: 4,
      title: "Select your King",
      description: "Tap the K♣ in your hand. A King is worth 13.",
      targetKey: handKey,
      expectedAction: TutorialAction.selectHandCard,
      expectedCardId: "tutorial_13",
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.selectHandCard],
    ),

    // 12
    TutorialStep(
      step: 12,
      section: 4,
      title: "Select J and 2",
      description:
          "Tap the J♣ and the 2♥ on the table. Together they also total 13.",
      targetKey: tableKey,
      expectedAction: TutorialAction.selectTableCard,
      expectedCardIds: ["table_J", "opp_2"],
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.selectTableCard],
    ),

    // 13
    TutorialStep(
      step: 13,
      section: 4,
      title: "Add & Take",
      description:
          "Press Add & Take. Your King is 13, and J+2 also total 13, so you capture both cards in one move.",
      targetKey: playButtonKey,
      expectedAction: TutorialAction.sweepTable,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.sweepTable],
    ),

    // 14
    TutorialStep(
      step: 14,
      section: 4,
      title: "Add & Take",
      description:
          "Add & Take lets you combine table cards into your hand card's value and capture them right away. You added the Jack and 2 (11+2) to match your King (13), then took them.",
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 15
    TutorialStep(
      step: 15,
      section: 4,
      title: "Sweep (virao)",
      description:
          "That capture cleared the table. Clearing every card is a sweep, or virao. The extra card on your collection is the virao — it scores a bonus at the end of the round.",
      targetKey: myDeckKey,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 16 — opponent plays leftover 4; extras collect to last capturer
    TutorialStep(
      step: 16,
      section: 5,
      title: "Last cards",
      description:
          "That last card came to you because you captured last. When a round ends, leftover table cards go to whoever took last.",
      targetKey: myDeckKey,
      playOpponent: true,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 17 — overlay hidden; Round Complete popup
    TutorialStep(
      step: 17,
      section: 5,
      title: "End of round",
      description: "",
      awaitRoundStatus: true,
      showNextButton: false,
      showSkipButton: false,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 18
    TutorialStep(
      step: 18,
      section: 5,
      title: "Game status",
      description:
          "Open this anytime to see the previous round's score, go back to the lobby, or leave the match.",
      targetKey: scoreKey,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 19
    TutorialStep(
      step: 19,
      section: 5,
      title: "You're ready!",
      description:
          "You know the basics: build stacks, capture cards, sweep the table, and score. Play a real game against Puli, or head home.",
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      showSkipButton: false,
      showNextButton: false,
      allowedActions: [],
    ),
  ];
}
