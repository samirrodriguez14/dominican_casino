import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/cupertino.dart';

class HomeViewModel extends ChangeNotifier {
  final AppRepo _appRepo;
  String? get name => _appRepo.player?.name;
  HomeViewModel({required this._appRepo});

  Future<bool> login() async {
    
    return await _appRepo.login();
  }

  Future<void> updatePlayerName(String name) async {
    await _appRepo.updatePlayer(name);
    notifyListeners();
  }
}
