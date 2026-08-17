import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_reaction.dart';
import 'package:dominican_casino/models/wallet.dart';
import 'package:dominican_casino/services/game_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';

class FirestoreService extends GameService {
  final CollectionReference _games = FirebaseFirestore.instance.collection(
    'games',
  );
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );

  /// Vs-Puli matches that could not be written to Firestore (guest with no
  /// anonymous auth, or rules/App Check denials). Kept in memory for this session.
  final Map<String, GameState> _localOnly = {};
  final Map<String, StreamController<GameState?>> _localGameControllers = {};
  final StreamController<void> _localListChanged =
      StreamController<void>.broadcast();

  void _putLocal(GameState gState) {
    _localOnly[gState.id] = gState;
    final c = _localGameControllers[gState.id];
    if (c != null && !c.isClosed) c.add(gState);
    if (!_localListChanged.isClosed) _localListChanged.add(null);
  }

  List<GamePillData> _localPillsFor(String pid) {
    return _localOnly.values
        .where(
          (g) => g.controllerId == pid || g.playersInfo.containsKey(pid),
        )
        .map((g) => GamePillData.fromDoc(g.id, g.toJson()))
        .toList();
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
  }) async {
    await _users.doc(uid).set({
      'name': ?name,
      'displayName': ?name,
      'avatarId': ?avatarId,
      'completedTutorial': completedTutorial,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> loadUserProfile(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveWallet({required String uid, required Wallet wallet}) async {
    await _users.doc(uid).set({
      ...wallet.toJson(),
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

    final cloudSub = _games
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
            debugPrint('listenGames cloud: $e');
            cloud = [];
            emit();
          },
        );
    final localSub = _localListChanged.stream.listen((_) => emit());
    emit();
    out.onCancel = () {
      cloudSub.cancel();
      localSub.cancel();
    };
    return out.stream;
  }

  @override
  Stream<GameState?> streamGame(String gameId) {
    if (_localOnly.containsKey(gameId)) {
      final c = _localGameControllers.putIfAbsent(
        gameId,
        () => StreamController<GameState?>.broadcast(),
      );
      return Stream<GameState?>.multi((listener) {
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
      });
    }
    return _games.doc(gameId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return GameState.fromMap(
        Map<String, dynamic>.from(snap.data() as Map<String, dynamic>),
      );
    });
  }

  @override
  Future<GameState> loadGame(String gid) async {
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
    final signedIn = FirebaseAuth.instance.currentUser != null;
    if (gState.isLocalBot && !signedIn) {
      debugPrint('newCreateGame: local bot without auth, keeping on device');
      _putLocal(gState);
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
      return gState.id;
    }
  }

  @override
  Future<GameState> updateGame(GameState gState) async {
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
    _localOnly.remove(gameId);
    final c = _localGameControllers.remove(gameId);
    if (c != null && !c.isClosed) await c.close();
    if (!_localListChanged.isClosed) _localListChanged.add(null);
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
