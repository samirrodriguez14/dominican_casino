import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/round.dart';

import 'playing_card_model.dart';

enum GameStatus { waitingForPlayers, readyToStart, inProgress, gameOver, error }

GameStatus gameStatusFrom(String? s) {
  if (s == null) return GameStatus.error;
  return GameStatus.values.firstWhere((g) => g.name == s);
}

enum GameMode { tresydos, casino, casinoNew, robaito }

GameMode gameModeFrom(String? s) {
  switch (s) {
    case 'tresydos':
      return GameMode.tresydos;
    case 'casino':
      return GameMode.casino;
    case 'casinoNew':
      return GameMode.casinoNew;
    case 'robaito':
    default:
      return GameMode.robaito;
  }
}

String gameModeTo(GameMode s) {
  switch (s) {
    case GameMode.tresydos:
      return 'tresydos';
    case GameMode.casino:
      return 'casino';
    case GameMode.robaito:
      return 'robaito';
    case GameMode.casinoNew:
      return 'casinoNew';
  }
}

class GameState {
  final GameMode gameMode;
  GameStatus gameStatus;
  final String id;
  String controllerId;
  bool started;
  String? currentTurnPlayerId;
  List<CardMoveEvent> cardMoveEvents = [];
  final List<PlayingCardModel> playingArea;
  final List<PlayingAreaStackModel> playingAreaStacks;

  List<PlayingCardModel> deck;
  final Map<String, List<PlayingCardModel>> hands;
  final Map<String, List<PlayingCardModel>> playersDeck;
  final Map<String, dynamic> scores;
  int extraPoints;
  String extraPointsHolderId;
  String lastTookCardId;
  final String? player1;
  final String? player2;
  final Map<String, dynamic>? playersInfo;
  String? winnerId;
  Round round;

  GameState({
    required this.gameStatus,
    required this.gameMode,
    required this.id,
    required this.controllerId,
    required this.started,
    required this.currentTurnPlayerId,
    required this.deck,
    required this.scores,
    required this.extraPoints,
    required this.extraPointsHolderId,
    required this.playingArea,
    required this.playingAreaStacks,
    required this.hands,
    required this.playersDeck,
    required this.lastTookCardId,
    required this.cardMoveEvents,
    required this.round,
    required this.winnerId,
    required this.player1,
    required this.player2,
    required this.playersInfo,
  });

  factory GameState.create(String gid, String pid, GameMode mode) {
    final round = Round(
      id: 0,
      roundStatus: RoundStatus.completed,
      roundScores: {},
    );
    return GameState(
      gameStatus: GameStatus.waitingForPlayers,
      gameMode: mode,
      id: gid,
      controllerId: pid,
      started: false,
      currentTurnPlayerId: "",
      deck: (Deck.shuffle(Deck.standard())),
      scores: {},
      extraPoints: 0,
      extraPointsHolderId: "",
      playingArea: [],
      playingAreaStacks: [],
      hands: {},
      playersDeck: {},
      lastTookCardId: '',
      cardMoveEvents: [],
      playersInfo: {},
      player1: "",
      player2: "",
      winnerId: "",
      round: round,
    );
  }

  Map<String, dynamic> toJson() => {
    'gameStatus': gameStatus.name,
    'cardMoveEvents': cardMoveEvents.map((e) => e.toJson()).toList(),
    'id': id,
    'gameMode': gameModeTo(gameMode),
    'controllerId': controllerId,
    'started': started,
    'currentTurnPlayerId': currentTurnPlayerId,

    'deck': deck.map((c) => c.toMap()).toList(),
    'playingArea': playingArea.map((c) => c.toMap()).toList(),
    'playingAreaStacks': playingAreaStacks.map((s) => s.toMap()).toList(),

    'hands': hands.map((k, v) => MapEntry(k, v.map((c) => c.toMap()).toList())),
    'scores': scores,
    'playersInfo': playersInfo,
    'playersDeck': playersDeck.map(
      (k, v) => MapEntry(k, v.map((c) => c.toMap()).toList()),
    ),
    'extraPoints': extraPoints,
    'extraPointsHolderId': extraPointsHolderId,
    'lastTookCardId': lastTookCardId,

    'player1': player1,
    'player2': player2,
    'winnerId': winnerId,
    'round': round.toJson(),
  };

  static GameState fromMap(Map<String, dynamic> m) {
    final gameMode = gameModeFrom(m['gameMode']);
    final gameStatus = gameStatusFrom(m['gameStatus']);
    final playing = (m['playingArea'] as List<dynamic>? ?? [])
        .map((e) => PlayingCardModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final deck = (m['deck'] as List<dynamic>? ?? [])
        .map((e) => PlayingCardModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final rawStacks = (m['playingAreaStacks'] as List?) ?? const [];
    final areaStack = rawStacks
        .map(
          (e) => PlayingAreaStackModel.fromMap(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();

    final handsRaw = Map<String, dynamic>.from(m['hands'] ?? {});
    final hands = <String, List<PlayingCardModel>>{};
    handsRaw.forEach((k, v) {
      hands[k] = (v as List)
          .map((e) => PlayingCardModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });

    final playersDeckRaw = Map<String, dynamic>.from(m['playersDeck'] ?? {});
    final playersDeck = <String, List<PlayingCardModel>>{};
    playersDeckRaw.forEach((k, v) {
      playersDeck[k] = (v as List)
          .map((e) => PlayingCardModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
    final round = Round.fromJson(m['round']);
    final cardMoveEvents =
        (m['cardMoveEvents'] as List?)
            ?.map((e) => CardMoveEvent.fromDto(e))
            .toList() ??
        [];
    return GameState(
      gameStatus: gameStatus,
      gameMode: gameMode,
      cardMoveEvents: cardMoveEvents,
      id: (m['id'] as String?) ?? '',
      controllerId: (m['controllerId'] as String?) ?? '',
      started: m['started'] == true,
      currentTurnPlayerId: m['currentTurnPlayerId'] as String?,
      deck: deck,
      playingArea: playing,
      playingAreaStacks: areaStack,
      scores: Map<String, dynamic>.from(m['scores'] ?? {}),
      hands: hands,
      playersDeck: playersDeck,
      lastTookCardId: (m['lastTookCardId'] as String?) ?? '',
      player1: m['player1'] as String?,
      player2: m['player2'] as String?,
      playersInfo: m['playersInfo'],
      winnerId: m['winnerId'] as String?,
      extraPoints: m['extraPoints'],
      extraPointsHolderId: m['extraPointsHolderId'],
      round: round,
    );
  }
}
