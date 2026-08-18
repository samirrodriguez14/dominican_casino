import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:flutter/cupertino.dart';

List<TutorialStep> getCasinoTutorialSteps({
  required GlobalKey tableContentKey,
  required GlobalKey myDeckKey,
  required GlobalKey oppDeckKey,
  required GlobalKey addButtonKey,
  required GlobalKey takeStackButtonKey,
  required GlobalKey scoreKey,
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
      description:
          "Tap the 5♦ in your hand, or drag it onto the 3♥ to build a stack.",
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
      description:
          "Tap the 3♥, or drop your 5♦ on it. We'll use this to create a stack.",
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
      description:
          "Press Add, or drop the 5♦ on the 3♥, to combine them into a stack.",
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
      description:
          "Your opponent captured the 9♠. Your stack of 8 is still on the table — you'll take it next.",
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
      description:
          "Tap the 8♠ in your hand, or drag it onto the stack of 8 to take it.",
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
      description:
          "Tap the stack that totals 8, or drop your 8♠ on it. Since you created it, you can take it.",
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
      description:
          "Press Take Stack, or drop your 8♠ on the stack, to collect the cards.",
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
          "Your opponent played a 2♥ next to the J♣. Those two cards add up to 13 — the same as your King.",
      targetKey: tableContentKey,
      resolveTargets: tableCardsOrArea,
      allowInteraction: false,
      blockGameInteraction: true,
      playOpponent: true,
      promptAboveTable: true,
      allowedActions: [],
    ),

    // 11 — combine J and 2 on the table (no Add & Take)
    TutorialStep(
      step: 11,
      section: 4,
      title: "Combine J and 2",
      description:
          "Tap the J♣ and the 2♥, or drag one onto the other. Together they total 13.",
      targetKey: tableContentKey,
      resolveTargets: () => [
        tableCardKey("table_J"),
        tableCardKey("opp_2"),
      ],
      expectedAction: TutorialAction.selectTableCard,
      expectedCardIds: ["table_J", "opp_2"],
      dragIds: const ["table_J", "opp_2"],
      dropAction: TutorialAction.addStack,
      dropToStep: 13,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      promptAboveTable: true,
      allowedActions: [TutorialAction.selectTableCard],
    ),

    // 12
    TutorialStep(
      step: 12,
      section: 4,
      title: "Add them",
      description:
          "Press Add to build a stack of 13. You can also drag one card onto the other.",
      targetKey: addButtonKey,
      expectedAction: TutorialAction.addStack,
      dragIds: const ["table_J", "opp_2"],
      dropAction: TutorialAction.addStack,
      dropToStep: 13,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      promptAboveTable: true,
      allowedActions: [TutorialAction.addStack],
    ),

    // 13
    TutorialStep(
      step: 13,
      section: 4,
      title: "Select your King",
      description:
          "Tap the K♣ in your hand. A King is worth 13, so it can take that stack. You can also drag it onto the stack.",
      targetKey: handCardKey("tutorial_13"),
      expectedAction: TutorialAction.selectHandCard,
      expectedCardId: "tutorial_13",
      dragIds: const ["tutorial_13"],
      dropAction: TutorialAction.takeStack,
      dropToStep: 16,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      allowedActions: [TutorialAction.selectHandCard],
    ),

    // 14
    TutorialStep(
      step: 14,
      section: 4,
      title: "Select the stack",
      description:
          "Tap the stack of 13, or drop your King on it to take it.",
      targetKey: tableContentKey,
      resolveTargets: () {
        final stack = firstStackKey();
        return [stack ?? tableContentKey];
      },
      expectedAction: TutorialAction.selectStack,
      dragIds: const ["tutorial_13"],
      dropAction: TutorialAction.takeStack,
      dropToStep: 16,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      promptAboveTable: true,
      allowedActions: [TutorialAction.selectStack],
    ),

    // 15
    TutorialStep(
      step: 15,
      section: 4,
      title: "Take with the King",
      description:
          "Press Take Stack to capture with your King, or drop the King on the stack.",
      targetKey: takeStackButtonKey,
      expectedAction: TutorialAction.takeStack,
      dragIds: const ["tutorial_13"],
      dropAction: TutorialAction.takeStack,
      dropToStep: 16,
      allowInteraction: true,
      blockGameInteraction: false,
      showNextButton: false,
      promptAboveTable: true,
      allowedActions: [TutorialAction.takeStack],
    ),

    // 16
    TutorialStep(
      step: 16,
      section: 4,
      title: "Sweep (virao)",
      description:
          "Jack plus 2 made 13, matching your King, so you took the stack. That cleared the table — a sweep, or virao. The extra card on your collection is the bonus.",
      targetKey: myDeckKey,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 17 — opponent plays leftover 4; extras collect to last capturer
    TutorialStep(
      step: 17,
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

    // 18 — overlay hidden; Round Complete popup
    TutorialStep(
      step: 18,
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

    // 19
    TutorialStep(
      step: 19,
      section: 5,
      title: "Game status",
      description:
          "Open this anytime to see the previous round's score, go back to the lobby, or leave the match.",
      targetKey: scoreKey,
      allowInteraction: false,
      blockGameInteraction: true,
      allowedActions: [],
    ),

    // 20
    TutorialStep(
      step: 20,
      section: 5,
      title: "You're ready!",
      description:
          "You know the basics: build stacks, capture cards, sweep the table, and score. Tap or drag cards to play. Play a real game against Puli, or head home.",
      autoAdvance: false,
      allowInteraction: false,
      blockGameInteraction: true,
      showSkipButton: false,
      showNextButton: false,
      allowedActions: [],
    ),
  ];
}
