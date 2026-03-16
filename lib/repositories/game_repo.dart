import 'dart:async';
import 'dart:developer' as developer;

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:flutter/cupertino.dart';

class GameRepo extends ChangeNotifier {
  final FirestoreService fs;

  GameState? gameState;
  //Keeps animation ids so no replay on coming back to game
  Set<String> lastPlayedIds = {};

  StreamSubscription<GameState?>? _sub;
  GameRepo({required this.fs});

  void listenToGame(String gameId) {
    _sub?.cancel();

    _sub = fs
        .streamGame(gameId)
        .listen(
          (gs) {
            gameState = gs;
            developer.log("GameRepo.listenToGame GameState ${gs?.id}");
            notifyListeners();
          },
          onError: (e, st) {
            developer.log("GameRepo.listenToGame Error: $e");
          },
        );
  }
}
