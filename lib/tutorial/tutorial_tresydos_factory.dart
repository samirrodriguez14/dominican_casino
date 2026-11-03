import 'package:youareup/models/deck.dart';
import 'package:youareup/models/game_state.dart';
import 'package:youareup/models/player.dart';
import 'package:youareup/models/round.dart';
import 'package:uuid/uuid.dart';

class TutorialTresydosFactory {
  static GameState create({
    required String gid,
    required String playerId,
  }) {
    final botPid = Uuid().v4().substring(0, 8);
    return GameState(
      gameStatus: GameStatus.inProgress,
      gameMode: GameMode.tresydos,
      id: gid,
      started: true,
      controllerId: playerId,
      currentTurnPlayerId: playerId,
      winnerId: '',
      round: Round(id: 1, roundStatus: RoundStatus.playing, roundScores: {}),
      deck: [
        Deck.card(id: 'tyd_d1', rank: '6', suit: '♥'),
        Deck.card(id: 'tyd_d2', rank: '7', suit: '♣'),
      ],
      scores: {playerId: 0, botPid: 0},
      extraPoints: 0,
      extraPointsHolderId: '',
      playingArea: [
        Deck.card(id: 'tyd_disc', rank: '5', suit: '♦'),
      ],
      playingAreaStacks: [],
      hands: {
        playerId: [
          Deck.card(id: 'tyd_h1', rank: '8', suit: '♠'),
          Deck.card(id: 'tyd_h2', rank: '8', suit: '♥'),
          Deck.card(id: 'tyd_h3', rank: '8', suit: '♦'),
          Deck.card(id: 'tyd_h4', rank: 'K', suit: '♣'),
          Deck.card(id: 'tyd_h5', rank: 'K', suit: '♠'),
        ],
        botPid: [
          Deck.card(id: 'tyd_o1', rank: '3', suit: '♥'),
          Deck.card(id: 'tyd_o2', rank: '4', suit: '♣'),
        ],
      },
      playersDeck: {playerId: []},
      playersInfo: {
        playerId: {
          'id': playerId,
          'name': 'You',
          'avatarId': Player.defaultAvatarId,
        },
        botPid: {
          'id': botPid,
          'name': 'Pulilo the tutor',
          'avatarId': GameState.localBotAvatarId,
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
