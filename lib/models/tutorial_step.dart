import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:flutter/cupertino.dart';

typedef TutorialStepCallback = void Function(BuildContext context);

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
  final bool showNextButton;

  final TutorialStepCallback? onShow;

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
    this.showSkipButton = false,
    this.showNextButton =true,
    this.onShow,
    required this.blockGameInteraction,
    required this.allowedActions,
  });
}