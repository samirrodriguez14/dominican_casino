import 'package:flutter/material.dart';
import 'package:dominican_casino/ui/walkthrough/walkthrough_step.dart';

List<WalkthroughStep> getCasinoWalkthroughSteps({
  required GlobalKey deckKey,
  required GlobalKey tableKey,
  required GlobalKey playerHandKey,
  required GlobalKey myDeckKey,
  required GlobalKey oppDeckKey,
}) {
  return [
    WalkthroughStep(
      stepNumber: 0,
      title: 'Welcome to Casino!',
      description:
          'In Casino, you\'ll try to capture cards from the table by matching them. Let\'s walk through the basics!',
      targetKey: null,
      showSkipButton: true,
    ),
    WalkthroughStep(
      stepNumber: 1,
      title: 'The Dealing Deck',
      description:
          'This is the dealing deck. Cards are drawn from here to be played on the table. You cannot interact with it directly.',
      targetKey: deckKey,
      tooltipPosition: Alignment.bottomCenter,
      showSkipButton: true,
    ),
    WalkthroughStep(
      stepNumber: 2,
      title: 'Table Area',
      description:
          'Cards played on the table appear here. You\'ll match your hand cards to capture these cards. Tap to select card stacks.',
      targetKey: tableKey,
      tooltipPosition: Alignment.bottomCenter,
      showSkipButton: true,
    ),
    WalkthroughStep(
      stepNumber: 3,
      title: 'Your Hand',
      description:
          'These are the cards in your hand. Tap a card to select it, then select cards on the table to capture them.',
      targetKey: playerHandKey,
      tooltipPosition: Alignment.topCenter,
      showSkipButton: true,
    ),
    WalkthroughStep(
      stepNumber: 4,
      title: 'Your Collection',
      description:
          'Cards you capture are stored here. At the end of the round, these contribute to your score.',
      targetKey: myDeckKey,
      tooltipPosition: Alignment.topCenter,
      showSkipButton: true,
    ),
    WalkthroughStep(
      stepNumber: 5,
      title: 'Opponent\'s Collection',
      description:
          'Cards your opponent captures appear here. Keep an eye on their collection!',
      targetKey: oppDeckKey,
      tooltipPosition: Alignment.topCenter,
      showSkipButton: true,
    ),
    WalkthroughStep(
      stepNumber: 6,
      title: 'Game Rules',
      description:
          '• Match cards: Your card value must equal the sum of table cards\n• Sweep: Capture all table cards in one play\n• Build: Combine cards to make a target value\n\nGood luck!',
      targetKey: null,
      showSkipButton: false,
    ),
  ];
}
