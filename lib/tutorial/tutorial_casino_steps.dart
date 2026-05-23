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
}) {
  return [
    TutorialStep(
      step: 0,
      title: "Welcome",
      description: "Let's learn how to capture cards in Casino.",
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    TutorialStep(
      step: 1,
      title: "Select your card",
      description: "Tap the 5 card in your hand.",
      targetKey: handKey,
      expectedAction: TutorialAction.selectHandCard,
      expectedCardId: "tutorial_5",
      allowInteraction: true,
      autoAdvance: false,
      blockGameInteraction: false,
      allowedActions: [
        TutorialAction.selectHandCard,
      ],
    ),

 TutorialStep(
  step: 2,
  title: "Pick table cards",
  description: "Select the 2 and 3 to make 5.",
  targetKey: tableKey,
  expectedAction: TutorialAction.selectTableCard,
  expectedCardIds: [
    "tutorial_2",
    "tutorial_3",
  ],
  allowInteraction: true,
  autoAdvance: false,
  blockGameInteraction: false,
  allowedActions: [
    TutorialAction.selectTableCard,
  ],
),

    TutorialStep(
      step: 3,
      title: "Play your move",
      description: "Press Play to capture the selected cards.",
      targetKey: playButtonKey,
      expectedAction: TutorialAction.playMove,
      allowInteraction: true,
      autoAdvance: false,
      blockGameInteraction: false,
      allowedActions: [
        TutorialAction.playMove,
      ],
    ),

    TutorialStep(
      step: 4,
      title: "Nice!",
      description:
          "Captured cards go into your collection. That's how taking cards works!",
      targetKey: myDeckKey,
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    TutorialStep(
      step: 5,
      title: "Opponent's collection",
      description:
          "Your opponent's captured cards will show here. Keep an eye on it during the game.",
      targetKey: oppDeckKey,
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    TutorialStep(
      step: 6,
      title: "The dealing deck",
      description:
          "New cards are dealt from here. You don't tap this directly during normal play.",
      targetKey: deckKey,
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    TutorialStep(
      step: 7,
      title: "You're ready",
      description:
          "That's the basic flow: choose your card, select matching table cards, and play the move.",
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),
  ];
}