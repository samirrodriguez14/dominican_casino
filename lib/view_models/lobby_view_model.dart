import 'dart:developer' as developer;

import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

import 'package:dominican_casino/models/lobby_game.dart';

class LobbyViewModel extends ChangeNotifier {
  final AppRepo _appRepo;

  LobbyViewModel({required this._appRepo});

  StreamSubscription<List<LobbyGame>>? _sub;

  List<LobbyGame> games = const [];
  String? get userId =>_appRepo.player?.id;

  bool loading = true;
  String? error;

  void startListening(String pid) {
    _sub?.cancel();
    loading = true;
    error = null;
    notifyListeners();

    _sub = _appRepo.fs.listenGames(pid).listen(
      (list) {
        games = list.where((g)=>g.player1 ==pid || g.player2 ==pid).toList();
        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (e, st) {
        developer.log("LobbyViewModel.listenGames Error: $e", stackTrace: st);
        loading = false;
        error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> refresh(String pid) async {
    startListening(pid);
  }

  Future<void> createGame() async {
    await _appRepo.createGame();
  }

  Future<void> deleteGame(String gameId) async {
   await _appRepo.deleteGame(gameId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}