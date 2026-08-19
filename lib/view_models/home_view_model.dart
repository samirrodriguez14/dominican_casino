import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/cupertino.dart';

class HomeViewModel extends ChangeNotifier {
  final AppRepo _appRepo;
  String? get name => _appRepo.player?.name;
  Player? get player => _appRepo.player;
  HomeViewModel({required AppRepo appRepo}) : _appRepo = appRepo;
  bool loading = true;
  String? error;

  Future<void> loadPlayer() async {
    try {
      await _appRepo.loadApp();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    loading = true;
    error = null;
    notifyListeners();
    await loadPlayer();
  }

  Future<void> updatePlayerName(String name) async {
    await _appRepo.updatePlayer(name);
    notifyListeners();
  }

  Future<GoogleAuthResult> linkGoogle() async {
    final result = await _appRepo.linkGoogleAccount();
    notifyListeners();
    return result;
  }

  Future<GoogleAuthResult> linkApple() async {
    final result = await _appRepo.linkAppleAccount();
    notifyListeners();
    return result;
  }
}
