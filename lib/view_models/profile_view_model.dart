import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/cupertino.dart';

class ProfileViewModel extends ChangeNotifier {
  final AppRepo _appRepo;

  Player? get player => _appRepo.player;

  ProfileViewModel({required AppRepo appRepo}) : _appRepo = appRepo;

  Future<void> updatePlayerName(String name) async {
    await _appRepo.updatePlayer(name);
    notifyListeners();
  }

  Future<void> updatePlayerAvatar(String avatarId) async {
    await _appRepo.updatePlayerAvatar(avatarId);
    notifyListeners();
  }

  bool get isGoogleLinked => _appRepo.isGoogleLinked;

  Future<GoogleAuthResult> linkGoogle() async {
    final result = await _appRepo.linkGoogleAccount();
    notifyListeners();
    return result;
  }
}
