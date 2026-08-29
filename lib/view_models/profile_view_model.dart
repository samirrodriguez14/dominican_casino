import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/opponent_match_stats.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:flutter/cupertino.dart';

class ProfileViewModel extends ChangeNotifier {
  final AppRepo _appRepo;

  Player? get player => _appRepo.player;

  ProfileViewModel({required AppRepo appRepo}) : _appRepo = appRepo;

  List<OpponentMatchStats> opponentStats = const [];
  bool opponentStatsLoading = false;
  bool opponentStatsHasMore = true;
  DocumentSnapshot? _opponentCursor;
  bool _opponentLoaded = false;
  String? _opponentUid;

  Future<void> ensureOpponentStatsLoaded() async {
    final uid = player?.id;
    if (uid == null || uid.isEmpty) return;
    if (_opponentLoaded && _opponentUid == uid) return;
    _opponentUid = uid;
    _opponentLoaded = false;
    opponentStats = const [];
    _opponentCursor = null;
    opponentStatsHasMore = true;
    await loadMoreOpponentStats();
    _opponentLoaded = true;
  }

  Future<void> loadMoreOpponentStats() async {
    final uid = player?.id;
    if (uid == null || uid.isEmpty) return;
    if (opponentStatsLoading || !opponentStatsHasMore) return;
    opponentStatsLoading = true;
    notifyListeners();
    try {
      final page = await _appRepo.fs.fetchOpponentStats(
        uid,
        limit: 8,
        startAfter: _opponentCursor,
      );
      opponentStats = [...opponentStats, ...page.items];
      _opponentCursor = page.lastDoc;
      opponentStatsHasMore = page.items.length >= 8;
    } catch (_) {
      opponentStatsHasMore = false;
    } finally {
      opponentStatsLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePlayerName(String name) async {
    await _appRepo.updatePlayer(name);
    notifyListeners();
  }

  Future<void> updatePlayerAvatar(String avatarId) async {
    await _appRepo.updatePlayerAvatar(avatarId);
    notifyListeners();
  }

  bool get isLinkedAccount => _appRepo.isLinkedAccount;

  /// @deprecated Use [isLinkedAccount].
  bool get isGoogleLinked => _appRepo.isLinkedAccount;

  Future<GoogleAuthResult> linkGoogle() async {
    final result = await _appRepo.linkGoogleAccount();
    notifyListeners();
    return result;
  }

  Future<GoogleAuthResult> linkApple() async {
    final result = await _appRepo.linkAppleAccount();
    notifyListeners();
    return result;
  }
}
