import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/ui/app_shell/games/games_screen.dart';

import 'playing_card_model.dart';

enum RoundStatus { playing, completed, dealing }

RoundStatus roundStatusFrom(String? s) {
  switch (s) {
    case 'completed':
      return RoundStatus.completed;
    case 'dealing':
      return RoundStatus.dealing;
    case 'playing':
    default:
      return RoundStatus.playing;
  }
}

String roundStatusTo(RoundStatus s) {
  switch (s) {
    case RoundStatus.completed:
      return 'completed';
    case RoundStatus.dealing:
      return 'dealing';
    case RoundStatus.playing:
      return 'playing';
  }
}

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
  final String id;
  final String controllerId;
  bool started;
  String? currentTurnPlayerId;
  List<CardMoveEvent> cardMoveEvents = [];
  final List<PlayingCardModel> playingArea;
  final List<PlayingAreaStackModel> playingAreaStacks;

  final List<PlayingCardModel> deck;
  final Map<String, List<PlayingCardModel>> hands;
  final Map<String, List<PlayingCardModel>> playersDeck;
  final Map<String, dynamic> scores;
  final int extraPoints;
  final String extraPointsHolderId;
  final String lastTookCardId;
  final String? player1;
  final String? player2;
  final Map<String, dynamic>? playersInfo;
  final String? winnerId;
  final int roundIndex;
  final RoundStatus roundStatus;
  final Map<String, bool> roundReady;
  final Map<String, dynamic> roundScores;

  GameState({
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
    this.winnerId,
    this.player1,
    this.player2,
    this.playersInfo,

    // round defaults (safe for old docs)
    this.roundIndex = 1,
    this.roundStatus = RoundStatus.playing,
    Map<String, bool>? roundReady,
    Map<String, dynamic>? roundScores,
  }) : roundReady = roundReady ?? const {},
       roundScores = roundScores ?? const {};

  Map<String, dynamic> toJson() => {
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

    'roundIndex': roundIndex,
    'roundStatus': roundStatusTo(roundStatus),
    'roundReady': roundReady,
    'roundScores': roundScores,
  };

  static GameState fromMap(Map<String, dynamic> m) {
    final gameMode = gameModeFrom(m['gameMode']);
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

    final roundIndex = (m['roundIndex'] as int?) ?? 1;
    final roundStatus = roundStatusFrom(m['roundStatus'] as String?);

    final roundReadyRaw = Map<String, dynamic>.from(m['roundReady'] ?? {});
    final roundReady = <String, bool>{};
    roundReadyRaw.forEach((k, v) {
      roundReady[k] = v == true;
    });

    final roundScores = Map<String, dynamic>.from(m['roundScores'] ?? {});
    final cardMoveEvents =
        (m['cardMoveEvents'] as List?)
            ?.map((e) => CardMoveEvent.fromDto(e))
            .toList() ??
        [];
    return GameState(
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
      roundIndex: roundIndex,
      roundStatus: roundStatus,
      roundReady: roundReady,
      roundScores: roundScores,
    );
  }
}
