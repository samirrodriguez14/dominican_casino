import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_reaction.dart';
import 'package:dominican_casino/models/wallet.dart';
import 'package:dominican_casino/services/game_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

class FirestoreService extends GameService {
  final CollectionReference _games = FirebaseFirestore.instance.collection(
    'games',
  );
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );

  /// Vs-Puli matches that could not be written to Firestore (guest with no
  /// anonymous auth, or rules/App Check denials). Persisted on this device.
  final Map<String, GameState> _localOnly = {};
  final Map<String, DateTime> _localUpdatedAt = {};
  final Map<String, StreamController<GameState?>> _localGameControllers = {};
  final StreamController<void> _localListChanged =
      StreamController<void>.broadcast();
  static const _localGamesKey = 'local_games_v1';
  Future<void>? _localLoadFuture;

  Future<void> _ensureLocalLoaded() {
    return _localLoadFuture ??= _loadLocalGames();
  }

  Future<void> _loadLocalGames() async {
    _localOnly.clear();
    _localUpdatedAt.clear();
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_localGamesKey);
      if (raw == null || raw.isEmpty) {
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }
      decoded.forEach((key, value) {
        if (value is! Map) return;
        try {
          final data = Map<String, dynamic>.from(value);
          final state = GameState.fromMap(data);
          state.ensureBotMetadata();
          _localOnly[key.toString()] = state;
          _localUpdatedAt[key.toString()] =
              GamePillData.parseUpdatedAt(data['updatedAt']) ?? DateTime.now();
        } catch (e) {
          debugPrint('load local game $key: $e');
        }
      });
    } catch (e) {
      debugPrint('load local games: $e');
    }
  }

  /// Drop on-device vs-Puli cache. Used on logout / delete local data so a
  /// new guest cannot inherit the previous session's history.
  Future<void> clearDeviceGames() async {
    _localOnly.clear();
    _localUpdatedAt.clear();
    for (final c in _localGameControllers.values) {
      if (!c.isClosed) {
        c.add(null);
        await c.close();
      }
    }
    _localGameControllers.clear();
    _localLoadFuture = null;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_localGamesKey);
    } catch (e) {
      debugPrint('clear local games: $e');
    }
    if (!_localListChanged.isClosed) _localListChanged.add(null);
  }

  /// Same person, new Firebase uid — rewrite local match seats in place.
  Future<void> rebindLocalPlayer({
    required String fromPid,
    required String toPid,
  }) async {
    if (fromPid.isEmpty || toPid.isEmpty || fromPid == toPid) return;
    await _ensureLocalLoaded();
    var changed = false;
    for (final game in _localOnly.values) {
      if (_rebindGamePlayer(game, fromPid, toPid)) changed = true;
    }
    if (!changed) return;
    await _persistLocalGames();
    if (!_localListChanged.isClosed) _localListChanged.add(null);
  }

  bool _rebindGamePlayer(GameState game, String from, String to) {
    var changed = false;
    if (game.controllerId == from) {
      game.controllerId = to;
      changed = true;
    }
    if (game.currentTurnPlayerId == from) {
      game.currentTurnPlayerId = to;
      changed = true;
    }
    if (game.winnerId == from) {
      game.winnerId = to;
      changed = true;
    }
    if (game.extraPointsHolderId == from) {
      game.extraPointsHolderId = to;
      changed = true;
    }
    if (game.entryPaidBy.contains(from)) {
      game.entryPaidBy = [
        for (final id in game.entryPaidBy) id == from ? to : id,
      ];
      changed = true;
    }
    changed = _rebindMapKey(game.playersInfo, from, to) || changed;
    for (final raw in game.playersInfo.values) {
      if (raw is Map && raw['id'] == from) {
        raw['id'] = to;
        changed = true;
      }
    }
    changed = _rebindMapKey(game.hands, from, to) || changed;
    changed = _rebindMapKey(game.playersDeck, from, to) || changed;
    changed = _rebindMapKey(game.lastTakes, from, to) || changed;
    changed = _rebindMapKey(game.scores, from, to) || changed;
    changed = _rebindMapKey(game.pendingCoins, from, to) || changed;
    changed = _rebindMapKey(game.roundTakeCoins, from, to) || changed;
    changed = _rebindMapKey(game.roundSpecialCoins, from, to) || changed;
    changed = _rebindMapKey(game.roundViraoCoins, from, to) || changed;
    changed = _rebindMapKey(game.round.roundScores, from, to) || changed;
    return changed;
  }

  bool _rebindMapKey<V>(Map<String, V> map, String from, String to) {
    if (!map.containsKey(from)) return false;
    final value = map.remove(from);
    if (value != null) map[to] = value;
    return true;
  }

  Future<void> _persistLocalGames() async {
    try {
      _pruneLocalGames();
      final sp = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};
      for (final e in _localOnly.entries) {
        final json = Map<String, dynamic>.from(e.value.toJson());
        json['updatedAt'] =
            (_localUpdatedAt[e.key] ?? DateTime.now()).toIso8601String();
        map[e.key] = json;
      }
      await sp.setString(_localGamesKey, jsonEncode(map));
    } catch (e) {
      debugPrint('persist local games: $e');
    }
  }

  void _pruneLocalGames() {
    final finished = _localOnly.entries
        .where((e) => e.value.gameStatus == GameStatus.gameOver)
        .toList()
      ..sort((a, b) {
        final at = _localUpdatedAt[a.key] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = _localUpdatedAt[b.key] ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
    if (finished.length <= 15) return;
    for (final e in finished.skip(15)) {
      _localOnly.remove(e.key);
      _localUpdatedAt.remove(e.key);
    }
  }

  void _putLocal(GameState gState) {
    _localOnly[gState.id] = gState;
    _localUpdatedAt[gState.id] = DateTime.now();
    final c = _localGameControllers[gState.id];
    if (c != null && !c.isClosed) c.add(gState);
    if (!_localListChanged.isClosed) _localListChanged.add(null);
    unawaited(_persistLocalGames());
  }

  List<GamePillData> _localPillsFor(String pid) {
    return _localOnly.values
        .where((g) => _localGameBelongsTo(g, pid))
        .map((g) {
          final json = Map<String, dynamic>.from(g.toJson());
          json['updatedAt'] = _localUpdatedAt[g.id]?.toIso8601String();
          return GamePillData.fromDoc(g.id, json);
        })
        .toList();
  }

  bool _localGameBelongsTo(GameState game, String pid) {
    if (game.controllerId == pid || game.playersInfo.containsKey(pid)) {
      return true;
    }
    for (final raw in game.playersInfo.values) {
      if (raw is Map && raw['id'] == pid) return true;
    }
    return false;
  }

  /// Which match this device is looking at. Cleared when the user leaves
  /// or backgrounds the app so turn pushes can skip an on-screen player.
  Future<void> saveActiveGameId(String uid, String? gameId) async {
    await _users.doc(uid).set({
      'activeGameId': gameId ?? FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Store FCM token on the user profile — never on game documents.
  Future<void> saveUserToken(
    String uid,
    String token,
    String? displayName,
  ) async {
    await _users.doc(uid).set({
      'fcmToken': token,
      'displayName': ?displayName,
      'name': ?displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveUserProfile({
    required String uid,
    String? name,
    String? avatarId,
    required bool completedTutorial,
    List<String>? ownedPacks,
    String? appTheme,
    String? cardBack,
    String? cardBackMark,
    String? cardBackTint,
    String? locale,
  }) async {
    await _users.doc(uid).set({
      'name': ?name,
      'displayName': ?name,
      'avatarId': ?avatarId,
      'completedTutorial': completedTutorial,
      'ownedPacks': ?ownedPacks,
      'appTheme': ?appTheme,
      'cardBack': ?cardBack,
      'cardBackMark': ?cardBackMark,
      'cardBackTint': ?cardBackTint,
      'locale': ?locale,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUserProfile(String uid) async {
    await _users.doc(uid).delete();
  }

  Future<Map<String, dynamic>?> loadUserProfile(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveWallet({required String uid, required Wallet wallet}) async {
    final fullAt = wallet.fullAt;
    await _users.doc(uid).set({
      ...wallet.toJson(),
      'energyFullAt': fullAt == null
          ? FieldValue.delete()
          : Timestamp.fromDate(fullAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveLastDailyClaimAt({
    required String uid,
    required DateTime at,
  }) async {
    await _users.doc(uid).set({
      'lastDailyClaimAt': at.millisecondsSinceEpoch,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveDailyChallenges({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _users.doc(uid).set({
      'dailyChallenges': data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<GamePillData>> listenGames(String pid) {
    final out = StreamController<List<GamePillData>>();
    var cloud = <GamePillData>[];

    List<GamePillData> merged() {
      final byId = {for (final g in cloud) g.id: g};
      for (final g in _localPillsFor(pid)) {
        byId[g.id] = g;
      }
      return byId.values.toList();
    }

    void emit() {
      if (!out.isClosed) out.add(merged());
    }

    late final StreamSubscription<QuerySnapshot> cloudSub;
    late final StreamSubscription<void> localSub;

    cloudSub = _games
        .where('playersInfo.$pid.id', isEqualTo: pid)
        .snapshots()
        .listen(
          (snapshot) {
            cloud = snapshot.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return GamePillData.fromDoc(d.id, data);
            }).toList();
            emit();
          },
          onError: (e, st) {
            // Common when signed out / rules block list — local pills still emit.
            final msg = e.toString();
            if (!msg.contains('permission-denied')) {
              debugPrint('listenGames cloud: $e');
            }
            cloud = [];
            emit();
          },
        );
    localSub = _localListChanged.stream.listen((_) => emit());
    out.onCancel = () {
      cloudSub.cancel();
      localSub.cancel();
    };
    _ensureLocalLoaded().then((_) {
      if (!out.isClosed) emit();
    });
    return out.stream;
  }

  @override
  Stream<GameState?> streamGame(String gameId) {
    return Stream<GameState?>.multi((listener) async {
      await _ensureLocalLoaded();
      if (_localOnly.containsKey(gameId)) {
        final c = _localGameControllers.putIfAbsent(
          gameId,
          () => StreamController<GameState?>.broadcast(),
        );
        listener.add(_localOnly[gameId]);
        final sub = c.stream.listen(
          listener.add,
          onError: listener.addError,
          onDone: listener.close,
        );
        listener
          ..onPause = sub.pause
          ..onResume = sub.resume
          ..onCancel = () async {
            await sub.cancel();
          };
        return;
      }
      final sub = _games
          .doc(gameId)
          .snapshots()
          .listen(
            (snap) {
              if (!snap.exists) {
                listener.add(null);
                return;
              }
              listener.add(
                GameState.fromMap(
                  Map<String, dynamic>.from(snap.data() as Map<String, dynamic>),
                ),
              );
            },
            onError: listener.addError,
            onDone: listener.close,
          );
      listener.onCancel = () async {
        await sub.cancel();
      };
    });
  }

  @override
  Future<GameState> loadGame(String gid) async {
    await _ensureLocalLoaded();
    final local = _localOnly[gid];
    if (local != null) return local;
    final snap = await _games.doc(gid).get();
    return GameState.fromMap(Map<String, dynamic>.from(snap.data() as Map));
  }

  Map<String, dynamic> _gamePayload(GameState gState) {
    final data = Map<String, dynamic>.from(gState.toJson());
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['playerIds'] = gState.playersInfo.keys.toList();
    return _omitNulls(data);
  }

  /// Firestore `set()` rejects null values. Drop them recursively.
  Map<String, dynamic> _omitNulls(Map<dynamic, dynamic> input) {
    final out = <String, dynamic>{};
    input.forEach((key, value) {
      if (key == null) return;
      final cleaned = _omitNullValue(value);
      if (cleaned != null) {
        out[key.toString()] = cleaned;
      }
    });
    return out;
  }

  dynamic _omitNullValue(dynamic value) {
    if (value == null) return null;
    if (value is FieldValue) return value;
    if (value is Map) return _omitNulls(value);
    if (value is Iterable && value is! String) {
      return value.map(_omitNullValue).where((e) => e != null).toList();
    }
    return value;
  }

  @override
  Future<String> newCreateGame(GameState gState) async {
    await _ensureLocalLoaded();
    final signedIn = FirebaseAuth.instance.currentUser != null;
    if (gState.isLocalBot && !signedIn) {
      debugPrint('newCreateGame: local bot without auth, keeping on device');
      _putLocal(gState);
      await _persistLocalGames();
      return gState.id;
    }
    final doc = _games.doc(gState.id);
    final payload = _gamePayload(gState);
    try {
      await doc.set(payload);
      return gState.id;
    } catch (e) {
      debugPrint('newCreateGame cloud: $e');
      if (!gState.isLocalBot) rethrow;
      _putLocal(gState);
      await _persistLocalGames();
      return gState.id;
    }
  }

  @override
  Future<GameState> updateGame(GameState gState) async {
    await _ensureLocalLoaded();
    if (_localOnly.containsKey(gState.id)) {
      _putLocal(gState);
      return gState;
    }
    try {
      await _games.doc(gState.id).set(_gamePayload(gState));
      final snap = await _games.doc(gState.id).get();
      return GameState.fromMap(Map<String, dynamic>.from(snap.data() as Map));
    } catch (e) {
      debugPrint('updateGame cloud: $e');
      if (!gState.isLocalBot) rethrow;
      _putLocal(gState);
      return gState;
    }
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await _ensureLocalLoaded();
    _localOnly.remove(gameId);
    _localUpdatedAt.remove(gameId);
    final c = _localGameControllers.remove(gameId);
    if (c != null && !c.isClosed) await c.close();
    if (!_localListChanged.isClosed) _localListChanged.add(null);
    await _persistLocalGames();
    try {
      await _games.doc(gameId).delete();
    } catch (e) {
      debugPrint('deleteGame cloud: $e');
    }
  }

  /// Side-channel so reactions never ride on [updateGame]'s full document set.
  DocumentReference _reactionDoc(String gid) {
    return _games.doc(gid).collection('signals').doc('reaction');
  }

  Future<void> sendReaction({
    required String gid,
    required GameReaction reaction,
  }) {
    if (_localOnly.containsKey(gid)) return Future.value();
    return _reactionDoc(gid).set({
      ...reaction.toMap(),
      'at': FieldValue.serverTimestamp(),
    });
  }

  Stream<GameReaction?> streamReaction(String gid) {
    if (_localOnly.containsKey(gid)) {
      return Stream<GameReaction?>.value(null);
    }
    return _reactionDoc(gid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data is! Map) return null;
      return GameReaction.fromMap(Map<String, dynamic>.from(data));
    });
  }
}
