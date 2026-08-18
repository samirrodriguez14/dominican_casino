import 'package:dominican_casino/game_control/game_engine/general_handlers/game_action_handler.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';

class TresDosGameStateHandler {
  //USE TO MAKE CHANGES TO THE GAME STATTE...
  //UPDATING GAMESTATE CURRENTPLAYER ID
  static GameState shuffleAction(GameState gameState, String pid) {
    gameState.deck = Deck.shuffle(Deck.standard());

    gameState.playingArea.clear();
    gameState.playingAreaStacks.clear();

    gameState.hands.clear();

    for (final playerId in gameState.playersInfo.keys) {
      gameState.hands[playerId] = [];
      gameState.playersDeck[playerId] = [];
    }

    gameState.extraPoints = 0;
    gameState.extraPointsHolderId = '';
    gameState.lastTookCardId = '';
    gameState.lastTakes.clear();
    gameState.cardMoveEvents = [];
    gameState.settlementEvents = [];

    gameState.currentTurnPlayerId = '';
    gameState.controllerId = pid;

    gameState.round.roundStatus = RoundStatus.readyToDeal;

    return gameState;
  }

  static String getNextPlayerId(GameState gameState, String pid) {
    final players = gameState.playersInfo.keys.toList();

    if (players.isEmpty) return "";

    final index = players.indexOf(pid);
    if (index == -1) return players.first;

    final nextIndex = (index + 1) % players.length;
    return players[nextIndex];
  }

  ///UPDATING SAME ROUND
  ///
  static bool shouldDealSameRound(GameState gameState) {
    return gameState.deck.isEmpty;
  }

  ///UPDATING ROUND AND GAME STATUS ON ROUND ENDED
  ///
  static GameState handleRoundEnded(GameState gameState, String performedBy) {
    gameState.scores[performedBy] = (gameState.scores[performedBy] ?? 0) + 1;
    gameState.round.roundStatus = RoundStatus.completed;
    gameState.round.nextAcknowledged = false;
    gameState.controllerId = GameActionHandler.getNextControllerId(gameState);
    bool won = gameState.scores[performedBy] >= 3;
    if (won) {
      gameState.winnerId = performedBy;
      gameState.gameStatus = GameStatus.gameOver;
      return gameState;
    }

    gameState.round.id += 1;
    return gameState;
  }

  static GameState handleShuffleRound(GameState gameState) {
    gameState.deck = Deck.shuffle(gameState.playingArea);
    gameState.playingArea.clear();
    return gameState;
  }

  static bool roundEnded(GameState gameState, String performedBy) {
    final myHand = gameState.hands[performedBy];
    if (myHand == null || myHand.isEmpty) return false;
    final Map<int, int> counts = {};
    for (final card in myHand) {
      counts[card.valueLow] = (counts[card.valueLow] ?? 0) + 1;
    }
    return counts.length == 2 &&
        counts.values.contains(2) &&
        counts.values.contains(3);
  }
}
