import 'package:dominican_casino/models/tutorial_action.dart';
import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:flutter/material.dart';

class TutorialViewModel extends ChangeNotifier {
  final List<TutorialStep> steps;

  int _current = 0;
  bool _active = false;

  TutorialViewModel(this.steps);

  bool get active => _active;
  bool get isActive => _active;

  int get currentStep => _current;
  int get totalSteps => steps.length;
  int get currentSection => steps.isEmpty ? 0 : step.section;
  int get totalSections {
    if (steps.isEmpty) return 0;
    var maxSection = 0;
    for (final s in steps) {
      if (s.section > maxSection) maxSection = s.section;
    }
    return maxSection + 1;
  }

  TutorialStep get step => steps[_current];
  TutorialStep get currentStepData => step;

  bool get isLastStep => _current >= steps.length - 1;

  bool pulsesTarget({String? cardId, String? stackId, GlobalKey? key}) {
    if (!_active) return false;
    if (step.awaitRoundStatus) return false;

    if (cardId != null) {
      if (step.expectedCardId == cardId) return true;
      if (step.expectedCardIds?.contains(cardId) == true) return true;
    }
    if (stackId != null && step.expectedStackId == stackId) return true;
    if (key != null && step.highlightKeys.contains(key)) return true;
    return false;
  }

  void start() {
    if (steps.isEmpty) return;

    _active = true;
    _current = 0;
    notifyListeners();
  }

  void finish() {
    _active = false;
    _current = 0;
    notifyListeners();
  }

  void nextStep() {
    if (!_active) return;
    if (isLastStep) {
      finish();
      return;
    }
    _current++;
    notifyListeners();
  }

  void previousStep() {
    if (!_active || _current == 0) return;

    _current--;
    notifyListeners();
  }

  bool canPerform(TutorialAction action) {
    if (!_active) return true;

    if (step.blockGameInteraction) {
      return false;
    }

    if (step.dropAction == action) return true;

    if (step.allowedActions.isEmpty) {
      return true;
    }

    return step.allowedActions.contains(action);
  }

  bool allowsDrag({String? cardId, String? stackId}) {
    if (!_active) return true;
    if (step.blockGameInteraction || !step.allowInteraction) return false;

    if (step.dragIds.isNotEmpty) {
      if (cardId != null && step.dragIds.contains(cardId)) return true;
      if (stackId != null && step.dragIds.contains(stackId)) return true;
      return false;
    }

    if (step.expectedCardId != null && cardId == step.expectedCardId) {
      return true;
    }
    if (step.expectedCardIds != null &&
        cardId != null &&
        step.expectedCardIds!.contains(cardId)) {
      return true;
    }
    if (step.expectedStackId != null && stackId == step.expectedStackId) {
      return true;
    }

    return canPerform(TutorialAction.selectHandCard) ||
        canPerform(TutorialAction.selectTableCard) ||
        canPerform(TutorialAction.selectStack);
  }

  bool tryProgress(
    TutorialAction action, {
    String? cardId,
    String? stackId,
    List<String> selectedCardIds = const [],
  }) {
    if (!_active) return true;

    if (step.dropAction != null &&
        action == step.dropAction &&
        canPerform(action)) {
      final jump = step.dropToStep;
      if (jump != null && jump >= 0 && jump < steps.length) {
        _current = jump;
        notifyListeners();
        return true;
      }
      nextStep();
      return true;
    }

    if (!canPerform(action)) return false;

    if (step.expectedAction != null && step.expectedAction != action) {
      return false;
    }

    if (step.expectedCardId != null && step.expectedCardId != cardId) {
      return false;
    }

    if (step.expectedCardIds != null && step.expectedCardIds!.isNotEmpty) {
      final expectedSet = step.expectedCardIds!.toSet();
      if (cardId != null && !expectedSet.contains(cardId)) {
        return false;
      }

      final selectedSet = selectedCardIds.toSet();
      final hasAllExpected = expectedSet.every(selectedSet.contains);

      if (!hasAllExpected) {
        return true; // allow tap, but don't advance yet
      }
    }

    nextStep();
    return true;
  }
}
