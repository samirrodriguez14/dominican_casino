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
            developer.log("GameRepo.Setting GameState ${gs?.id}");
            notifyListeners();
          },
          onError: (e, st) {
            developer.log("Error updating game: $e");
          },
        );
  }

  //LISTENS TO GAME CHANGES. NOTIFIES VIEW MODEL

  //GENERAL ACTIONS
  Future<void> startGame() async {
    try {
      await fs.startGame(gameState!.id);
    } catch (e) {
      developer.log("Error starting Game $e");
    }
  }

  Future<void> dealSameRound() async {
    try {
      await fs.dealSameRound(gameState!.id);
    } catch (e) {
      developer.log("Error Dealing same round $e");
    }
  }

  Future<void> dealNextRound(String playerId) async {
    try {
      await fs.dealNextRound(gameState!.id, playerId);
    } catch (e) {
      developer.log("Error delaing Next round $e");
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

  void leaveGame() {}
  void endGame() {}

  //GENERAL ACTIONS
}
