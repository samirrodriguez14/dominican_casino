import 'package:dominican_casino/game_control/game_engine/general_handlers/game_action_handler.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';

class CasinoGameStateHandler {
  //USE TO MAKE CHANGES TO THE GAME STATTE...
  //UPDATING GAMESTATE CURRENTPLAYER ID

  ///UPDATING SAME ROUND
  ///
  static bool shouldDealSameRound(GameState gameState) {
    final allHandsEmpty = gameState.hands.entries.every((p) => p.value.isEmpty);
    final deckStillHasCards = gameState.deck.isNotEmpty;

    return allHandsEmpty && deckStillHasCards;
  }

  static GameState handleExtraPoints(GameState g, String currentPid) {
    final holder = g.extraPointsHolderId;
    int points = g.extraPoints;
    if (g.playingArea.isNotEmpty || g.playingAreaStacks.isNotEmpty) return g;

    if (points == 0 || holder == "") {
      g.extraPointsHolderId = currentPid;
      g.extraPoints = 1;
      return g;
    }
    if (holder == currentPid) {
      g.extraPoints = points + 1;
    } else {
      g.extraPoints = points - 1;
      if (g.extraPoints == 0) {
        g.extraPointsHolderId = "";
      }
    }

    return g;
  }

  ///UPDATING ROUND AND GAME STATUS ON ROUND ENDED
  ///
  static GameState handleRoundEnded(GameState gameState) {
    gameState = _handleScores(gameState);
    gameState.round.roundStatus = RoundStatus.completed;
    gameState.controllerId = GameActionHandler.getNextControllerId(gameState);
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
      if (prev + roundTotal >= 21) {
        return pid;
      }
    }

    return null;
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
    final roundScores = <String, dynamic>{};
    final totalScores = Map<String, dynamic>.from(gameState.scores);

    final playerIds = (gameState.playersInfo.keys).toList();

    for (final pid in playerIds) {
      final playerDeck = gameState.playersDeck[pid] ?? [];

      roundScores[pid] = _createScoreMap(
        playerDeck,
        gameState.extraPointsHolderId == pid ? gameState.extraPoints : 0,
        gameState.scores[pid] ?? 0,
      );

      totalScores[pid] =
          (totalScores[pid] ?? 0) + (roundScores[pid]['total'] as int);
    }

    gameState.round.roundScores = roundScores;
    gameState.scores.clear();
    gameState.scores.addAll(totalScores);

    return gameState;
  }

  static Map<String, dynamic> _createScoreMap(
    List<PlayingCardModel> playerDeck,
    int extraPoints,
    int prevScore,
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

    totalScore += extraPoints;
    scoresMap['total'] = totalScore;

    // Apply endgame restrictions here

    // if score == 20, player needs pi
    if (prevScore == 20) {
      if ((scoresMap['pi'] as int) == 0) {
        scoresMap['A'] = 0;
        scoresMap['10♦'] = 0;
        scoresMap['2♠'] = 0;
        scoresMap['carta'] = 0;
        scoresMap['virao'] = 0;
        scoresMap['total'] = 0;
      }
    }
    // if score == 18 or 19, player only keeps carta + pi
    else if (prevScore == 18 || prevScore == 19) {
      if ((scoresMap['carta'] as int) == 0) {
        scoresMap['A'] = 0;
        scoresMap['10♦'] = 0;
        scoresMap['2♠'] = 0;
        scoresMap['virao'] = 0;
        scoresMap['total'] = (scoresMap['pi'] as int);
      }
    }
    // if score == 17, player only keeps carta + pi, and needs both
    else if (prevScore == 17) {
      final hasCarta = (scoresMap['carta'] as int) > 0;
      final hasPi = (scoresMap['pi'] as int) > 0;

      if (!hasCarta || !hasPi) {
        scoresMap['A'] = 0;
        scoresMap['10♦'] = 0;
        scoresMap['2♠'] = 0;
        scoresMap['virao'] = 0;
        scoresMap['total'] =
            (scoresMap['pi'] as int) + (scoresMap['carta'] as int);
      }
    }

    return scoresMap;
  }

  static GameState settleEndOfRoundIfNeeded(GameState gameState) {
    if (!roundEnded(gameState)) gameState;

    if (gameState.playingArea.isEmpty && gameState.playingAreaStacks.isEmpty) {
      gameState;
    }

    final lastTaker = gameState.lastTookCardId.trim();
    final playerIds = (gameState.playersInfo.keys)
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final receiver = lastTaker.isNotEmpty
        ? lastTaker
        : (playerIds.isNotEmpty ? playerIds.first : '');

    if (receiver.isEmpty) gameState;

    final leftovers = <PlayingCardModel>[];
    leftovers.addAll(gameState.playingArea);

    for (final stack in gameState.playingAreaStacks) {
      leftovers.addAll(stack.cards);
    }

    gameState.playersDeck.putIfAbsent(receiver, () => []);
    gameState.playersDeck[receiver]!.addAll(leftovers);

    gameState.playingArea.clear();
    gameState.playingAreaStacks.clear();
    return gameState;
  }

}
