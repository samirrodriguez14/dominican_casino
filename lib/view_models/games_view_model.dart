import 'dart:developer' as developer;

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/cupertino.dart';

class GamesViewModel extends ChangeNotifier {
  final AppRepo _appRepo;
  GamesViewModel({required AppRepo appRepo}) : _appRepo = appRepo;

  Future<String?> newGame(GameMode mode) async {
    try {
      String gid = await _appRepo.fs.createGame(mode);
      String? pid = _appRepo.player?.id;
      Player? playersInfo = _appRepo.player;
      if (pid != null && playersInfo != null) {
        return gid;
      }
      developer.log("game $gid, player $pid");
    } catch (e) {
      developer.log("Error");
    }
    return null;
  }

  Future<void> deleteGame(String gameId) async {
    await _appRepo.fs.deleteGame(gameId);
  }

  // Future<String?> _joinGame(
  //   String gameId,
  //   String pid,
  //   Player playersInfo,
  // ) async {
  //   return await _appRepo.fs.joinGame(gameId, pid, playersInfo.toJson());
  // }
}
