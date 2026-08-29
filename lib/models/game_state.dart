import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/models/table_slot.dart';

import 'package:dominican_casino/models/local_bot_roster.dart';
import 'package:dominican_casino/models/wallet_config.dart';

import 'package:dominican_casino/game_control/game_engine/rummy/rummy_state.dart';
import 'package:dominican_casino/game_control/game_engine/bs/bs_state.dart';

import 'playing_card_model.dart';

enum GameStatus { waitingForPlayers, readyToStart, inProgress, gameOver, error }

GameStatus gameStatusFrom(String? s) {
  if (s == null) return GameStatus.error;
  return GameStatus.values.firstWhere((g) => g.name == s);
}

enum GameMode { tresydos, rummy, casino, casinoSpeed, robaito, bs }

/// Friend tables stay open until Start. Tres/Rummy 2–4; BS 3–6; Casino heads-up.
int maxSeatsFor(GameMode mode) {
  switch (mode) {
    case GameMode.bs:
      return 6;
    case GameMode.tresydos:
    case GameMode.rummy:
      return 4;
    case GameMode.casino:
    case GameMode.casinoSpeed:
    case GameMode.robaito:
      return 2;
  }
}

GameMode gameModeFrom(String? s) {
  switch (s) {
    case 'casino':
      return GameMode.casino;
    case 'casinoSpeed':
      return GameMode.casinoSpeed;
    case 'tresydos':
      return GameMode.tresydos;
    case 'rummy':
      return GameMode.rummy;
    case 'robaito':
      return GameMode.robaito;
    case 'bs':
      return GameMode.bs;
    default:
      return GameMode.casino;
  }
}

String gameModeTo(GameMode s) {
  switch (s) {
    case GameMode.casino:
      return 'casino';
    case GameMode.casinoSpeed:
      return 'casinoSpeed';
    case GameMode.tresydos:
      return 'tresydos';
    case GameMode.rummy:
      return 'rummy';
    case GameMode.robaito:
      return 'robaito';
    case GameMode.bs:
      return 'bs';
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

  /// Cards from each player's most recent capture, keyed by pid.
  Map<String, List<PlayingCardModel>> lastTakes;

  final Map<String, dynamic> scores;
  int extraPoints;
  String extraPointsHolderId;
  String lastTookCardId;
  final Map<String, dynamic> playersInfo;

  /// Soft-reserved seats for rematch/invite targets (not paid, not in turn order).
  Map<String, dynamic> invitedPlayers;

  String? winnerId;
  Round round;

  /// Display name of the original on-device AI seat ("Puli").
  static const String localBotName = 'Pulilo';

  /// Avatar used for the original on-device AI seat.
  static const String localBotAvatarId = 'star';

  /// True when one or more seats are the on-device AI, not a remote player.
  bool isLocalBot;
  String? botPlayerId;
  List<String> botPlayerIds;

  /// Coins charged to join this table. Join-by-ID reads this.
  int entryCost;

  /// Uids that already paid [entryCost]. Host is added at create.
  List<String> entryPaidBy;

  /// Players whose match payout coins were already written to their wallet.
  ///
  /// This must be per-player (not one boolean for the whole match) so a
  /// resigner can't accidentally block the winner from claiming later.
  List<String> payoutClaimedBy;

  /// Casino bonuses earned this match, claimed at game over.
  Map<String, int> pendingCoins;

  /// Round id whose virao coins were already added to [pendingCoins].
  int viraosCreditedRoundId;

  /// Take-size coins accrued this round (folded into [round.roundScores]).
  Map<String, int> roundTakeCoins;

  /// Special-card coins accrued this round.
  Map<String, int> roundSpecialCoins;

  /// Virao coins accrued this round.
  Map<String, int> roundViraoCoins;

  /// Rummy-specific persisted state (contract + the card-id overlay per box).
  RummyState? rummyState;

  /// BS-specific persisted state (pile claim + challenge window).
  BsState? bsState;

  /// UTC instant when the current seat's action clock expires.
  /// Shared on the match so every client can render it.
  DateTime? turnDeadline;

  /// Per-turn seconds for Casino Speed (5 / 10 / 25). Ignored for other modes.
  int turnDurationSeconds;

  /// When true, Quick Play can discover and join this waiting room.
  bool isPublic;

  /// Intended table size for public (and seat-capped) rooms. Null = mode max /
  /// classic friends lobby (ready at mode minimum).
  int? targetSeats;

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
    Map<String, dynamic>? invitedPlayers,
    this.isLocalBot = false,
    this.botPlayerId,
    List<String>? botPlayerIds,
    int? entryCost,
    List<String>? entryPaidBy,
    List<String>? payoutClaimedBy,
    Map<String, int>? pendingCoins,
    this.viraosCreditedRoundId = -1,
    Map<String, int>? roundTakeCoins,
    Map<String, int>? roundSpecialCoins,
    Map<String, int>? roundViraoCoins,
    this.rummyState,
    this.bsState,
    List<String>? tableOrder,
    Map<String, List<PlayingCardModel>>? lastTakes,
    this.turnDeadline,
    int? turnDurationSeconds,
    this.isPublic = false,
    this.targetSeats,
  }) : invitedPlayers = invitedPlayers ?? {},
       settlementEvents = settlementEvents ?? [],
       tableOrder = tableOrder ?? [],
       entryCost = entryCost ?? WalletConfig.entryCost,
       entryPaidBy = entryPaidBy ?? [],
       payoutClaimedBy = payoutClaimedBy ?? [],
       pendingCoins = pendingCoins ?? {},
       roundTakeCoins = roundTakeCoins ?? {},
       roundSpecialCoins = roundSpecialCoins ?? {},
       roundViraoCoins = roundViraoCoins ?? {},
       lastTakes = lastTakes ?? {},
       botPlayerIds = List<String>.from(botPlayerIds ?? const []),
       turnDurationSeconds =
           turnDurationSeconds ?? WalletConfig.defaultSpeedTurnSeconds {
    if (this.botPlayerIds.isEmpty &&
        botPlayerId != null &&
        botPlayerId!.isNotEmpty) {
      this.botPlayerIds = [botPlayerId!];
    }
    if (this.botPlayerIds.isNotEmpty) {
      botPlayerId = this.botPlayerIds.first;
    }
  }

  /// First bot pid from persisted fields, or a legacy named seat.
  String? get localBotPid {
    final all = localBotPids;
    return all.isEmpty ? null : all.first;
  }

  List<String> get localBotPids {
    if (botPlayerIds.isNotEmpty) return List<String>.from(botPlayerIds);
    if (botPlayerId != null && botPlayerId!.isNotEmpty) return [botPlayerId!];
    return [
      for (final entry in playersInfo.entries)
        if (entry.value is Map && LocalBotRoster.isBotName(entry.value['name']))
          entry.key,
    ];
  }

  bool isLocalBotPid(String? pid) =>
      pid != null && pid.isNotEmpty && localBotPids.contains(pid);

  /// Invitees that have not joined [playersInfo] yet.
  List<String> get pendingInviteIds => [
        for (final id in invitedPlayers.keys)
          if (!playersInfo.containsKey(id)) id,
      ];

  bool get hasPendingInvites => pendingInviteIds.isNotEmpty;

  bool isPendingInvite(String? pid) =>
      pid != null &&
      pid.isNotEmpty &&
      invitedPlayers.containsKey(pid) &&
      !playersInfo.containsKey(pid);

  Map<String, dynamic>? invitedSeatMap(String pid) {
    final raw = invitedPlayers[pid];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  Duration get turnDuration => gameMode == GameMode.casinoSpeed
      ? Duration(seconds: turnDurationSeconds)
      : WalletConfig.standardTurnDuration;

  bool get _turnClockLive {
    if (gameMode != GameMode.casinoSpeed) return false;
    final pid = currentTurnPlayerId;
    return gameStatus == GameStatus.inProgress &&
        round.roundStatus == RoundStatus.playing &&
        pid != null &&
        pid.isNotEmpty &&
        !isLocalBotPid(pid);
  }

  /// Assign the acting seat and arm a shared action clock when the seat changes.
  void setTurn(String pid) {
    final changed = currentTurnPlayerId != pid;
    currentTurnPlayerId = pid;
    refreshTurnClock(restart: changed);
  }

  /// Keep the existing deadline for the same seat; otherwise arm or clear.
  void refreshTurnClock({bool restart = true}) {
    if (!_turnClockLive) {
      turnDeadline = null;
      return;
    }
    if (!restart && turnDeadline != null) return;
    turnDeadline = DateTime.now().toUtc().add(turnDuration);
  }

  /// Stamp a deadline for live human turns that predate this field.
  /// Returns true when the persisted clock changed.
  bool ensureTurnClock() {
    if (!_turnClockLive) {
      if (turnDeadline == null) return false;
      turnDeadline = null;
      return true;
    }
    if (turnDeadline != null) return false;
    turnDeadline = DateTime.now().toUtc().add(turnDuration);
    return true;
  }

  /// Fill bot fields so a restored match can recreate the AI actor(s).
  void ensureBotMetadata() {
    final ids = localBotPids;
    if (ids.isEmpty) return;
    isLocalBot = true;
    botPlayerIds = ids;
    botPlayerId = ids.first;
  }

  int pendingCoinsFor(String pid) => pendingCoins[pid] ?? 0;

  bool isPayoutClaimedBy(String pid) => payoutClaimedBy.contains(pid);

  void markPayoutClaimedBy(String pid) {
    if (pid.isEmpty) return;
    if (payoutClaimedBy.contains(pid)) return;
    payoutClaimedBy.add(pid);
  }

  void addPendingCoins(String pid, int amount) {
    if (amount <= 0 || pid.isEmpty) return;
    pendingCoins[pid] = pendingCoinsFor(pid) + amount;
  }

  void addRoundTakeCoins(String pid, int amount) {
    if (amount <= 0 || pid.isEmpty) return;
    roundTakeCoins[pid] = (roundTakeCoins[pid] ?? 0) + amount;
  }

  void addRoundSpecialCoins(String pid, int amount) {
    if (amount <= 0 || pid.isEmpty) return;
    roundSpecialCoins[pid] = (roundSpecialCoins[pid] ?? 0) + amount;
  }

  void addRoundViraoCoins(String pid, int amount) {
    if (amount <= 0 || pid.isEmpty) return;
    roundViraoCoins[pid] = (roundViraoCoins[pid] ?? 0) + amount;
  }

  void clearRoundCoinAccrual() {
    roundTakeCoins.clear();
    roundSpecialCoins.clear();
    roundViraoCoins.clear();
  }

  int scoreOf(String pid) {
    final raw = scores[pid];
    return raw is num ? raw.toInt() : 0;
  }

  /// Face-rank total (A=1 … K=13), negated so leftover hands finish negative.
  static int leftoverRankScore(List<PlayingCardModel> hand) {
    var sum = 0;
    for (final c in hand) {
      sum += c.valueLow;
    }
    return -sum;
  }

  /// Winner = 0; everyone else = −(sum of remaining card ranks).
  /// Less negative finishes higher (2nd, 3rd, …) for pot shares.
  void applyLeftoverRankFinishScores(String winnerPid) {
    for (final pid in playersInfo.keys) {
      if (pid == winnerPid) {
        scores[pid] = 0;
      } else {
        scores[pid] = leftoverRankScore(hands[pid] ?? const []);
      }
    }
  }

  int get seatedPlayerCount => playersInfo.length;

  int get maxSeats => maxSeatsFor(gameMode);

  /// Seat cap for joining: public [targetSeats] when set, else mode max.
  int get joinSeatCap {
    final target = targetSeats;
    if (target != null && target > 0) {
      return target.clamp(1, maxSeats);
    }
    return maxSeats;
  }

  /// Highest score first; [winnerId] is always listed first when set.
  List<String> rankedPlayerIds() {
    final ids = playersInfo.keys.toList();
    ids.sort((a, b) {
      final aWon = winnerId != null && winnerId!.isNotEmpty && a == winnerId;
      final bWon = winnerId != null && winnerId!.isNotEmpty && b == winnerId;
      if (aWon != bWon) return aWon ? -1 : 1;
      final byScore = scoreOf(b).compareTo(scoreOf(a));
      if (byScore != 0) return byScore;
      return a.compareTo(b);
    });
    return ids;
  }

  /// Competition ranks (1, 2, 2, 4). [winnerId] is always unique 1st.
  Map<String, int> finishRanks() {
    final ids = playersInfo.keys.toList();
    final ranks = <String, int>{};
    if (ids.isEmpty) return ranks;

    final winner = winnerId;
    final hasWinner =
        winner != null && winner.isNotEmpty && ids.contains(winner);
    final rest = [
      for (final id in ids)
        if (!hasWinner || id != winner) id,
    ]..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));

    if (hasWinner) ranks[winner] = 1;

    var place = hasWinner ? 2 : 1;
    var i = 0;
    while (i < rest.length) {
      final score = scoreOf(rest[i]);
      var j = i + 1;
      while (j < rest.length && scoreOf(rest[j]) == score) {
        j++;
      }
      for (var k = i; k < j; k++) {
        ranks[rest[k]] = place;
      }
      place += j - i;
      i = j;
    }
    return ranks;
  }

  /// 1-based finish place, or null if [pid] is not seated.
  int? finishRank(String pid) => finishRanks()[pid];

  int winPotCoins(String pid) {
    if (gameStatus != GameStatus.gameOver) return 0;
    if (!playersInfo.containsKey(pid)) return 0;
    // Online: only paid seats share the pot.
    // Local AI: show every seat's share of the theoretical table pot.
    if (!isLocalBot && !entryPaidBy.contains(pid)) return 0;

    final rank = finishRank(pid);
    if (rank == null) return 0;
    final pool = WalletConfig.potShareForRank(
      entryCost,
      seatedPlayerCount,
      rank,
    );
    if (pool <= 0) return 0;
    final tied = finishRanks().values.where((r) => r == rank).length;
    if (tied <= 1) return pool;
    return pool ~/ tied;
  }

  int coinsToClaim(String pid) => pendingCoinsFor(pid) + winPotCoins(pid);

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
      lastTakes: {},
      lastTookCardId: '',
      cardMoveEvents: [],
      settlementEvents: [],
      playersInfo: {},
      invitedPlayers: {},
      winnerId: "",
      round: round,
      entryCost: WalletConfig.entryCost,
      entryPaidBy: [],
      payoutClaimedBy: [],
      pendingCoins: {},
      viraosCreditedRoundId: -1,
      roundTakeCoins: {},
      roundSpecialCoins: {},
      roundViraoCoins: {},
      turnDurationSeconds: WalletConfig.defaultSpeedTurnSeconds,
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

  /// Move [cards] into [pid]'s captured pile and remember them as the last take.
  void addCapturedCards(String pid, List<PlayingCardModel> cards) {
    if (cards.isEmpty) return;
    playersDeck.putIfAbsent(pid, () => []);
    playersDeck[pid]!.addAll(cards);
    lastTookCardId = pid;
    lastTakes[pid] = List<PlayingCardModel>.from(cards);
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
    'invitedPlayers': invitedPlayers,
    'playersDeck': playersDeck.map(
      (k, v) => MapEntry(k, v.map((c) => c.toMap()).toList()),
    ),
    'lastTakes': lastTakes.map(
      (k, v) => MapEntry(k, v.map((c) => c.toMap()).toList()),
    ),
    'extraPoints': extraPoints,
    'extraPointsHolderId': extraPointsHolderId,
    'lastTookCardId': lastTookCardId,
    'winnerId': winnerId,
    'round': round.toJson(),
    'isLocalBot': isLocalBot,
    'botPlayerId': ?botPlayerId,
    'botPlayerIds': botPlayerIds,
    'entryCost': entryCost,
    'entryPaidBy': entryPaidBy,
    'payoutClaimedBy': payoutClaimedBy,
    'pendingCoins': pendingCoins,
    'viraosCreditedRoundId': viraosCreditedRoundId,
    'roundTakeCoins': roundTakeCoins,
    'roundSpecialCoins': roundSpecialCoins,
    'roundViraoCoins': roundViraoCoins,
    'rummyState': rummyState?.toJson(),
    'bsState': bsState?.toJson(),
    'turnDeadline': turnDeadline?.toUtc().toIso8601String(),
    'turnDurationSeconds': turnDurationSeconds,
    'isPublic': isPublic,
    'targetSeats': ?targetSeats,
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
    final lastTakes = _cardListMap(m['lastTakes']);
    final roundRaw = m['round'];
    final round = Round.fromJson(
      roundRaw is Map
          ? Map<String, dynamic>.from(roundRaw)
          : <String, dynamic>{},
    );
    final cardMoveEvents =
        (m['cardMoveEvents'] as List?)
            ?.map(
              (e) => CardMoveEvent.fromDto(
                e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
              ),
            )
            .toList() ??
        [];
    final settlementEvents =
        (m['settlementEvents'] as List?)
            ?.map(
              (e) => CardMoveEvent.fromDto(
                e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
              ),
            )
            .toList() ??
        [];
    final tableOrder =
        (m['tableOrder'] as List?)?.map((e) => e.toString()).toList() ??
        <String>[];

    final rummyStateRaw = m['rummyState'];
    final rummyState = rummyStateRaw is Map
        ? RummyState.fromJson(Map<String, dynamic>.from(rummyStateRaw))
        : null;
    final bsStateRaw = m['bsState'];
    final bsState = bsStateRaw is Map
        ? BsState.fromJson(Map<String, dynamic>.from(bsStateRaw))
        : null;
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
      lastTakes: lastTakes,
      lastTookCardId: (m['lastTookCardId'] as String?) ?? '',
      playersInfo: Map<String, dynamic>.from(m['playersInfo'] ?? {}),
      invitedPlayers: Map<String, dynamic>.from(m['invitedPlayers'] ?? {}),
      winnerId: m['winnerId'] as String?,
      extraPoints: (m['extraPoints'] as num?)?.toInt() ?? 0,
      extraPointsHolderId: (m['extraPointsHolderId'] as String?) ?? '',
      round: round,
      isLocalBot: m['isLocalBot'] == true,
      botPlayerId: m['botPlayerId'] as String?,
      botPlayerIds: (m['botPlayerIds'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const <String>[],
      entryCost: (m['entryCost'] as num?)?.toInt() ?? WalletConfig.entryCost,
      entryPaidBy: (m['entryPaidBy'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      // Legacy migrations:
      // - Old documents used a single boolean `payoutApplied`.
      // - We can no longer reconstruct "who" claimed from that boolean.
      //   New games store `payoutClaimedBy`.
      payoutClaimedBy: _stringList(m['payoutClaimedBy']),
      pendingCoins: _intMap(m['pendingCoins']),
      viraosCreditedRoundId: (m['viraosCreditedRoundId'] as num?)?.toInt() ?? -1,
      roundTakeCoins: _intMap(m['roundTakeCoins']),
      roundSpecialCoins: _intMap(m['roundSpecialCoins']),
      roundViraoCoins: _intMap(m['roundViraoCoins']),
      rummyState: rummyState,
      bsState: bsState,
      turnDeadline: _dateTime(m['turnDeadline']),
      turnDurationSeconds: _speedTurnSeconds(m['turnDurationSeconds']),
      isPublic: m['isPublic'] == true,
      targetSeats: (m['targetSeats'] as num?)?.toInt(),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static int _speedTurnSeconds(dynamic raw) {
    final seconds = (raw as num?)?.toInt() ?? WalletConfig.defaultSpeedTurnSeconds;
    return WalletConfig.isAllowedSpeedTurn(seconds)
        ? seconds
        : WalletConfig.defaultSpeedTurnSeconds;
  }

  static DateTime? _dateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    return null;
  }

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    );
  }

  static Map<String, List<PlayingCardModel>> _cardListMap(dynamic raw) {
    if (raw is! Map) return {};
    final out = <String, List<PlayingCardModel>>{};
    raw.forEach((k, v) {
      if (v is! List) {
        out[k.toString()] = const [];
        return;
      }
      out[k.toString()] = v
          .map(
            (e) => PlayingCardModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    });
    return out;
  }
}
