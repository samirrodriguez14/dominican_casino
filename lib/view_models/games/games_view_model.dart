import 'dart:developer' as developer;

import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/cupertino.dart';

class GamesViewModel extends ChangeNotifier {
  final AppRepo _appRepo;
  GamesViewModel({required AppRepo appRepo}): _appRepo = appRepo; 

  Future<String?> newGame() async {
    try {
      String gid = await _createGame();
      String? pid = _appRepo.player?.id;
      Player? playersInfo = _appRepo.player;
      if (pid != null && playersInfo != null) {
        _joinGame(gid, pid, playersInfo);
        return gid;
      }
    } catch (e) {
      developer.log("Error");
    }
    return null;
  }

  Future<String> _createGame() async {
    return await _appRepo.fs.createGame();
  }

  Future<String?> _joinGame(
    String gameId,
    String pid,
    Player playersInfo,
  ) async {
    return await _appRepo.fs.joinGame(gameId, pid, playersInfo.toJson());
  }
}
