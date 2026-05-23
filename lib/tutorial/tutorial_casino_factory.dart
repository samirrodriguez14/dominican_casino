import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';

class TutorialCasinoFactory {
  static GameState createBasicTakeTutorial({
    required String gid,
    required String playerId,
  }) {
    final round = Round(
      id: 1,
      roundStatus: RoundStatus.playing,
      roundScores: {},
    );

    // tiny remaining deck so game engine doesn't break
    final tutorialDeck = Deck.casinoTutorialDeck();

    final playerHand = [
      tutorialDeck[0], // 5♦
      tutorialDeck[1], // 8♠
    ];
    final String oppId = "pulilo_tutor";
    final oppHand = [tutorialDeck[2], tutorialDeck[3]];

    final table = [
      tutorialDeck[4], // 2♣
      tutorialDeck[5], // 3♥
      tutorialDeck[6], // 9♠
      tutorialDeck[7], // A♦
    ];

    final remainingDeck = tutorialDeck.sublist(8);
    return GameState(
      gameStatus: GameStatus.inProgress,
      gameMode: GameMode.casino,
      id: gid,

      started: true,

      controllerId: playerId,
      currentTurnPlayerId: playerId,

      winnerId: "",

      round: round,

      deck: remainingDeck,

      scores: {playerId: 0},

      extraPoints: 0,
      extraPointsHolderId: "",

      playingArea: table,

      playingAreaStacks: [],

      hands: {playerId: playerHand, oppId: oppHand},

      playersDeck: {playerId: []},

      playersInfo: {
        playerId: {"id": playerId, "name": "You", "token": ""},
        oppId: {"id": oppId, "name": "Puli", "token": ""},
      },

      lastTookCardId: '',
      cardMoveEvents: [],
    );
  }
}
