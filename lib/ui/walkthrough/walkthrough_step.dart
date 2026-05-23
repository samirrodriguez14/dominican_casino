import 'package:flutter/material.dart';

class WalkthroughStep {
  final int stepNumber;
  final String title;
  final String description;
  final GlobalKey? targetKey; // Widget to highlight
  final Alignment tooltipPosition; // Where to show tooltip relative to highlight
  final bool showSkipButton;
  final Duration? delay; // Delay before showing this step

  WalkthroughStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.targetKey,
    this.tooltipPosition = Alignment.bottomCenter,
    this.showSkipButton = true,
    this.delay,
  });
}
