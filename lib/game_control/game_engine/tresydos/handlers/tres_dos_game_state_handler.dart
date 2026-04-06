import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';

class TresDosGameStateHandler {
  //USE TO MAKE CHANGES TO THE GAME STATTE...
  //UPDATING GAMESTATE CURRENTPLAYER ID

  static String getNextPlayerId(GameState gameState, String pid) {
    final players = gameState.playersInfo.keys.toList();

    if (players.isEmpty) return "";

    final index = players.indexOf(pid);
    if (index == -1) return players.first;

    final nextIndex = (index + 1) % players.length;
    return players[nextIndex];
  }

  static String getNextControllerId(GameState gameState) {
    final players = (gameState.playersInfo.keys).toList();

    if (players.isEmpty) return '';

    final currentIndex = players.indexOf(gameState.controllerId);

    if (currentIndex == -1) {
      return players.first;
    }

    final nextIndex = (currentIndex + 1) % players.length;
    return players[nextIndex];
  }

  ///UPDATING SAME ROUND
  ///
  static bool shouldDealSameRound(GameState gameState) {
    return gameState.playingArea.isEmpty;
  }

  ///UPDATING ROUND AND GAME STATUS ON ROUND ENDED
  ///
  static GameState handleRoundEnded(GameState gameState, String performedBy) {
    gameState.scores[performedBy] = (gameState.scores[performedBy] ?? 0) + 1;
    gameState.round.roundStatus = RoundStatus.completed;
    gameState.controllerId = getNextControllerId(gameState);
    gameState.winnerId = _handleWinner(
      gameState.scores,
      gameState.round.roundScores,
    );
    if (gameState.winnerId != null && gameState.winnerId != "") {
      gameState.gameStatus = GameStatus.gameOver;
      return gameState;
    }
    gameState.round.id += 1;
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

  static String? _handleWinner(
    Map<String, dynamic> prevScore,
    Map<String, dynamic> roundScore,
  ) {
    final playerIds = roundScore.keys.toList();

    playerIds.sort((a, b) {
      final aScore = prevScore[a] ?? 0;
      final bScore = prevScore[b] ?? 0;
      return bScore.compareTo(aScore);
    });

    for (final pid in playerIds) {
      final prev = prevScore[pid] ?? 0;
      final roundTotal = roundScore[pid]['total'] ?? 0;
      if (prev + roundTotal == 3) {
        return pid;
      }
    }
    return null;
  }

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
    gameState.cardMoveEvents = [];

    gameState.currentTurnPlayerId = '';
    gameState.controllerId = pid;

    gameState.round.roundStatus = RoundStatus.readyToDeal;

    return gameState;
  }
}
