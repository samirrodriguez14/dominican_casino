import 'dart:async';
import 'dart:developer' as developer;

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:flutter/cupertino.dart';

class GameRepo extends ChangeNotifier {
  GameState? gameState;
  final FirestoreService fs;
  StreamSubscription<GameState?>? _sub;

  GameRepo({required this.fs});

  //LISTENS TO GAME CHANGES. NOTIFIES VIEW MODEL
  void listenToGame(String gameId) {
    _sub?.cancel();

    _sub = fs
        .streamGame(gameId)
        .listen(
          (gs) {
            gameState = gs;
            developer.log("GameRepo.listenToGame GameState ${gs?.id}");
            notifyListeners();
          },
          onError: (e, st) {
            developer.log("GameRepo.listenToGame Error: $e");
          },
        );
  }

  //LISTENS TO GAME CHANGES. NOTIFIES VIEW MODEL

  //GENERAL ACTIONS

  Future<bool> loadGame(String gid) async {
    try {
      gameState = await fs.loadGame(gid);
      developer.log("GameRepo.loadGame Success: ${gameState!.id}");

      return true;
    } catch (e) {
      developer.log("GameRepo.loadGame Error: $e");
      return false;
    }
  }

  Future<bool> joinGame(String gid, String pid, Map<String, dynamic> playerInfo) async {
    try {
      if (gameState == null) await loadGame(gid);
      await fs.joinGame(gameState!.id, pid, playerInfo);
      return true;
    } catch (e) {
      developer.log("AppRepo.joinGame Error Joining Game: $e");
      return false;
    }
  }

  Future<void> startGame() async {
    try {
      await fs.startGame(gameState!.id);
    } catch (e) {
      developer.log("GameRepo.startGame Error: $e");
    }
  }

  Future<void> dealSameRound() async {
    try {
      await fs.dealSameRound(gameState!.id);
    } catch (e) {
      developer.log("GameRepo.dealSameRound Error: $e");
    }
  }

  Future<void> dealNextRound(String playerId) async {
    try {
      await fs.dealNextRound(gameState!.id, playerId);
    } catch (e) {
      developer.log("GameRepo.dealNextRound Error: $e");
    }
  }

  Future<void> setRoundReady(String playerId) async {
    try {
      await fs.setRoundReady(gameState!.id, playerId);
    } catch (e) {
      developer.log("Error setting round ready $e");
    }
  }

  Future<void> makePlay(String playerId, PlayingCardModel card) async {
    await fs.playCard(gameState!.id, playerId, card);
  }

  Future<void> takeCard(
    String playerId,
    PlayingCardModel card,
    PlayingCardModel takingCard,
  ) async {
    await fs.takeCard(gameState!.id, playerId, card, takingCard);
  }

  Future<void> addAndTakeCards(
    String playerId,
    PlayingCardModel card,
    List<PlayingCardModel> takingCards,
  ) async {
    await fs.addAndTakeCards(gameState!.id, playerId, card, takingCards);
  }

  Future<void> stackCards(
    String playerId,
    PlayingCardModel? playerCard,
    List<String?> cardStackIds,

    PlayingAreaStackModel stack,
  ) async {
    await fs.stackCard(
      gameState!.id,
      playerId,
      playerCard,
      cardStackIds,
      stack,
    );
  }

  Future<void> pairStacks(
    String playerId,
    List<String?> cardStackIds,
    PlayingCardModel? playerCard,
    PlayingAreaStackModel stack,
  ) async {
    await fs.pairStack(
      gameState!.id,
      playerId,
      cardStackIds,
      playerCard,
      stack,
    );
  }

  Future<void> stackAndPairStacks(
    String playerId,
    List<String?> cardStackIds,
    PlayingCardModel? playerCard,
    PlayingAreaStackModel stack,
  ) async {
    await fs.stackAndPairStacks(
      gameState!.id,
      playerId,
      cardStackIds,
      playerCard,
      stack,
    );
  }

  Future<void> takeStack(
    String playerId,
    PlayingAreaStackModel stack,
    PlayingCardModel takingCard,
  ) async {
    await fs.takeStack(gameState!.id, playerId, stack, takingCard);
  }

  // Future<void> leaveGame(String playerId) async {
  //   gameState = null;
  // }

  Future<void> endGame() async {
    await fs.deleteGame(gameState!.id);
  }

  //GENERAL ACTIONS
}
