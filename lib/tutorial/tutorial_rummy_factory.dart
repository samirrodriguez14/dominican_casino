import 'package:youareup/game_control/game_engine/rummy/rummy_contract.dart';
import 'package:youareup/game_control/game_engine/rummy/rummy_requirement.dart';
import 'package:youareup/game_control/game_engine/rummy/rummy_state.dart';
import 'package:youareup/models/deck.dart';
import 'package:youareup/models/game_state.dart';
import 'package:youareup/models/player.dart';
import 'package:youareup/models/round.dart';
import 'package:uuid/uuid.dart';

class TutorialRummyFactory {
  static GameState create({
    required String gid,
    required String playerId,
  }) {
    final botPid = Uuid().v4().substring(0, 8);
    final contract = RummyContract(
      requirements: [
        RummyRequirement.colorOf(4, RummyColor.black),
        RummyRequirement.set(3),
      ],
    );

    final hand = [
      Deck.card(id: 'rummy_h1', rank: '2', suit: '♠'),
      Deck.card(id: 'rummy_h2', rank: '3', suit: '♣'),
      Deck.card(id: 'rummy_h3', rank: '4', suit: '♠'),
      Deck.card(id: 'rummy_h4', rank: '4', suit: '♣'),
      Deck.card(id: 'rummy_h5', rank: '9', suit: '♥'),
      Deck.card(id: 'rummy_h6', rank: '9', suit: '♦'),
      Deck.card(id: 'rummy_h7', rank: 'K', suit: '♠'),
    ];
    final discard = Deck.card(id: 'rummy_disc', rank: '5', suit: '♠');
    final deckCards = [
      Deck.card(id: 'rummy_d1', rank: '7', suit: '♥'),
      Deck.card(id: 'rummy_d2', rank: '8', suit: '♣'),
    ];

    return GameState(
      gameStatus: GameStatus.inProgress,
      gameMode: GameMode.rummy,
      id: gid,
      started: true,
      controllerId: playerId,
      currentTurnPlayerId: playerId,
      winnerId: '',
      round: Round(id: 1, roundStatus: RoundStatus.playing, roundScores: {}),
      deck: deckCards,
      scores: {playerId: 0, botPid: 0},
      extraPoints: 0,
      extraPointsHolderId: '',
      playingArea: [discard],
      playingAreaStacks: [],
      hands: {
        playerId: hand,
        botPid: [
          Deck.card(id: 'rummy_o1', rank: '10', suit: '♥'),
          Deck.card(id: 'rummy_o2', rank: 'J', suit: '♣'),
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
      rummyState: RummyState(
        contract: contract,
        boxAByPid: {playerId: [], botPid: []},
        boxBByPid: {playerId: [], botPid: []},
      ),
    );
  }
}
