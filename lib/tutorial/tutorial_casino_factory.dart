import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:uuid/uuid.dart';

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
      tutorialDeck[2], // 13♣
    ];
    final botPid = Uuid().v4().substring(0, 8);

    final oppHand = [
      tutorialDeck[3], //11♠
      tutorialDeck[4], //2♥
    ];

    final table = [
      tutorialDeck[5], // 3♥
      tutorialDeck[6], // 9♠
      tutorialDeck[7], // K♣
    ];

    final remainingDeck = tutorialDeck.sublist(8);
    return GameState(
      gameStatus: GameStatus.inProgress,
      gameMode: GameMode.casino,
      id: gid,

      started: true,

      controllerId: botPid,
      currentTurnPlayerId: playerId,

      winnerId: "",

      round: round,

      deck: remainingDeck,

      scores: {playerId: 0},

      extraPoints: 0,
      extraPointsHolderId: "",

      playingArea: table,

      playingAreaStacks: [],

      hands: {playerId: playerHand, botPid: oppHand},

      playersDeck: {playerId: []},

      playersInfo: {
        playerId: {"id": playerId, "name": "You", "token": ""},
        botPid: {"id": botPid, "name": "Pulilo the tutor", "token": ""},
      },
      isLocalBot: true,
      botPlayerId: botPid,
      lastTookCardId: '',
      cardMoveEvents: [],
      settlementEvents: [],
    );
  }
}
