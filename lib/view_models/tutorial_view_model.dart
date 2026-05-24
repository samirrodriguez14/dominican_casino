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

  TutorialStep get step => steps[_current];
  TutorialStep get currentStepData => step;

  bool get isLastStep => _current >= steps.length - 1;

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

    if (step.allowedActions.isEmpty) {
      return true;
    }

    return step.allowedActions.contains(action);
  }

  bool tryProgress(
    TutorialAction action, {
    String? cardId,
    String? stackId,
    List<String> selectedCardIds = const [],
  }) {
    if (!_active) return true;

    if (!canPerform(action)) return false;

    if (step.expectedAction != null && step.expectedAction != action) {
      return false;
    }

    if (step.expectedCardId != null && step.expectedCardId != cardId) {
      return false;
    }

    if (step.expectedCardIds != null && step.expectedCardIds!.isNotEmpty) {
      final selectedSet = selectedCardIds.toSet();
      final expectedSet = step.expectedCardIds!.toSet();

      final hasAllExpected = expectedSet.every(selectedSet.contains);

      if (!hasAllExpected) {
        return true; // allow tap, but don't advance yet
      }
    }

    nextStep();
    return true;
  }
}
