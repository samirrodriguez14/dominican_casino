import 'package:youareup/game_control/game_engine/bs/bs_state.dart';
import 'package:youareup/models/deck.dart';
import 'package:youareup/models/game_state.dart';
import 'package:youareup/models/player.dart';
import 'package:youareup/models/round.dart';
import 'package:uuid/uuid.dart';

class TutorialBsFactory {
  static GameState create({
    required String gid,
    required String playerId,
  }) {
    final botPid = Uuid().v4().substring(0, 8);
    return GameState(
      gameStatus: GameStatus.inProgress,
      gameMode: GameMode.bs,
      id: gid,
      started: true,
      controllerId: botPid,
      currentTurnPlayerId: botPid,
      winnerId: '',
      round: Round(id: 1, roundStatus: RoundStatus.playing, roundScores: {}),
      deck: [],
      scores: {playerId: 0, botPid: 0},
      extraPoints: 0,
      extraPointsHolderId: '',
      playingArea: [],
      playingAreaStacks: [],
      hands: {
        playerId: [
          Deck.card(id: 'bs_h1', rank: '9', suit: '♠'),
          Deck.card(id: 'bs_h2', rank: '9', suit: '♥'),
          Deck.card(id: 'bs_h3', rank: '9', suit: '♦'),
        ],
        botPid: [
          Deck.card(id: 'bs_o1', rank: 'J', suit: '♣'),
          Deck.card(id: 'bs_o2', rank: '2', suit: '♥'),
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
      bsState: BsState(
        phase: BsPhase.challenge,
        lastPlayedCardIds: ['bs_o1', 'bs_o2'],
        lastClaimPid: botPid,
        lastClaimCount: 2,
        lastClaimRank: 'J',
        challengeDeadline: DateTime.now().toUtc().add(BsState.challengeWindow),
      ),
    );
  }
}
