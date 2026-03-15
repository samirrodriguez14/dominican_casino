import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';

class GameStateHandler {
  //USE TO MAKE CHANGES TO THE GAME STATTE...
  //UPDATING GAMESTATE CURRENTPLAYER ID

  static String getNextPlayerId(GameState gameState, String pid) {
    final players = gameState.playersInfo?.keys.toList() ?? [];

    if (players.isEmpty) return "";

    final index = players.indexOf(pid);
    if (index == -1) return players.first;

    final nextIndex = (index + 1) % players.length;
    return players[nextIndex];
  }

  ///UPDATING ROUND AND GAME STATUS ON ROUND ENDED
  ///
  static GameState handleRoundEnded(GameState gameState) {
    gameState = _handleScores(gameState);

    // complete current round
    final completedRound = Round(
      id: gameState.round.id,
      roundStatus: RoundStatus.completed,
      roundScores: Map<String, dynamic>.from(
        gameState.round.roundScores,
      ),
    );

    gameState.round = completedRound;
    // if game is not over, prepare next round
    if (gameState.winnerId == null || gameState.winnerId!.isEmpty) {
      final nextRoundId = completedRound.id + 1;

      gameState.round = Round(
        id: nextRoundId,
        roundStatus: RoundStatus.dealing,

        roundScores: {},
      );
    }

    return gameState;
  }

  static bool roundEnded(GameState gameState) {
    List<bool> handsEmptyVals = [];
    for (var entry in gameState.hands.entries) {
      handsEmptyVals.add(entry.value.isEmpty);
    }
    bool handsEmpty = handsEmptyVals.every((v) => v);

    return gameState.started && gameState.deck.isEmpty && handsEmpty;
  }

  static GameState _handleScores(GameState gameState) {
    final p1 = gameState.player1 as String;
    final p2 = gameState.player2 as String;

    final p1Deck = gameState.playersDeck[p1] ?? [];
    final p2Deck = gameState.playersDeck[p2] ?? [];

    final roundScores = <String, dynamic>{};

    roundScores[p1] = _createScoreMap(
      p1Deck,
      gameState.extraPointsHolderId == p1 ? gameState.extraPoints : 0,
    );

    roundScores[p2] = _createScoreMap(
      p2Deck,
      gameState.extraPointsHolderId == p2 ? gameState.extraPoints : 0,
    );

    final totalScores = Map<String, dynamic>.from(gameState.scores);

    // final winner = _handleWinner(totalScores, roundScores, p1, p2);

    totalScores[p1] =
        (totalScores[p1] ?? 0) + (roundScores[p1]['total'] as int);
    totalScores[p2] =
        (totalScores[p2] ?? 0) + (roundScores[p2]['total'] as int);

    gameState.round = Round(
      id: gameState.round.id,
      roundStatus: RoundStatus.completed,
      roundScores: roundScores,
    );

    gameState.scores.clear();
    gameState.scores.addAll(totalScores);

    gameState.extraPoints = 0;
    gameState.extraPointsHolderId = '';
    // gameState.winnerId = winner;
    return gameState;
  }

  static Map<String, dynamic> _createScoreMap(
    List<PlayingCardModel> playerDeck,
    int extraPoints,
  ) {
    final scoresMap = <String, dynamic>{
      'A': 0,
      '2♠': 0,
      '10♦': 0,
      'pi': 0,
      'carta': 0,
      'virao': extraPoints,
      'total': 0,
    };

    var totalScore = 0;

    if (playerDeck.length > 26) {
      totalScore += 3;
      scoresMap['carta'] = 3;
    }

    for (final card in playerDeck) {
      if (card.rank == 'A') {
        totalScore += 1;
        scoresMap['A'] = (scoresMap['A'] as int) + 1;
      }
      if (card.rank == '2' && card.suit == '♠') {
        totalScore += 1;
        scoresMap['2♠'] = (scoresMap['2♠'] as int) + 1;
      }
      if (card.rank == '10' && card.suit == '♦') {
        totalScore += 2;
        scoresMap['10♦'] = (scoresMap['10♦'] as int) + 2;
      }
    }

    final spadesCount = playerDeck.where((c) => c.suit == '♠').length;
    if (spadesCount > 6) {
      totalScore += 1;
      scoresMap['pi'] = 1;
    }

    scoresMap['total'] = totalScore + extraPoints;
    return scoresMap;
  }
}
