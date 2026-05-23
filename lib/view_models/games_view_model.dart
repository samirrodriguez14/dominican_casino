import 'dart:async';
import 'dart:developer' as developer;
import 'package:dominican_casino/models/game_info.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:flutter/cupertino.dart';

class GamesViewModel extends ChangeNotifier {
  final AppRepo _appRepo;
  final GameRepo _gameRepo;

  GamesViewModel({required AppRepo appRepo, required GameRepo gameRepo})
    : _appRepo = appRepo,
      _gameRepo = gameRepo;

  List<GameInfo> get gamesInfo => _appRepo.gamesInfo;
  
  Future<String?> newGame(GameMode mode, bool local) async {
    try {
      String? pid = _appRepo.player?.id;
      Player? playersInfo = _appRepo.player;
      if (pid != null && playersInfo != null) {
        String gid = await _appRepo.createNewGame(mode, pid, _gameRepo, local);
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
                .where((g) => g.gameStatus != GameStatus.gameOver)
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
