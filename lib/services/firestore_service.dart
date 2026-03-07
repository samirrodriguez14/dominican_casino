import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/lobby_game.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/services/game_handler2.dart';
import '../models/playing_card_model.dart';
import '../models/game_state.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference _games = FirebaseFirestore.instance.collection(
    'games',
  );

  final GameHandler2 gameHandler;

  FirestoreService()
    : gameHandler = GameHandler2(db: FirebaseFirestore.instance);

  ///START STREAMS
  ///
  Stream<List<LobbyGame>> listenGames() {
    return _games.snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return LobbyGame.fromDoc(d.id, data);
      }).toList();
    });
  }

  Stream<GameState?> streamGame(String gameId) {
    return _games.doc(gameId).snapshots().map((snap) {
      // developer.log('updateGame: ${snap.data().toString() != ""}');
      if (!snap.exists) return null;
      return GameState.fromMap(
        Map<String, dynamic>.from(snap.data() as Map<String, dynamic>),
      );
    });
  }

  ///
  ///END STREAMS

  ///GAME HANDLE START
  ///
  ///
  Future<GameState> loadGame(String gid) async {
    final snap = await _games.doc(gid).get();
    return GameState.fromMap(Map<String, dynamic>.from(snap.data() as Map));
  }

  Future<String> createGame() => gameHandler.createGame();

  Future<void> deleteGame(String gameId) async {
    await _games.doc(gameId).delete();
  }

  Future<String?> joinGame(String gameId, String pid) async {
    String? g;
    try {
      g = await gameHandler.joinGame(gameId: gameId, pid: pid);
    } catch (e) {
      developer.log("Service.fs.joinGame Error $e");
    }
    return g;
  }

  Future<void> startGame(String gameId) async =>
      await gameHandler.startGame(gameId);

  Future<void> leaveGame(String gameId, String pid) async =>
      await gameHandler.leaveGame(gameId, pid);

  ///
  ///GAME HANDLE END

  ///ROUND CONTROLLERS
  ///

  Future<void> dealSameRound(String gameId) async =>
      await gameHandler.dealSameRound(gameId);

  Future<void> dealNextRound(String gameId, String playerId) async {
    final doc = _games.doc(gameId);
    developer.log("SERVICE docPath=${_games.doc(gameId).path}");
    await _db
        .runTransaction((tx) async {
          await gameHandler.dealNextRound(tx, doc, playerId);
        })
        .catchError((e, st) {
          developer.log("setRoundReady tx FAILED: $e\n$st");
          throw e;
        });
  }

  Future<void> setRoundReady(String gameId, String playerId) async {
    final doc = _games.doc(gameId);
    developer.log("SERVICE docPath=${_games.doc(gameId).path}");
    await _db
        .runTransaction((tx) async {
          await gameHandler.setRoundReady(tx, doc, playerId);
          developer.log("setRoundReady SUCCESS");
        })
        .catchError((e, st) {
          developer.log("setRoundReady tx FAILED: $e\n$st");
          throw e;
        });
  }

  ///
  ///ROUND CONTROLLERS

  ///PlayHandle START
  ///
  Future<void> playCard(
    String gameId,
    String playerId,
    PlayingCardModel card,
  ) async {
    final doc = _games.doc(gameId);
    developer.log("SERVICE docPath=${_games.doc(gameId).path}");
    await _db
        .runTransaction((tx) async {
          await gameHandler.playCard(tx, doc, card, playerId);
        })
        .catchError((e, st) {
          developer.log("runTransaction failed: $e\n$st");
          throw e;
        });
  }

  Future<void> takeCard(
    String gameId,
    String playerId,
    PlayingCardModel card,
    PlayingCardModel takingCard,
  ) async {
    final doc = _games.doc(gameId);
    developer.log("SERVICE docPath=${_games.doc(gameId).path}");

    await _db
        .runTransaction((tx) async {
          await gameHandler.takeCard(tx, doc, card, takingCard, playerId);
        })
        .catchError((e, st) {
          developer.log("runTransaction failed: $e\n$st");
          throw e;
        });
  }

  Future<void> addAndTakeCards(
    String gameId,
    String playerId,
    PlayingCardModel card,
    List<PlayingCardModel> takingCards,
  ) async {
    final doc = _games.doc(gameId);
    developer.log("SERVICE docPath=${_games.doc(gameId).path}");

    await _db
        .runTransaction((tx) async {
          await gameHandler.addAndTakeCards(
            tx,
            doc,
            card,
            takingCards,
            playerId,
          );
        })
        .catchError((e, st) {
          developer.log("runTransaction failed: $e\n$st");
          throw e;
        });
  }

  Future<void> stackCard(
    String gameId,
    String playerId,
    PlayingCardModel? playerCard,
    List<String?> cardStackIds,

    PlayingAreaStackModel cardStack,
  ) async {
    final doc = _games.doc(gameId);
    await _db
        .runTransaction((tx) async {
          await gameHandler.stackCards(
            tx,
            doc,
            playerId,
            playerCard,
            cardStackIds,
            cardStack,
          );
        })
        .catchError((e, st) {
          developer.log("runTransaction failed: $e\n$st");
          throw e;
        });
  }

  Future<void> pairStack(
    String gameId,
    String playerId,
    List<String?> cardStackIds,
    PlayingCardModel? playerCard,
    PlayingAreaStackModel cardStack,
  ) async {
    final doc = _games.doc(gameId);
    await _db
        .runTransaction((tx) async {
          await gameHandler.pairStacks(
            tx,
            doc,
            playerId,
            cardStackIds,
            playerCard,
            cardStack,
          );
        })
        .catchError((e, st) {
          developer.log("runTransaction failed: $e\n$st");
          throw e;
        });
  }

  Future<void> stackAndPairStacks(
    String gameId,
    String playerId,
    List<String?> cardStackIds,
    PlayingCardModel? playerCard,
    PlayingAreaStackModel cardStack,
  ) async {
    final doc = _games.doc(gameId);
    await _db
        .runTransaction((tx) async {
          await gameHandler.pairStacks(
            tx,
            doc,
            playerId,
            cardStackIds,
            playerCard,
            cardStack,
          );
        })
        .catchError((e, st) {
          developer.log("runTransaction failed: $e\n$st");
          throw e;
        });
  }

  Future<void> takeStack(
    String gameId,
    String playerId,
    PlayingAreaStackModel stack,
    PlayingCardModel card,
  ) async {
    final doc = _games.doc(gameId);
    await _db
        .runTransaction((tx) async {
          await gameHandler.takeStack(tx, doc, stack, card, playerId);
        })
        .catchError((e, st) {
          developer.log("runTransaction failed: $e\n$st");
          throw e;
        });
  }

  ///
  ///PLAY HANDLE END
}
