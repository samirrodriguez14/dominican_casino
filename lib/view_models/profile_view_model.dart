import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/league.dart';
import 'package:dominican_casino/models/opponent_match_stats.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter/cupertino.dart';

/// Friend row for league Friends tab (H2H + public career/league).
class LeagueFriendRow {
  const LeagueFriendRow({
    required this.opponent,
    required this.profile,
  });

  final OpponentMatchStats opponent;
  final PublicProfile profile;
}

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

  JourneyWorld? get currentLeague => _appRepo.currentLeague;

  JourneyWorld? get nextLeagueTarget => _appRepo.nextLeagueTarget;

  int? exitRankFor(JourneyWorld world) => _appRepo.exitRankFor(world);

  List<PublicProfile> leagueTop = const [];
  int? leagueOwnRank;
  List<PublicProfile> leagueTopFriends = const [];
  List<LeagueFriendRow> leagueFriends = const [];
  bool leagueLoading = false;
  bool _leagueLoaded = false;
  String? _leagueUid;
  JourneyWorld? _leagueLoadedFor;

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

  Future<void> ensureLeagueLoaded({bool force = false}) async {
    final uid = player?.id;
    if (uid == null || uid.isEmpty) return;
    final league = currentLeague;
    if (!force &&
        _leagueLoaded &&
        _leagueUid == uid &&
        _leagueLoadedFor == league &&
        // Retry when cloud returned nobody — self should always appear.
        !(league != null && leagueTop.isEmpty)) {
      return;
    }
    _leagueUid = uid;
    _leagueLoadedFor = league;
    leagueLoading = true;
    notifyListeners();
    try {
      await _appRepo.syncPublicProfile();
      if (league == null) {
        leagueTop = const [];
        leagueOwnRank = null;
        leagueTopFriends = const [];
        leagueFriends = const [];
      } else {
        final opponents = await _appRepo.fs.fetchAllOpponentStats(uid);
        final profiles = await _appRepo.fs.fetchPublicProfiles(
          opponents.map((o) => o.opponentUid),
        );
        final friendRows = <LeagueFriendRow>[
          for (final opp in opponents)
            LeagueFriendRow(
              opponent: opp,
              profile: profiles[opp.opponentUid] ??
                  PublicProfile(
                    uid: opp.opponentUid,
                    name: opp.name,
                    avatarId: opp.avatarId,
                    wins: 0,
                    league: null,
                  ),
            ),
        ];
        friendRows.sort(
          (a, b) => compareFriendsByLeagueThenWins(a.profile, b.profile),
        );
        final topFriends = [...friendRows.map((r) => r.profile)]
          ..sort((a, b) => b.wins.compareTo(a.wins));

        final me = PublicProfile(
          uid: uid,
          name: player?.name,
          avatarId: player?.avatarId,
          wins: player?.matchStats.wins ?? 0,
          league: league,
        );
        // Await sequentially so index/build errors stay contained.
        final top = await _appRepo.fs.fetchLeagueTop(league, limit: 5);
        var rank = await _appRepo.fs.fetchLeagueRank(
          league: league,
          wins: player?.matchStats.wins ?? 0,
        );
        var mergedTop = top;
        // Always include yourself — alone in the league you are #1.
        if (!mergedTop.any((p) => p.uid == uid)) {
          mergedTop = [...mergedTop, me]
            ..sort((a, b) => b.wins.compareTo(a.wins));
          mergedTop = mergedTop.take(5).toList();
          if (mergedTop.length == 1) rank = 1;
        }
        leagueTop = mergedTop;
        leagueOwnRank = rank;
        leagueTopFriends = topFriends.take(5).toList();
        leagueFriends = friendRows;
      }
      _leagueLoaded = true;
    } catch (_) {
      // Still show the local player if they have a league.
      final league = currentLeague;
      final uid = player?.id;
      if (league != null && uid != null && uid.isNotEmpty) {
        leagueTop = [
          PublicProfile(
            uid: uid,
            name: player?.name,
            avatarId: player?.avatarId,
            wins: player?.matchStats.wins ?? 0,
            league: league,
          ),
        ];
        leagueOwnRank = 1;
      } else {
        leagueTop = const [];
        leagueOwnRank = null;
      }
      leagueTopFriends = const [];
      leagueFriends = const [];
    } finally {
      leagueLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePlayerName(String name) async {
    await _appRepo.updatePlayer(name);
    _refreshSelfOnLeagueBoard();
    notifyListeners();
  }

  Future<void> updatePlayerAvatar(String avatarId) async {
    await _appRepo.updatePlayerAvatar(avatarId);
    _refreshSelfOnLeagueBoard();
    notifyListeners();
  }

  void _refreshSelfOnLeagueBoard() {
    final uid = player?.id;
    if (uid == null || uid.isEmpty) return;
    leagueTop = [
      for (final p in leagueTop)
        if (p.uid == uid)
          PublicProfile(
            uid: uid,
            name: player?.name,
            avatarId: player?.avatarId,
            wins: player?.matchStats.wins ?? p.wins,
            league: p.league ?? currentLeague,
          )
        else
          p,
    ];
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
