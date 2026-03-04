import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:uuid/uuid.dart';

class GameHandler2 {
  GameHandler2({required FirebaseFirestore db, CollectionReference? games})
    : _db = db,
      _games = games ?? db.collection('games');

  final FirebaseFirestore _db;
  final CollectionReference _games;
  final Uuid _uuid = const Uuid();

  /// CREATE GAME (moved from FirestoreService)
  Future<String> createGame() async {
    final id = _uuid.v4().substring(0, 8);
    final doc = _games.doc(id);

    await doc.set({
      'id': id,
      'controllerId': null,
      'started': false,
      'currentTurnPlayerId': null,
      'deck': _createDeck(),
      'playingArea': [],
      'playingAreaStacks': [],
      'hands': {},
      'scores': {},
      'playersDeck': {},
      'lastTookCardId': '',
      'player1': '',
      'player2': '',
      'winnerId': null,
      'roundIndex': 1,
      'roundStatus': 'playing',
      'roundReady': {},
      'roundScores': {},
    });

    return id;
  }

  //JOIN GAME
  Future<String?> joinGame({
    required String gameId,
    required String pid,
  }) async {
    final doc = _games.doc(gameId);
    developer.log("GameId: $gameId, Pid: $pid");

    await _db.runTransaction((tx) async {
      final s = await tx.get(doc);
      if (!s.exists) return;

      final data = s.data() as Map<String, dynamic>;

      var player1 = (data['player1'] as String?) ?? '';
      var player2 = (data['player2'] as String?) ?? '';

      developer.log("player1: $player1; player2: $player2");

      if (player1 == "") {
        player1 = pid;
      } else if (player2 == "") {
        player2 = pid;
      } else {
        developer.log("Game full");
        return;
      }

      final controller = (data['controllerId'] as String?) ?? player1;

      tx.update(doc, {
        'player1': player1,
        'player2': player2,
        'controllerId': controller,
      });
    });

    return pid;
  }

  /// START GAME
  Future<void> startGame(String gameId) async {
    final doc = _games.doc(gameId);
    final snap = await doc.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final deck = (data['deck'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final p1 = _drawFromDeck(deck, 4);
    final p2 = _drawFromDeck(deck, 4);

    final started = data['started'] == true;
    final area = started
        ? (data['playingArea'] as List? ?? [])
        : _drawFromDeck(deck, 4);

    final player1 = data['player1'];
    final player2 = data['player2'];

    final hands = <String, List<Map<String, dynamic>>>{};
    hands[player1] = p1.toList();
    hands[player2] = p2.toList();

    final playerDecks = data['playersDeck'];
    await doc.update({
      'started': true,
      'playingArea': started ? area : area, // keeps your semantics
      'deck': deck,
      'playersDeck': playerDecks ?? {},
      'hands': hands,
      'playingAreaStacks': data['playingAreaStacks'] ?? [],
      'currentTurnPlayerId': player2,
      'controllerId': player1,
    });
  }

  Future<void> dealSameRound(String gameId) async {
    final doc = _games.doc(gameId);
    final snap = await doc.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final deck = (data['deck'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final p1Deck = _drawFromDeck(deck, 4);
    final p2Deck = _drawFromDeck(deck, 4);

    final p1 = data['player1'];
    final p2 = data['player2'];

    final hands = <String, List<Map<String, dynamic>>>{};
    hands[p1] = p1Deck.toList();
    hands[p2] = p2Deck.toList();

    await doc.update({
      'deck': deck,
      'hands': hands,
      'playingAreaStacks': data['playingAreaStacks'] ?? [],
    });
  }

  Future<void> dealNextRound(
    Transaction tx,
    DocumentReference doc,
    String playerId,
  ) async {
    final s = await tx.get(doc);
    if (!s.exists) return;
    final data = s.data() as Map<String, dynamic>;

    if (data['roundStatus'] != 'completed') return;
    if (data['controllerId'] != playerId) return;

    final p1 = data['player1'] as String;
    final p2 = data['player2'] as String;

    final ready = Map<String, dynamic>.from(data['roundReady'] ?? {});
    final bothReady = (ready[p1] == true) && (ready[p2] == true);
    if (!bothReady) return;

    final newDeck = _createDeck();

    final p1Hand = _drawFromDeck(newDeck, 4);
    final p2Hand = _drawFromDeck(newDeck, 4);
    final playingArea = _drawFromDeck(newDeck, 4);
    final hands = {p1: p1Hand, p2: p2Hand};

    // final nextController = _handleController(data);

    tx.update(doc, {
      'deck': newDeck,
      'hands': hands,
      'playersDeck': {},
      'playingArea': playingArea,
      'playingAreaStacks': [],
      // 'currentTurnPlayerId': nextController == p1 ? p2 : p1,
      // 'controllerId': nextController,
      'roundStatus': 'playing',
      'roundReady': {p1: false, p2: false},
      'roundIndex': (data['roundIndex'] ?? 1) + 1,
    });
  }

  Future<void> setRoundReady(
    Transaction tx,
    DocumentReference doc,
    String playerId,
  ) async {
    final s = await tx.get(doc);
    if (!s.exists) return;
    final data = s.data() as Map<String, dynamic>;
    if (data['roundStatus'] != 'completed') return;
    final ready = Map<String, dynamic>.from(data['roundReady'] ?? {});
    ready[playerId] = true;
    tx.update(doc, {'roundReady': ready});
  }

  ///GAME ACTIONS TRANSACTIONS START
  ///
  Future<void> playCard(
    Transaction tx,
    DocumentReference<Object?> doc,
    PlayingCardModel card,
    String playerId,
  ) async {
    await _runAction(
      tx: tx,
      doc: doc,
      playerId: playerId,
      mutator: (ctx) async {
        final handsRaw = ctx.handsRaw();
        final hand = _handOf(handsRaw, playerId);

        final removed = _removeCardMapOnce(hand, card);
        if (!removed) return _TxResult(update: const {}, skipPost: true);

        _setHand(handsRaw, playerId, hand);

        final playing = ctx.playingArea();
        playing.add(card.toMap());

        final next = _handleTurn(ctx.data, playerId);

        return _TxResult(
          update: {'hands': handsRaw, 'playingArea': playing},
          nextTurnPlayerId: next,
        );
      },
    );
  }

  Future<void> takeCard(
    Transaction tx,
    DocumentReference<Object?> doc,
    PlayingCardModel card,
    PlayingCardModel takingCard,
    String playerId,
  ) async {
    await _runAction(
      tx: tx,
      doc: doc,
      playerId: playerId,
      mutator: (ctx) async {
        final handsRaw = ctx.handsRaw();
        final hand = _handOf(handsRaw, playerId);

        if (!_removeCardMapOnce(hand, card)) {
          return _TxResult(update: const {}, skipPost: true);
        }
        _setHand(handsRaw, playerId, hand);

        final playing = ctx.playingArea();
        _removeCardMapOnce(
          playing,
          takingCard,
        ); // you weren’t returning if missing

        final decksRaw = ctx.playersDeckRaw();
        final deck = _deckOf(decksRaw, playerId);
        deck.add(card.toMap());
        deck.add(takingCard.toMap());
        decksRaw[playerId] = deck;

        final next = _handleTurn(ctx.data, playerId);

        return _TxResult(
          update: {
            'hands': handsRaw,
            'playingArea': playing,
            'playersDeck': decksRaw,
            'lastTookCardId': playerId,
          },
          nextTurnPlayerId: next,
        );
      },
    );
  }

  Future<void> takeStack(
    Transaction tx,
    DocumentReference<Object?> doc,
    PlayingAreaStackModel stack,
    PlayingCardModel card,
    String playerId,
  ) async {
    await _runAction(
      tx: tx,
      doc: doc,
      playerId: playerId,
      mutator: (ctx) async {
        final handsRaw = ctx.handsRaw();
        final hand = _handOf(handsRaw, playerId);

        if (!_removeCardMapOnce(hand, card)) {
          return _TxResult(update: const {}, skipPost: true);
        }
        _setHand(handsRaw, playerId, hand);

        final stacks = ctx.playingAreaStacks();
        stacks.removeWhere((m) => m['id'] == stack.id);

        final decksRaw = ctx.playersDeckRaw();
        var deck = _deckOf(decksRaw, playerId);
        deck.add(card.toMap());
        final stackCards = stack.cards.map((c) => c.toMap()).toList();
        deck = [deck, stackCards].expand((e) => e).toList();
        decksRaw[playerId] = deck;

        final next = _handleTurn(ctx.data, playerId);

        return _TxResult(
          update: {
            'hands': handsRaw,
            'playingAreaStacks': stacks,
            'playersDeck': decksRaw,
            'lastTookCardId': playerId,
          },
          nextTurnPlayerId: next,
        );
      },
    );
  }

  Future<void> stackCards(
    Transaction tx,
    DocumentReference<Object?> doc,
    String playerId,
    PlayingCardModel? playerCard,
    List<String?> cardStackId,
    PlayingAreaStackModel cardStack,
  ) => _upsertStack(
    tx: tx,
    doc: doc,
    playerId: playerId,
    cardStackId: cardStackId,
    playerCard: playerCard,
    cardStack: cardStack,
  );

  Future<void> pairStacks(
    Transaction tx,
    DocumentReference<Object?> doc,
    String playerId,
    List<String?> cardStackId,
    PlayingCardModel? playerCard,
    PlayingAreaStackModel cardStack,
  ) => _upsertStack(
    tx: tx,
    doc: doc,
    playerId: playerId,
    cardStackId: cardStackId,
    playerCard: playerCard,
    cardStack: cardStack,
  );

  Future<void> stackAndPairStacks(
    Transaction tx,
    DocumentReference<Object?> doc,
    String playerId,
    List<String?> cardStackId,
    PlayingCardModel? playerCard,
    PlayingAreaStackModel cardStack,
  ) => _upsertStack(
    tx: tx,
    doc: doc,
    playerId: playerId,
    cardStackId: cardStackId,
    playerCard: playerCard,
    cardStack: cardStack,
  );

  //STACK HANDLER HELPER
  Future<void> _upsertStack({
    required Transaction tx,
    required DocumentReference<Object?> doc,
    required String playerId,
    required List<String?> cardStackId,
    required PlayingCardModel? playerCard,
    required PlayingAreaStackModel cardStack,
  }) async {
    await _runAction(
      tx: tx,
      doc: doc,
      playerId: playerId,
      mutator: (ctx) async {
        final playing = ctx.playingArea();

        // remove all cards that are in cardStack.cards from playingArea (same as you do)
        for (final c in cardStack.cards) {
          _removeCardMapOnce(playing, c);
        }

        final handsRaw = ctx.handsRaw();
        final hand = _handOf(handsRaw, playerId);

        if (playerCard != null) {
          cardStack.cards.add(
            playerCard,
          ); // same behavior (mutates passed object)
          _removeCardMapOnce(hand, playerCard); // you didn't return if missing
        }
        _setHand(handsRaw, playerId, hand);

        final stacks = ctx.playingAreaStacks();
        stacks.removeWhere((e) => cardStackId.contains(e['id']));
        stacks.add(cardStack.toMap());

        final next = (playerCard == null)
            ? playerId
            : _handleTurn(ctx.data, playerId);

        return _TxResult(
          update: {
            'hands': handsRaw,
            'playingArea': playing,
            'playingAreaStacks': stacks,
          },
          nextTurnPlayerId: next,
        );
      },
    );
  }

  ///
  ///GAME ACTION TRANSATIONS END

  ///TRANSACTION WRAPPER
  ///
  Future<void> _runAction({
    required Transaction tx,
    required DocumentReference<Object?> doc,
    required String playerId,
    required TxMutator mutator,
  }) async {
    final s = await tx.get(doc);
    if (!s.exists) return;
    developer.log("HANDLER docPath=${doc.path}");
    final data = (s.data() as Map<String, dynamic>);
    final cur = data['currentTurnPlayerId'];
    if (cur != playerId) return;
    developer.log("PlayerId: $playerId");

    final ctx = _TxCtx(tx: tx, doc: doc, data: data, playerId: playerId);
    developer.log("ctx run");

    final result = await mutator(ctx);
    developer.log("skpPost =${result.skipPost}");

    if (result.skipPost) {
      tx.update(doc, result.update);
      return;
    }

    // Post-processing stays exactly like you do today:
    // - next turn (if provided)
    // - controller (based on roundEnded)
    // - scores (based on roundEnded)
    final patch = Map<String, dynamic>.from(result.update);

    if (result.nextTurnPlayerId != null) {
      patch['currentTurnPlayerId'] = result.nextTurnPlayerId;
    }
    var nextData = _applyPatchToData(data, patch);
    final roundComplete = _roundEnded(nextData);

    if (roundComplete) {
      final settlementPatch = _settleEndOfRoundIfNeeded(
        dataAfterMove: nextData,
        fallbackPlayerId: playerId,
      );

      if (settlementPatch.isNotEmpty) {
        patch.addAll(settlementPatch);
        nextData = _applyPatchToData(nextData, settlementPatch);
      }

      final controller = _handleController(nextData);
      _handleScores(nextData); //hanldes inner internally..
      final winner = nextData['winnerId'] != null;

      final roundScores = Map<String, dynamic>.from(
        nextData['roundScores'] ?? {},
      );
      final p1 = (nextData['player1'] as String?) ?? '';
      final p2 = (nextData['player2'] as String?) ?? '';

      patch['controllerId'] = controller;
      patch['currentTurnPlayerId'] = controller == p1 ? p2 : p1;
      patch['roundStatus'] = 'completed';
      patch['roundScores'] = roundScores;
      patch['scores'] = nextData['scores'];
      patch['roundReady'] = {
        if (p1.isNotEmpty) p1: false,
        if (p2.isNotEmpty) p2: false,
      };
      patch['winnerId'] = nextData['winnerId'];
      patch['started'] = winner ? false : true;
    }
    tx.update(doc, patch);
    developer.log("round ended =$roundComplete");
  }

  ///
  ///END TRASNSACTION WRAPPER

  ///HELPERS
  ///

  List<Map<String, dynamic>> _createDeck() {
    final deck = Deck.standard();
    final shuffled = Deck.shuffle(deck);
    return shuffled.map((c) => c.toMap()).toList();
  }

  bool _removeCardMapOnce(
    List<Map<String, dynamic>> list,
    PlayingCardModel card,
  ) {
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      if (m['suit'] == card.suit && m['rank'] == card.rank) {
        list.removeAt(i);
        return true;
      }
    }
    return false;
  }

  List<Map<String, dynamic>> _handOf(
    Map<String, dynamic> handsRaw,
    String playerId,
  ) {
    return (handsRaw[playerId] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _setHand(
    Map<String, dynamic> handsRaw,
    String playerId,
    List<Map<String, dynamic>> hand,
  ) {
    handsRaw[playerId] = hand;
    return handsRaw;
  }

  List<Map<String, dynamic>> _deckOf(
    Map<String, dynamic> decksRaw,
    String playerId,
  ) {
    return (decksRaw[playerId] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> _drawFromDeck(
    List<Map<String, dynamic>> deck,
    int count,
  ) {
    final take = deck.take(count).toList();
    deck.removeRange(0, count);
    return take;
  }

  String _handleTurn(Map<String, dynamic> data, String currPlayerId) {
    final player1 = data['player1'];
    final player2 = data['player2'];
    String next;
    if (player1 == currPlayerId) {
      next = player2;
    } else {
      next = player1;
    }
    return next;
  }

  String _handleController(Map<String, dynamic> data) {
    if (!_roundEnded(data)) return data['controllerId'];
    final player1 = data['player1'];
    final player2 = data['player2'];
    final currController = data['controllerId'];
    String next;
    if (player1 == currController) {
      next = player2;
    } else {
      next = player1;
    }
    return next;
  }

  bool _roundEnded(Map<String, dynamic> data) {
    String p1 = data['player1'];
    String p2 = data['player2'];
    final handsRaw = Map<String, dynamic>.from(data['hands'] ?? {});

    final player1Hand = (handsRaw[p1] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final player2Hand = (handsRaw[p2] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final deck = (data['deck'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return (player1Hand.isEmpty && player2Hand.isEmpty && deck.isEmpty);
  }

  void _handleScores(Map<String, dynamic> data) {
    final p1 = data['player1'] as String;
    final p2 = data['player2'] as String;

    final playersDeck = Map<String, dynamic>.from(data['playersDeck'] ?? {});
    final p1DeckMap = (playersDeck[p1] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final p2DeckMap = (playersDeck[p2] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final p1Deck = p1DeckMap.map(PlayingCardModel.fromMap).toList();
    final p2Deck = p2DeckMap.map(PlayingCardModel.fromMap).toList();

    final roundScores = Map<String, dynamic>.from(data['roundScores'] ?? {});
    roundScores[p1] = _createScoreMap(p1Deck);
    roundScores[p2] = _createScoreMap(p2Deck);

    final totalScores = Map<String, dynamic>.from(data['scores'] ?? {});
    //handle wiiner before adding scores from new round
    final winner = _handleWinner(totalScores, roundScores, p1, p2);

    totalScores[p1] = (totalScores[p1] == null)
        ? roundScores[p1]['total']
        : totalScores[p1] += roundScores[p1]['total'];

    totalScores[p2] = (totalScores[p2] == null)
        ? roundScores[p2]['total']
        : totalScores[p2] += roundScores[p2]['total'];

    developer.log(
      "winner: $winner roundScores ${roundScores[p1]} ${roundScores[p2]}\nTotalScores: ${totalScores[p1]}, ${totalScores[p2]}",
    );
    data['roundScores'] = roundScores;
    data['scores'] = totalScores;
    data['winnerId'] = winner;
  }

  Map<String, dynamic> _createScoreMap(List<PlayingCardModel> playerDeck) {
    final scoresMap = <String, dynamic>{
      'A': 0,
      '2♠': 0,
      '10♦': 0,
      'pi': 0,
      'carta': 0,
      'total': 0,
    };

    var totalScore = 0;

    if (playerDeck.length > 26) {
      totalScore += 3;
      scoresMap['carta'] = 3;
    }

    for (final card in playerDeck) {
      if (card.rank == 'A') {
        totalScore += 1;
        scoresMap['A'] = (scoresMap['A'] as int) + 1;
      }
      if (card.rank == '2' && card.suit == '♠') {
        totalScore += 1;
        scoresMap['2♠'] = (scoresMap['2♠'] as int) + 1;
      }
      if (card.rank == '10' && card.suit == '♦') {
        totalScore += 2;
        // you had "+= 2" before; keeping that exact behavior:
        scoresMap['10♦'] = (scoresMap['10♦'] as int) + 2;
      }
    }

    final spadesCount = playerDeck.where((c) => c.suit == '♠').length;
    if (spadesCount > 6) {
      totalScore += 1;
      scoresMap['pi'] = (scoresMap['pi'] as int) + 1;
    }

    scoresMap['total'] = totalScore;
    return scoresMap;
  }

  Map<String, dynamic> _applyPatchToData(
    Map<String, dynamic> data,
    Map<String, dynamic> patch,
  ) {
    final next = Map<String, dynamic>.from(data);
    patch.forEach((k, v) {
      next[k] = v;
    });
    return next;
  }

  Map<String, dynamic> _settleEndOfRoundIfNeeded({
    required Map<String, dynamic> dataAfterMove,
    required String
    fallbackPlayerId, // usually the player who made the last move
  }) {
    // Only run on round end (your definition)
    if (!_roundEnded(dataAfterMove)) return const {};

    final playingArea = (dataAfterMove['playingArea'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final stacks = (dataAfterMove['playingAreaStacks'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // Nothing to sweep
    if (playingArea.isEmpty && stacks.isEmpty) return const {};

    // Who gets the leftovers?
    final lastTaker = (dataAfterMove['lastTookCardId'] as String?)?.trim();
    final receiver = (lastTaker != null && lastTaker.isNotEmpty)
        ? lastTaker
        : fallbackPlayerId;

    // Collect all cards from stacks
    final stackCards = <Map<String, dynamic>>[];
    for (final s in stacks) {
      final cards = (s['cards'] as List<dynamic>? ?? []);
      for (final c in cards) {
        stackCards.add(Map<String, dynamic>.from(c as Map));
      }
    }

    final allLeftovers = <Map<String, dynamic>>[...playingArea, ...stackCards];

    // Append to receiver's playersDeck
    final playersDeckRaw = Map<String, dynamic>.from(
      dataAfterMove['playersDeck'] ?? {},
    );
    final receiverDeck = (playersDeckRaw[receiver] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    receiverDeck.addAll(allLeftovers);
    playersDeckRaw[receiver] = receiverDeck;

    return {
      'playersDeck': playersDeckRaw,
      'playingArea': <Map<String, dynamic>>[],
      'playingAreaStacks': <Map<String, dynamic>>[],
      // Optional: could also store who received the sweep:
      // 'lastRoundSweepWinner': receiver,
    };
  }

  String? _handleWinner(
    Map<String, dynamic> prevScore,
    Map<String, dynamic> roundScore,
    String p1,
    String p2,
  ) {
    //compute highest prev score first:
    developer.log(
      "_handle wiinwe with data: prev:::$prevScore, round:::$roundScore, $p1, $p2",
    );
        int score1 = prevScore[p1] ?? 0;
        int score2 = prevScore[p2] ?? 0;

    String highScoreId = (score1 >= score2) ? p1 : p2;
    String lowScoreId = (highScoreId == p1) ? p2 : p1;
    if (_handleWinningConditions(prevScore, roundScore, highScoreId)) {
      return highScoreId;
    }
    if (_handleWinningConditions(prevScore, roundScore, lowScoreId)) {
      return lowScoreId;
    }
    return null;
  }

  bool _handleWinningConditions(
    Map<String, dynamic> prevScore,
    Map<String, dynamic> roundScore,
    String player,
  ) {
    //if score ==20 needs pi
    int score = prevScore[player] ?? 0;
    if (score == 20) {
      if (roundScore[player]['pi'] == 0) {
        roundScore[player]['A'] = 0;
        roundScore[player]['10♦'] = 0;
        roundScore[player]['2♠'] = 0;
        roundScore[player]['total'] = 0;
        return false;
      }
    }
    //if score ==19-18 needs carta...
    if (score == 18 || score == 19) {
      if (roundScore[player]['carta'] == 0) {
        roundScore[player]['A'] = 0;
        roundScore[player]['10♦'] = 0;
        roundScore[player]['2♠'] = 0;
        roundScore[player]['total'] = roundScore[player]['pi'];
        return false;
      }
      return true;
    }
    //if score == 17 needs carta and pi
    if (score == 17) {
      if (roundScore[player]['carta'] == 0 || roundScore[player]['pi']) {
        roundScore[player]['A'] = 0;
        roundScore[player]['10♦'] = 0;
        roundScore[player]['2♠'] = 0;
        roundScore[player]['total'] = roundScore[player]['pi'] + roundScore[player]['carta'];
        return false;
      }
      return true;
    }
    developer.log("prev:::$score, round:::${roundScore[player]['total']},");
    return (score + roundScore[player]['total']) >= 21;
  }
}

///
///END HELPERS

///TXMUTATOR CLASS
/// handles the transactions wrapped in the _run action method
typedef TxMutator = Future<_TxResult> Function(_TxCtx ctx);

class _TxCtx {
  _TxCtx({
    required this.tx,
    required this.doc,
    required this.data,
    required this.playerId,
  });

  final Transaction tx;
  final DocumentReference<Object?> doc;
  final Map<String, dynamic> data;
  final String playerId;

  Map<String, dynamic> handsRaw() =>
      Map<String, dynamic>.from(data['hands'] ?? {});
  Map<String, dynamic> playersDeckRaw() =>
      Map<String, dynamic>.from(data['playersDeck'] ?? {});

  List<Map<String, dynamic>> playingArea() =>
      (data['playingArea'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  List<Map<String, dynamic>> playingAreaStacks() =>
      (data['playingAreaStacks'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
}

class _TxResult {
  _TxResult({
    required this.update,
    this.nextTurnPlayerId,
    this.skipPost = false,
  });

  /// Fields to update on doc within tx.update
  final Map<String, dynamic> update;

  /// If null, wrapper won’t change currentTurnPlayerId.
  final String? nextTurnPlayerId;

  /// If true, wrapper won’t do controller/scores/round-end checks.
  final bool skipPost;
}
