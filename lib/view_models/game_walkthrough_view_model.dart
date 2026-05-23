import 'package:flutter/material.dart';
import 'package:dominican_casino/ui/walkthrough/walkthrough_step.dart';

class GameWalkthroughViewModel extends ChangeNotifier {
  int _currentStep = 0;
  bool _isActive = false;
  final List<WalkthroughStep> _steps;

  GameWalkthroughViewModel({required List<WalkthroughStep> steps})
      : _steps = steps;

  int get currentStep => _currentStep;
  bool get isActive => _isActive;
  WalkthroughStep get currentStepData => _steps[_currentStep];
  int get totalSteps => _steps.length;
  List<WalkthroughStep> get steps => _steps;

  void start() {
    _isActive = true;
    _currentStep = 0;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < _steps.length - 1) {
      _currentStep++;
      notifyListeners();
    } else {
      finish();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int stepNumber) {
    if (stepNumber >= 0 && stepNumber < _steps.length) {
      _currentStep = stepNumber;
      notifyListeners();
    }
  }

  void finish() {
    _isActive = false;
    _currentStep = 0;
    notifyListeners();
  }

  void reset() {
    _isActive = false;
    _currentStep = 0;
    notifyListeners();
  }
}
