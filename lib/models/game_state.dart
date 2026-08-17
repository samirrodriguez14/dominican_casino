import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/models/table_slot.dart';

import 'playing_card_model.dart';

enum GameStatus { waitingForPlayers, readyToStart, inProgress, gameOver, error }

GameStatus gameStatusFrom(String? s) {
  if (s == null) return GameStatus.error;
  return GameStatus.values.firstWhere((g) => g.name == s);
}

enum GameMode { tresydos, casino, robaito }

GameMode gameModeFrom(String? s) {
  switch (s) {
    case 'tresydos':
      return GameMode.tresydos;
    case 'casino':
      return GameMode.casino;
    case 'robaito':
      return GameMode.robaito;
    default:
      return GameMode.casino;
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

  /// End-of-round leftover collect only — never mixed into [cardMoveEvents].
  List<CardMoveEvent> settlementEvents = [];

  final List<PlayingCardModel> playingArea;
  final List<PlayingAreaStackModel> playingAreaStacks;

  /// Visual order on the table: `c:<cardId>` or `s:<stackId>`.
  List<String> tableOrder;

  List<PlayingCardModel> deck;
  final Map<String, List<PlayingCardModel>> hands;
  final Map<String, List<PlayingCardModel>> playersDeck;
  final Map<String, dynamic> scores;
  int extraPoints;
  String extraPointsHolderId;
  String lastTookCardId;
  final Map<String, dynamic> playersInfo;
  String? winnerId;
  Round round;

  /// Display name of the on-device AI seat ("Puli").
  static const String localBotName = 'Pulilo';

  /// True when the opponent seat is the on-device AI, not a remote player.
  bool isLocalBot;
  String? botPlayerId;

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
    List<CardMoveEvent>? settlementEvents,
    required this.round,
    required this.winnerId,
    required this.playersInfo,
    this.isLocalBot = false,
    this.botPlayerId,
    List<String>? tableOrder,
  }) : settlementEvents = settlementEvents ?? [],
       tableOrder = tableOrder ?? [];

  /// Bot pid from persisted fields, or a legacy "Pulilo" seat for older games.
  String? get localBotPid {
    if (botPlayerId != null && botPlayerId!.isNotEmpty) return botPlayerId;
    for (final entry in playersInfo.entries) {
      final raw = entry.value;
      if (raw is Map && raw['name'] == localBotName) return entry.key;
    }
    return null;
  }

  /// Fill bot fields so a restored match can recreate the AI actor.
  void ensureBotMetadata() {
    final pid = localBotPid;
    if (pid == null) return;
    isLocalBot = true;
    botPlayerId = pid;
  }

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
      tableOrder: [],
      hands: {},
      playersDeck: {},
      lastTookCardId: '',
      cardMoveEvents: [],
      settlementEvents: [],
      playersInfo: {},
      winnerId: "",
      round: round,
    );
  }

  List<TableSlot> get tableSlots {
    ensureTableOrder();
    final cardsById = {for (final c in playingArea) c.id: c};
    final stacksById = {for (final s in playingAreaStacks) s.id: s};
    final out = <TableSlot>[];
    for (final key in tableOrder) {
      if (TableOrder.isCard(key)) {
        final c = cardsById[TableOrder.idOf(key)];
        if (c != null) out.add(TableCardSlot(c));
      } else if (TableOrder.isStack(key)) {
        final s = stacksById[TableOrder.idOf(key)];
        if (s != null) out.add(TableStackSlot(s));
      }
    }
    return out;
  }

  void ensureTableOrder() {
    if (tableOrder.isNotEmpty) return;
    tableOrder = [
      ...playingAreaStacks.map((s) => TableOrder.stackKey(s.id)),
      ...playingArea.map((c) => TableOrder.cardKey(c.id)),
    ];
  }

  void placeCardOnTable(PlayingCardModel card) {
    playingArea.add(card);
    tableOrder.add(TableOrder.cardKey(card.id));
  }

  void removeLooseCardFromTable(PlayingCardModel card) {
    playingArea.removeWhere((c) => c.id == card.id);
    tableOrder.remove(TableOrder.cardKey(card.id));
  }

  void removeStackFromTable(PlayingAreaStackModel stack) {
    playingAreaStacks.removeWhere((s) => s.id == stack.id);
    tableOrder.remove(TableOrder.stackKey(stack.id));
  }

  void formStackInPlace({
    required PlayingAreaStackModel stack,
    List<PlayingCardModel> removedCards = const [],
    List<PlayingAreaStackModel> removedStacks = const [],
  }) {
    ensureTableOrder();
    int? insertAt;
    for (final c in removedCards) {
      final i = tableOrder.indexOf(TableOrder.cardKey(c.id));
      if (i >= 0 && (insertAt == null || i < insertAt)) insertAt = i;
    }
    for (final s in removedStacks) {
      final i = tableOrder.indexOf(TableOrder.stackKey(s.id));
      if (i >= 0 && (insertAt == null || i < insertAt)) insertAt = i;
    }

    for (final c in removedCards) {
      playingArea.removeWhere((x) => x.id == c.id);
      tableOrder.remove(TableOrder.cardKey(c.id));
    }
    for (final s in removedStacks) {
      playingAreaStacks.removeWhere((x) => x.id == s.id);
      tableOrder.remove(TableOrder.stackKey(s.id));
    }

    playingAreaStacks.add(stack);
    final at = (insertAt ?? tableOrder.length).clamp(0, tableOrder.length);
    tableOrder.insert(at, TableOrder.stackKey(stack.id));
  }

  Map<String, dynamic> toJson() => {
    'gameStatus': gameStatus.name,
    'cardMoveEvents': cardMoveEvents.map((e) => e.toJson()).toList(),
    'settlementEvents': settlementEvents.map((e) => e.toJson()).toList(),
    'id': id,
    'gameMode': gameModeTo(gameMode),
    'controllerId': controllerId,
    'started': started,
    'currentTurnPlayerId': currentTurnPlayerId,
    'deck': deck.map((c) => c.toMap()).toList(),
    'playingArea': playingArea.map((c) => c.toMap()).toList(),
    'playingAreaStacks': playingAreaStacks.map((s) => s.toMap()).toList(),
    'tableOrder': tableOrder,
    'hands': hands.map((k, v) => MapEntry(k, v.map((c) => c.toMap()).toList())),
    'scores': scores,
    'playersInfo': playersInfo,
    'playersDeck': playersDeck.map(
      (k, v) => MapEntry(k, v.map((c) => c.toMap()).toList()),
    ),
    'extraPoints': extraPoints,
    'extraPointsHolderId': extraPointsHolderId,
    'lastTookCardId': lastTookCardId,
    'winnerId': winnerId,
    'round': round.toJson(),
    'isLocalBot': isLocalBot,
    'botPlayerId': botPlayerId,
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
    final settlementEvents =
        (m['settlementEvents'] as List?)
            ?.map((e) => CardMoveEvent.fromDto(e))
            .toList() ??
        [];
    final tableOrder =
        (m['tableOrder'] as List?)?.map((e) => e.toString()).toList() ??
        <String>[];
    return GameState(
      gameStatus: gameStatus,
      gameMode: gameMode,
      cardMoveEvents: cardMoveEvents,
      settlementEvents: settlementEvents,
      id: (m['id'] as String?) ?? '',
      controllerId: (m['controllerId'] as String?) ?? '',
      started: m['started'] == true,
      currentTurnPlayerId: m['currentTurnPlayerId'] as String?,
      deck: deck,
      playingArea: playing,
      playingAreaStacks: areaStack,
      tableOrder: tableOrder,
      scores: Map<String, dynamic>.from(m['scores'] ?? {}),
      hands: hands,
      playersDeck: playersDeck,
      lastTookCardId: (m['lastTookCardId'] as String?) ?? '',
      playersInfo: Map<String, dynamic>.from(m['playersInfo'] ?? {}),
      winnerId: m['winnerId'] as String?,
      extraPoints: m['extraPoints'],
      extraPointsHolderId: m['extraPointsHolderId'],
      round: round,
      isLocalBot: m['isLocalBot'] == true,
      botPlayerId: m['botPlayerId'] as String?,
    );
  }
}
