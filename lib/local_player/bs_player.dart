import 'dart:math';

import 'package:dominican_casino/game_control/game_engine/bs/bs_state.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:flutter/foundation.dart';

/// BS bot: dumps honest multi-card plays often; Call BS only when useful.
class BsPlayer {
  static final _rng = Random();

  /// Standard deck has 4 of each rank.
  static const cardsPerRank = 4;

  /// Public reveal memory for this process (not persisted).
  /// gameId → holderPid → rank → known count still in that hand.
  static final Map<String, Map<String, Map<String, int>>> _knownRanks = {};

  static String? _lastResolveKey;
  static _OpenClaim? _openClaim;

  static (ClaimPlayAction, CurrentCardSelection) bsBestAction(
    String pid,
    GameState state,
  ) {
    final hand = List<PlayingCardModel>.from(state.hands[pid] ?? const []);
    if (hand.isEmpty) {
      throw StateError('BS bot has empty hand');
    }

    final byRank = <String, List<PlayingCardModel>>{};
    for (final c in hand) {
      byRank.putIfAbsent(c.rank.toUpperCase(), () => []).add(c);
    }
    final groups = byRank.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final largest = groups.first;
    final preferDump = hand.length >= 8 || largest.value.length >= 3;

    List<PlayingCardModel> play;
    String claimRank;

    // Mostly honest multi-card dumps; occasional light bluff with 1–2 cards.
    final bluffChance = preferDump ? 0.12 : 0.22;
    if (_rng.nextDouble() < bluffChance && hand.length >= 2) {
      hand.shuffle(_rng);
      final n = hand.length >= 3 && _rng.nextDouble() < 0.35 ? 2 : 1;
      play = hand.take(n).toList();
      // Claim a rank we do not hold (or hold few of) so the lie is useful.
      final weak = groups.lastWhere(
        (e) => e.value.length <= 1,
        orElse: () => groups.last,
      );
      claimRank = weak.key;
      if (play.every((c) => c.rank.toUpperCase() == claimRank)) {
        claimRank = groups[_rng.nextInt(groups.length)].key;
      }
    } else {
      final pool = List<PlayingCardModel>.from(largest.value);
      pool.shuffle(_rng);
      final maxPlay = pool.length.clamp(1, 4);
      int n;
      if (maxPlay >= 3) {
        n = maxPlay; // dump the set
      } else if (maxPlay == 2) {
        n = preferDump || _rng.nextDouble() < 0.75 ? 2 : 1;
      } else {
        n = 1;
      }
      play = pool.take(n).toList();
      claimRank = largest.key;
    }

    final action = ClaimPlayAction(
      cards: play,
      claimedRank: claimRank,
      performedById: pid,
    );
    final selection = CurrentCardSelection(
      pid: pid,
      selectedCard: null,
      selectedCards: play,
      selectedStacks: const [],
    );
    return (action, selection);
  }

  /// Call BS when the claim is impossible given this bot's hand, else rarely
  /// when the claim is tight relative to remaining unknown cards.
  static CallBluffAction? maybeCallBluff(String pid, GameState state) {
    syncMemory(state);

    final bs = state.bsState;
    if (bs == null || bs.phase != BsPhase.challenge) return null;
    if (pid == bs.lastClaimPid || bs.challengerPid != null) return null;
    final deadline = bs.challengeDeadline;
    if (deadline != null && !deadline.isAfter(DateTime.now().toUtc())) {
      return null;
    }

    final rank = (bs.lastClaimRank ?? '').toUpperCase();
    final claimCount = bs.lastClaimCount;
    final claimer = bs.lastClaimPid;
    if (rank.isEmpty || claimCount <= 0 || claimer == null) return null;

    // We watched them take these cards after a failed Call BS. Re-playing no
    // more than that known count → skip. More than we saw → normal odds.
    if (shouldSkipCallFromMemory(
      gameId: state.id,
      claimerId: claimer,
      rank: rank,
      claimCount: claimCount,
    )) {
      return null;
    }

    final hand = state.hands[pid] ?? const <PlayingCardModel>[];
    final myCount =
        hand.where((c) => c.rank.toUpperCase() == rank).length;
    final seats = state.playersInfo.length;
    final p = callBluffProbability(
      claimCount: claimCount,
      myRankCount: myCount,
      seats: seats,
    );
    if (p <= 0) return null;
    if (p >= 1.0 || _rng.nextDouble() < p) {
      return CallBluffAction(performedById: pid);
    }
    return null;
  }

  /// True when we already know [claimerId] holds at least [claimCount] of [rank].
  static bool shouldSkipCallFromMemory({
    required String gameId,
    required String claimerId,
    required String rank,
    required int claimCount,
  }) {
    if (claimCount <= 0) return false;
    return claimCount <= knownRankCount(gameId, claimerId, rank);
  }

  /// Probability this seat should Call BS.
  ///
  /// - Impossible claim (`claimCount > cards left outside my hand`) → 1.0
  /// - Single-card claims → near-zero (usually skip)
  /// - Tight multi-card claims → modest odds; rises with more seats
  static double callBluffProbability({
    required int claimCount,
    required int myRankCount,
    required int seats,
    int deckPerRank = cardsPerRank,
  }) {
    if (claimCount <= 0) return 0;
    final remaining = (deckPerRank - myRankCount).clamp(0, deckPerRank);
    if (claimCount > remaining) return 1.0; // impossible → always call

    // One card is almost never worth a Call BS.
    if (claimCount == 1) return 0.03;

    // How much of the unknown pool this claim would need.
    final tightness = claimCount / remaining; // in (0, 1]
    final seatBoost = ((seats - 3).clamp(0, 3)) * 0.05;
    var p = 0.04 + tightness * 0.16 + seatBoost;
    if (claimCount >= 3) p += 0.10;
    if (claimCount == remaining) p += 0.08; // they need every unknown copy
    return p.clamp(0.0, 0.45);
  }

  /// How many of [rank] we know [holderId] still holds from public reveals.
  static int knownRankCount(String gameId, String holderId, String rank) {
    return _knownRanks[gameId]?[holderId]?[rank.toUpperCase()] ?? 0;
  }

  /// Keep reveal memory in sync with the live board (in-process only).
  static void syncMemory(GameState state) {
    if (state.gameMode != GameMode.bs) return;
    final bs = state.bsState;
    if (bs == null) return;
    final gameId = state.id;

    if (state.gameStatus != GameStatus.inProgress ||
        state.round.roundStatus != RoundStatus.playing) {
      clearMemory(gameId);
      return;
    }

    // Track the open claim so an accept / timeout can consume known cards.
    if (bs.phase == BsPhase.challenge &&
        bs.lastClaimPid != null &&
        (bs.lastClaimRank ?? '').isNotEmpty &&
        bs.lastClaimCount > 0) {
      _openClaim = _OpenClaim(
        gameId: gameId,
        claimerId: bs.lastClaimPid!,
        rank: bs.lastClaimRank!.toUpperCase(),
        count: bs.lastClaimCount,
        fingerprint: bs.lastPlayedCardIds.join(','),
      );
    }

    // Failed Call BS (honest claim): challenger publicly received those cards.
    if (bs.phase == BsPhase.resolve &&
        bs.wasBluffing == false &&
        bs.challengerPid != null &&
        bs.lastPlayedCardIds.isNotEmpty) {
      final key =
          '$gameId:${bs.challengerPid}:${bs.lastPlayedCardIds.join(",")}';
      if (_lastResolveKey != key) {
        _lastResolveKey = key;
        final cards = _findCards(state, bs.lastPlayedCardIds);
        _addKnownCards(gameId, bs.challengerPid!, cards);
        final claimer = bs.lastClaimPid;
        if (claimer != null && claimer.isNotEmpty) {
          _removeKnownCards(gameId, claimer, cards);
        }
      }
      _openClaim = null;
      return;
    }

    // Successful Call BS (bluff): drop open claim; no new public rank gift.
    if (bs.phase == BsPhase.resolve && bs.wasBluffing == true) {
      _openClaim = null;
      return;
    }

    // Claim accepted / window expired: those cards left the claimer's hand.
    if (bs.phase == BsPhase.turn && _openClaim != null) {
      final open = _openClaim!;
      if (open.gameId == gameId) {
        _addKnown(gameId, open.claimerId, open.rank, -open.count);
      }
      _openClaim = null;
    }
  }

  static void clearMemory([String? gameId]) {
    if (gameId == null) {
      _knownRanks.clear();
    } else {
      _knownRanks.remove(gameId);
    }
    _lastResolveKey = null;
    _openClaim = null;
  }

  /// Test helper: seed known ranks after a failed Call BS.
  @visibleForTesting
  static void debugSetKnown({
    required String gameId,
    required String holderId,
    required String rank,
    required int count,
  }) {
    final byHolder = _knownRanks.putIfAbsent(gameId, () => {});
    final byRank = byHolder.putIfAbsent(holderId, () => {});
    final r = rank.toUpperCase();
    if (count <= 0) {
      byRank.remove(r);
    } else {
      byRank[r] = count;
    }
  }

  static List<PlayingCardModel> _findCards(
    GameState state,
    List<String> ids,
  ) {
    final want = ids.toSet();
    final found = <PlayingCardModel>[];
    void take(Iterable<PlayingCardModel> cards) {
      for (final c in cards) {
        if (want.remove(c.id)) found.add(c);
      }
    }

    for (final e in state.settlementEvents) {
      take([e.card]);
    }
    for (final hand in state.hands.values) {
      take(hand);
    }
    take(state.playingArea);
    return found;
  }

  static void _addKnownCards(
    String gameId,
    String holderId,
    List<PlayingCardModel> cards,
  ) {
    final byRank = <String, int>{};
    for (final c in cards) {
      final r = c.rank.toUpperCase();
      byRank[r] = (byRank[r] ?? 0) + 1;
    }
    for (final e in byRank.entries) {
      _addKnown(gameId, holderId, e.key, e.value);
    }
  }

  static void _removeKnownCards(
    String gameId,
    String holderId,
    List<PlayingCardModel> cards,
  ) {
    final byRank = <String, int>{};
    for (final c in cards) {
      final r = c.rank.toUpperCase();
      byRank[r] = (byRank[r] ?? 0) + 1;
    }
    for (final e in byRank.entries) {
      _addKnown(gameId, holderId, e.key, -e.value);
    }
  }

  static void _addKnown(
    String gameId,
    String holderId,
    String rank,
    int delta,
  ) {
    if (delta == 0) return;
    final byHolder = _knownRanks.putIfAbsent(gameId, () => {});
    final byRank = byHolder.putIfAbsent(holderId, () => {});
    final r = rank.toUpperCase();
    final next = (byRank[r] ?? 0) + delta;
    if (next <= 0) {
      byRank.remove(r);
    } else {
      byRank[r] = next;
    }
  }
}

class _OpenClaim {
  const _OpenClaim({
    required this.gameId,
    required this.claimerId,
    required this.rank,
    required this.count,
    required this.fingerprint,
  });

  final String gameId;
  final String claimerId;
  final String rank;
  final int count;
  final String fingerprint;
}
