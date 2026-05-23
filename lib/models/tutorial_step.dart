import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:flutter/cupertino.dart';

class TutorialStep {
  final int step;
  final String title;
  final String description;
  final bool blockGameInteraction;
  final List<TutorialAction> allowedActions;
  final GlobalKey? targetKey;

  final TutorialAction? expectedAction;
  final String? expectedCardId;
  final String? expectedStackId;
final List<String>? expectedCardIds;
  final bool allowInteraction;
  final bool autoAdvance;
  final bool showSkipButton;

  const TutorialStep({
    required this.step,
    required this.title,
    required this.description,
    this.targetKey,
    this.expectedAction,
    this.expectedCardId,
    this.expectedStackId,
    this.expectedCardIds,
    this.allowInteraction = true,
    this.autoAdvance = false,
    this.showSkipButton = true,
    required this.blockGameInteraction,
    required this.allowedActions,
  });
}