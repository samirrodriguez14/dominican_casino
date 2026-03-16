import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/services/game_service.dart';
import '../models/game_state.dart';

class FirestoreService extends GameService {
  final CollectionReference _games = FirebaseFirestore.instance.collection(
    'games',
  );
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
      // developer.log('updateGame: ${snap.data().toString() != ""}');
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

  @override
  Future<String> newCreateGame(GameState gState) async {
    final doc = _games.doc(gState.id);
    await doc.set(gState.toJson());
    return gState.id;
  }

  @override
  Future<GameState> updateGame(GameState gState) async {
    await _games.doc(gState.id).set(gState.toJson());
    final snap = await _games.doc(gState.id).get();
    return GameState.fromMap(Map<String, dynamic>.from(snap.data() as Map));
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await _games.doc(gameId).delete();
  }
}
