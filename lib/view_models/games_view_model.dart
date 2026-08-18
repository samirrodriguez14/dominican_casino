import 'dart:async';
import 'dart:developer' as developer;

import 'package:dominican_casino/models/game_info.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';

class GamesViewModel extends ChangeNotifier {
  final AppRepo _appRepo;

  GamesViewModel({required AppRepo appRepo}) : _appRepo = appRepo;

  List<GameInfo> get gamesInfo => _appRepo.gamesInfo;

  Future<String?> newGame(GameMode mode, bool local) async {
    try {
      final gid = await _appRepo.createNewGame(mode, '', local);
      debugPrint('newGame $gid local=$local');
      return gid;
    } on InsufficientFundsException {
      rethrow;
    } catch (e) {
      debugPrint('Error Creating Game $e');
      rethrow;
    }
  }

  Future<void> deleteGame(String gameId) async {
    await _appRepo.deleteGame(gameId);
  }

  Future<GameState> loadGameState(String gameId) {
    return _appRepo.fs.loadGame(gameId);
  }

  StreamSubscription<List<GamePillData>>? _sub;

  List<GamePillData> currentGames = const [];
  List<GamePillData> previousGames = const [];

  /// Back-compat alias used by older call sites.
  List<GamePillData> get games => currentGames;

  String? get userId => _appRepo.player?.id;
  String? get myAvatarId => _appRepo.player?.avatarId;

  bool loading = true;
  String? error;

  List<GamePillData> get myCurrentGames {
    final uid = userId;
    if (uid == null) return currentGames;
    final mine = currentGames.where((g) => g.containsPlayer(uid)).toList();
    return mine.isNotEmpty ? mine : currentGames;
  }

  List<GamePillData> get myPreviousGames {
    final uid = userId;
    if (uid == null) return previousGames;
    final mine = previousGames.where((g) => g.containsPlayer(uid)).toList();
    return mine.isNotEmpty ? mine : previousGames;
  }

  /// Current games where it is this player's turn (for the peek-card badge).
  int get yourTurnCount {
    final uid = userId;
    if (uid == null) return 0;
    return myCurrentGames
        .where((g) => g.isMyTurn(uid) && g.gameStatus != GameStatus.gameOver)
        .length;
  }

  bool get hasCurrentGames => myCurrentGames.isNotEmpty;

  static int _byUpdatedAtDesc(GamePillData a, GamePillData b) {
    final at = a.updatedAt;
    final bt = b.updatedAt;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  }

  void startListening(String pid, {bool retried = false}) {
    _sub?.cancel();
    loading = true;
    error = null;
    notifyListeners();

    _sub = _appRepo.fs
        .listenGames(pid)
        .listen(
          (list) {
            currentGames =
                list.where((g) => g.gameStatus != GameStatus.gameOver).toList()
                  ..sort(_byUpdatedAtDesc);
            previousGames =
                list.where((g) => g.gameStatus == GameStatus.gameOver).toList()
                  ..sort(_byUpdatedAtDesc);
            loading = false;
            error = null;
            notifyListeners();
          },
          onError: (e, st) async {
            developer.log(
              "GamesViewModel.listenGames Error: $e",
              stackTrace: st,
            );
            if (!retried &&
                e is FirebaseException &&
                e.code == 'permission-denied') {
              try {
                final uid = await _appRepo.ensurePlayableUid();
                startListening(uid, retried: true);
                return;
              } catch (retryError) {
                developer.log('GamesViewModel.listenGames retry: $retryError');
              }
            }
            loading = false;
            final code = e is FirebaseException ? e.code : '';
            error = code == 'permission-denied'
                ? 'permission-denied'
                : e.toString();
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
            onPressed: SoundService.wrapTap(() => Navigator.of(ctx).pop(false)),
            child: const Text("Cancel"),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.of(ctx).pop(true)),
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
