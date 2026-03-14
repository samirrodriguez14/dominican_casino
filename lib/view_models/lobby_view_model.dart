import 'dart:developer' as developer;

import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

import 'package:dominican_casino/models/lobby_game.dart';

class LobbyViewModel extends ChangeNotifier {
  final AppRepo _appRepo;

  LobbyViewModel({required AppRepo appRepo}): _appRepo = appRepo; 

  StreamSubscription<List<LobbyGame>>? _sub;

  List<LobbyGame> games = const [];
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
                .where((g) => g.player1 == pid || g.player2 == pid)
                .toList();
            games.sort((a, b) {
              final aTurn = a.currentTurnPlayerId == pid;
              final bTurn = b.currentTurnPlayerId == pid;

              if (aTurn && !bTurn) return -1;
              if (!aTurn && bTurn) return 1;
              return 0;
            });
            loading = false;
            error = null;
            notifyListeners();
          },
          onError: (e, st) {
            developer.log(
              "LobbyViewModel.listenGames Error: $e",
              stackTrace: st,
            );
            loading = false;
            error = e.toString();
            notifyListeners();
          },
        );
  }

  Future<void> deleteGame(String gameId) async {
    await _appRepo.fs.deleteGame(gameId);
  }

  Future<void> onDelete(BuildContext context, String gid) async {
    () async {
      final ok = await confirmDelete(context, gid);
      if (!ok) return;
      await deleteGame(gid);
    };
  }

  Future<bool> confirmDelete(BuildContext context, String gameId) async {
    final res = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Delete game?"),
        content: Text("Game: $gameId"),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
