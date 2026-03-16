import 'dart:async';

import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/cupertino.dart';

class ProfileViewModel extends ChangeNotifier {
  final AppRepo _appRepo;

  Player? get player => _appRepo.player;

  ProfileViewModel({required AppRepo appRepo}) : _appRepo = appRepo;

  StreamSubscription<List<GamePillData>>? _sub;

  List<GamePillData> games = const [];
  String? get userId => _appRepo.player?.id;

  bool loading = true;
  String? error;

  void startListening(String pid) {
    _sub?.cancel();
    loading = true;
    error = null;
    notifyListeners();

    _sub = _appRepo.fs
        .listenGames(pid)
        .listen(
          (list) {
            games = list
                .where((g) => g.gameStatus == GameStatus.gameOver)
                .toList();
            loading = false;
            error = null;
            notifyListeners();
          },
          onError: (e, st) {
            loading = false;
            error = e.toString();
            notifyListeners();
          },
        );
  }

  Future<void> updatePlayerName(String name) async {
    await _appRepo.updatePlayer(name);
    notifyListeners();
  }
}
