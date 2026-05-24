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
          "Your opponent played a card and added more cards to the table.",
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

    //10
    TutorialStep(
      step: 10,
      title: "Sweep bonus",
      autoAdvance: false,

      description:
          "Now you can take all remaining cards from the table. Clearing every card is called a sweep (virao)! This gives extra points at the end of the round.",
      // expectedAction: TutorialAction.takeStack,
      allowInteraction: false,
      blockGameInteraction: false,
      allowedActions: [],
    ),
    //11
    TutorialStep(
      step: 11,
      title: "Sweep bonus",
      targetKey: myDeckKey,
      description:
          "After sweeping you'll see an extra card showing how many viraos you have (Only one player ca have viraos. If you sweep and the opponent has a virao, he'll lose his virao and next time you sweep, you'll earn one.)",
      allowInteraction: false,
      blockGameInteraction: false,
      allowedActions: [],
    ),
    // 12
    TutorialStep(
      step: 12,
      title: "Round scoring",
      description:
          "At the end of each round, points are awarded for sweeps, most cards, special cards, and more.",
      targetKey: scoreKey,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 13
    TutorialStep(
      step: 13,
      title: "You're ready!",
      description:
          "You now know the basics of Casino: build stacks, capture cards, sweep the table, and score points. Good luck!",
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),
  ];
}
