import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
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

    // Tutorial is intentionally short: only teach the 5♦ add and 8♠ take
    // flow. The King card is omitted so the later "King take" beats
    // don't exist anymore.
    final playerHand = [
      tutorialDeck[0], // 5♦
      tutorialDeck[1], // 8♠
    ];
    final botPid = Uuid().v4().substring(0, 8);

    final oppHand = [
      tutorialDeck[3], // 9♦ — captures the table 9
      tutorialDeck[4], // 2♥ — dumped after the stack take (next to the J)
    ];

    final table = [
      tutorialDeck[6], // 3♥
      tutorialDeck[7], // 9♠
      tutorialDeck[8], // J♣
    ];

    final remainingDeck = tutorialDeck.sublist(9);
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

      scores: {playerId: 0, botPid: 0},

      extraPoints: 0,
      extraPointsHolderId: "",

      playingArea: table,

      playingAreaStacks: [],

      hands: {playerId: playerHand, botPid: oppHand},

      playersDeck: {playerId: []},

      playersInfo: {
        playerId: {
          "id": playerId,
          "name": "You",
          "token": "",
          "avatarId": Player.defaultAvatarId,
        },
        botPid: {
          "id": botPid,
          "name": "Pulilo the tutor",
          "token": "",
          "avatarId": GameState.localBotAvatarId,
        },
      },
      isLocalBot: true,
      botPlayerId: botPid,
      lastTookCardId: '',
      cardMoveEvents: [],
      settlementEvents: [],
    );
  }
}
