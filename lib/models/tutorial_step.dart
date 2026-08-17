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

  /// When true, the tutorial bot should take this turn (e.g. after Add).
  final bool playOpponent;

  /// Hide the overlay and wait for the round-status popup (end of scripted round).
  final bool awaitRoundStatus;

  /// Display chapter for the overlay pills (several screens can share one).
  final int section;

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
    this.showSkipButton = true,
    this.showNextButton =true,
    this.playOpponent = false,
    this.awaitRoundStatus = false,
    this.section = 0,
    this.onShow,
    required this.blockGameInteraction,
    required this.allowedActions,
  });
}