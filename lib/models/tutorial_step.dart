import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:flutter/cupertino.dart';

typedef TutorialStepCallback = void Function(BuildContext context);

/// Who appears beside the tutorial speech bubble.
enum TutorialSpeaker {
  /// Pulilo / journey guide (default bot avatar).
  guide,

  /// The local player.
  player,
}

class TutorialStep {
  final int step;
  final String title;
  final String description;
  final bool blockGameInteraction;
  final List<TutorialAction> allowedActions;
  final GlobalKey? targetKey;

  /// Bubble speaker; [avatarId] overrides the default for this speaker when set.
  final TutorialSpeaker speaker;

  /// Optional avatar id override (e.g. Journey Jack face).
  final String? avatarId;

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

  /// Completing this move by drag-and-drop jumps to [dropToStep].
  final TutorialAction? dropAction;
  final int? dropToStep;

  /// Card ids that may be dragged on this step (hand or table).
  final List<String> dragIds;

  /// Live lookup for highlight targets (e.g. a stack created mid-tutorial).
  final List<GlobalKey> Function()? resolveTargets;

  /// When true, the overlay prompt sits just above the table instead of
  /// next to the highlighted widget (so table cards stay visible).
  final bool promptAboveTable;

  /// Extra space between the highlight target and the prompt bubble.
  /// Keeps tappable coach targets clear of the overlay.
  final double? promptClearance;

  final TutorialStepCallback? onShow;

  const TutorialStep({
    required this.step,
    required this.title,
    required this.description,
    this.targetKey,
    this.speaker = TutorialSpeaker.guide,
    this.avatarId,
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
    this.dropAction,
    this.dropToStep,
    this.dragIds = const [],
    this.resolveTargets,
    this.promptAboveTable = false,
    this.promptClearance,
    this.onShow,
    required this.blockGameInteraction,
    required this.allowedActions,
  });

  List<GlobalKey> get highlightKeys {
    final resolved = resolveTargets?.call();
    if (resolved != null && resolved.isNotEmpty) return resolved;
    if (targetKey != null) return [targetKey!];
    return const [];
  }
}