import 'dart:developer' as developer;

import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

import 'package:dominican_casino/models/lobby_game.dart';

class LobbyViewModel extends ChangeNotifier {
  final AppRepo _appRepo;

  LobbyViewModel({required AppRepo appRepo}) : _appRepo = appRepo;

  StreamSubscription<List<LobbyGame>>? _sub;

  List<LobbyGame> games = const [];
  String? get userId =>_appRepo.player?.id;
  bool loading = true;
  String? error;

  void startListening() {
    _sub?.cancel();
    loading = true;
    error = null;
    notifyListeners();

    _sub = _appRepo.fs.listenGames().listen(
      (list) {
        games = list;
        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (e, st) {
        developer.log("listenGames error: $e", stackTrace: st);
        loading = false;
        error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    // If your stream is realtime, refresh can just restart the subscription.
    startListening();
  }

  Future<void> createGame() async {
    await _appRepo.createGame();
  }

  Future<void> joinGame(String gameId) async {
    await _appRepo.joinGame(gameId);
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