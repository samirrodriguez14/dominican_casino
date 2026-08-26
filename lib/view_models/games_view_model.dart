import 'dart:async';
import 'dart:developer' as developer;

import 'package:dominican_casino/models/game_info.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/local_bot_roster.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';

class GamesViewModel extends ChangeNotifier {
  final AppRepo _appRepo;
  String? _listenPid;

  GamesViewModel({required AppRepo appRepo}) : _appRepo = appRepo {
    _appRepo.addListener(_onRepo);
  }

  void _onRepo() {
    final uid = _appRepo.player?.id;
    if (uid == _listenPid) return;
    final switchingUser = _listenPid != null;
    _listenPid = uid;
    if (!switchingUser) return;
    _stopActiveSubscription();
    currentGames = const [];
    previousGames = const [];
    _historyVisible = historyPageSize;
    _archivedHasMore = true;
    _archivedCursor = null;
    _archivedLoaded = false;
    loading = uid != null;
    error = null;
    notifyListeners();
  }

  List<GameInfo> get gamesInfo => _appRepo.gamesInfo;

  Future<String?> newGame(
    GameMode mode,
    bool local, {
    int playerCount = 2,
    int entryCost = WalletConfig.entryCost,
    int turnDurationSeconds = WalletConfig.defaultSpeedTurnSeconds,
    LocalBotProfile? botOverride,
    List<LocalBotProfile>? botOverrides,
  }) async {
    try {
      final gid = await _appRepo.createNewGame(
        mode,
        '',
        local,
        playerCount: playerCount,
        entryCost: entryCost,
        turnDurationSeconds: turnDurationSeconds,
        botOverride: botOverride,
        botOverrides: botOverrides,
      );
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
  bool _paused = false;
  bool _archivedLoaded = false;
  bool _archivedLoading = false;
  bool _archivedHasMore = true;
  DateTime? _archivedCursor;

  List<GamePillData> currentGames = const [];
  List<GamePillData> previousGames = const [];

  static const historyPageSize = 20;
  int _historyVisible = historyPageSize;

  /// Back-compat alias used by older call sites.
  List<GamePillData> get games => currentGames;

  String? get userId => _appRepo.player?.id;
  String? get myAvatarId => _appRepo.player?.avatarId;

  bool loading = true;
  bool get archivedLoading => _archivedLoading;
  String? error;

  List<GamePillData> get myCurrentGames {
    final uid = userId;
    if (uid == null) return const [];
    return currentGames.where((g) => g.containsPlayer(uid)).toList();
  }

  List<GamePillData> get myPreviousGames {
    final uid = userId;
    if (uid == null) return const [];
    return previousGames.where((g) => g.containsPlayer(uid)).toList();
  }

  List<GamePillData> get visiblePreviousGames {
    final all = myPreviousGames;
    if (all.length <= _historyVisible) return all;
    return all.take(_historyVisible).toList();
  }

  bool get hasMoreHistory =>
      myPreviousGames.length > _historyVisible || _archivedHasMore;

  Future<void> ensureArchivedLoaded() async {
    if (_archivedLoaded || _archivedLoading) return;
    final pid = userId;
    if (pid == null) return;

    _archivedLoading = true;
    notifyListeners();
    try {
      final page = await _appRepo.fs.fetchArchivedGames(
        pid,
        limit: historyPageSize,
      );
      previousGames = page..sort(_byUpdatedAtDesc);
      _archivedLoaded = true;
      _archivedHasMore = page.length >= historyPageSize;
      _archivedCursor = previousGames.isEmpty ? null : previousGames.last.updatedAt;
      _historyVisible = historyPageSize;
    } catch (e, st) {
      developer.log('GamesViewModel.ensureArchivedLoaded: $e', stackTrace: st);
    } finally {
      _archivedLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreHistory() async {
    if (_historyVisible < myPreviousGames.length) {
      _historyVisible += historyPageSize;
      notifyListeners();
      return;
    }
    if (_archivedLoading || !_archivedHasMore) return;

    final pid = userId;
    if (pid == null) return;

    _archivedLoading = true;
    notifyListeners();
    try {
      final page = await _appRepo.fs.fetchArchivedGames(
        pid,
        limit: historyPageSize,
        startAfterUpdatedAt: _archivedCursor,
      );
      if (page.isEmpty) {
        _archivedHasMore = false;
        return;
      }
      final byId = {for (final g in previousGames) g.id: g};
      for (final g in page) {
        byId[g.id] = g;
      }
      previousGames = byId.values.toList()..sort(_byUpdatedAtDesc);
      _archivedHasMore = page.length >= historyPageSize;
      _archivedCursor = previousGames.last.updatedAt;
      _historyVisible += historyPageSize;
    } catch (e, st) {
      developer.log('GamesViewModel.loadMoreHistory: $e', stackTrace: st);
    } finally {
      _archivedLoading = false;
      notifyListeners();
    }
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
    _listenPid = pid;
    _paused = false;
    _stopActiveSubscription();
    currentGames = const [];
    loading = true;
    error = null;
    notifyListeners();

    _sub = _appRepo.fs.listenActiveGames(pid).listen(
      (list) {
        currentGames = list..sort(_byUpdatedAtDesc);
        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (e, st) async {
        developer.log(
          'GamesViewModel.listenActiveGames Error: $e',
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
            developer.log(
              'GamesViewModel.listenActiveGames retry: $retryError',
            );
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

  /// Drop the lobby listener while a match is on screen — no cloud churn.
  void pauseListening() {
    if (_paused) return;
    _paused = true;
    _stopActiveSubscription();
  }

  /// Resume the active-games listener when back on the shell.
  void resumeListening() {
    if (!_paused) return;
    _paused = false;
    final pid = _listenPid ?? _appRepo.player?.id;
    if (pid != null) startListening(pid);
  }

  void _stopActiveSubscription() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> onDelete(BuildContext context, String gid) async {
    () async {
      final ok = await confirmDelete(context, gid);
      if (!ok) return;
      await deleteGame(gid);
    }();
  }

  Future<bool> confirmDelete(BuildContext context, String gameId) async {
    final res = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete game?'),
        content: Text('Game: $gameId'),
        actions: [
          CupertinoDialogAction(
            onPressed: SoundService.wrapTap(() => Navigator.of(ctx).pop(false)),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.of(ctx).pop(true)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  void dispose() {
    _appRepo.removeListener(_onRepo);
    _stopActiveSubscription();
    super.dispose();
  }
}
