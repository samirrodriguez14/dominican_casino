import 'dart:async';
import 'dart:developer' as developer;

import 'package:dominican_casino/models/game_info.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/cupertino.dart';

class GamesViewModel extends ChangeNotifier {
  final AppRepo _appRepo;

  GamesViewModel({required AppRepo appRepo}) : _appRepo = appRepo;

  List<GameInfo> get gamesInfo => _appRepo.gamesInfo;

  Future<String?> newGame(GameMode mode, bool local) async {
    try {
      String? pid = _appRepo.player?.id;
      Player? playersInfo = _appRepo.player;
      if (pid != null && playersInfo != null) {
        String gid = await _appRepo.createNewGame(mode, pid, local);
        developer.log("game $gid, player $pid");
        return gid;
      }
    } catch (e) {
      developer.log("Error Creating Game $e");
    }
    return null;
  }

  Future<void> deleteGame(String gameId) async {
    await _appRepo.fs.deleteGame(gameId);
  }

  StreamSubscription<List<GamePillData>>? _sub;

  List<GamePillData> currentGames = const [];
  /// Kept for a future history surface; not shown in the UI yet.
  List<GamePillData> previousGames = const [];

  /// Back-compat alias used by older call sites.
  List<GamePillData> get games => currentGames;

  String? get userId => _appRepo.player?.id;

  bool loading = true;
  String? error;

  List<GamePillData> get myCurrentGames {
    final uid = userId;
    if (uid == null) return const [];
    return currentGames.where((g) => g.containsPlayer(uid)).toList();
  }

  /// Current games where it is this player's turn (for FAB badge).
  int get yourTurnCount {
    final uid = userId;
    if (uid == null) return 0;
    return myCurrentGames
        .where((g) => g.isMyTurn(uid) && g.gameStatus != GameStatus.gameOver)
        .length;
  }

  bool get hasCurrentGames => myCurrentGames.isNotEmpty;

  void startListening(String pid) {
    _sub?.cancel();
    loading = true;
    error = null;
    notifyListeners();

    _sub = _appRepo.fs
        .listenGames(pid)
        .listen(
          (list) {
            currentGames = list
                .where((g) => g.gameStatus != GameStatus.gameOver)
                .toList();
            previousGames = list
                .where((g) => g.gameStatus == GameStatus.gameOver)
                .toList();
            loading = false;
            error = null;
            notifyListeners();
          },
          onError: (e, st) {
            developer.log(
              "GamesViewModel.listenGames Error: $e",
              stackTrace: st,
            );
            loading = false;
            error = e.toString();
            notifyListeners();
          },
        );
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
