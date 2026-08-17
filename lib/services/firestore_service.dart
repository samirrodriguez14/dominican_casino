import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_reaction.dart';
import 'package:dominican_casino/models/wallet.dart';
import 'package:dominican_casino/services/game_service.dart';
import '../models/game_state.dart';

class FirestoreService extends GameService {
  final CollectionReference _games = FirebaseFirestore.instance.collection(
    'games',
  );
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );

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
    return _games.where('playersInfo.$pid.id', isEqualTo: pid).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return GamePillData.fromDoc(d.id, data);
      }).toList();
    });
  }

  @override
  Stream<GameState?> streamGame(String gameId) {
    return _games.doc(gameId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return GameState.fromMap(
        Map<String, dynamic>.from(snap.data() as Map<String, dynamic>),
      );
    });
  }

  @override
  Future<GameState> loadGame(String gid) async {
    final snap = await _games.doc(gid).get();
    return GameState.fromMap(Map<String, dynamic>.from(snap.data() as Map));
  }

  Map<String, dynamic> _gamePayload(GameState gState) {
    final data = gState.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    return data;
  }

  @override
  Future<String> newCreateGame(GameState gState) async {
    final doc = _games.doc(gState.id);
    await doc.set(_gamePayload(gState));
    return gState.id;
  }

  @override
  Future<GameState> updateGame(GameState gState) async {
    await _games.doc(gState.id).set(_gamePayload(gState));
    final snap = await _games.doc(gState.id).get();
    return GameState.fromMap(Map<String, dynamic>.from(snap.data() as Map));
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await _games.doc(gameId).delete();
  }

  /// Side-channel so reactions never ride on [updateGame]'s full document set.
  DocumentReference _reactionDoc(String gid) {
    return _games.doc(gid).collection('signals').doc('reaction');
  }

  Future<void> sendReaction({
    required String gid,
    required GameReaction reaction,
  }) {
    return _reactionDoc(gid).set({
      ...reaction.toMap(),
      'at': FieldValue.serverTimestamp(),
    });
  }

  Stream<GameReaction?> streamReaction(String gid) {
    return _reactionDoc(gid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data is! Map) return null;
      return GameReaction.fromMap(Map<String, dynamic>.from(data));
    });
  }
}
