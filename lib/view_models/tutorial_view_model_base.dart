import 'dart:convert';

import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialViewModelBase extends ChangeNotifier {
  final AppRepo appRepo;
  
  int _currentStep = 0;
  bool _isLoading = false;

  TutorialViewModelBase(this.appRepo);

  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  Player? get player => appRepo.player;
  
  int get totalSteps => 3; // Number of tutorial steps

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  Future<void> completeTutorial() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (appRepo.player != null) {
        final updatedPlayer = appRepo.player!.copyWith(completedTutorial: true);
        final SharedPreferences sp = await SharedPreferences.getInstance();
        await sp.setString("player_id", jsonEncode(updatedPlayer.toJson()));
        appRepo.player = updatedPlayer;
        appRepo.notifyListeners();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

