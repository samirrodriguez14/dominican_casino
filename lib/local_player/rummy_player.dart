import 'dart:math' as math;

import 'package:dominican_casino/game_control/game_engine/rummy/rummy_contract.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_matcher.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_requirement.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_state.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/local_player/local_player.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

/// Contract-aware bot for Rummy (Romir).
class RummyPlayer {
  static Future<PossibleSelection> rummyBestAction(
    String pid,
    GameState gameState,
  ) async {
    final hand = gameState.hands[pid] ?? const <PlayingCardModel>[];
    final tableCard = gameState.playingArea.isNotEmpty
        ? gameState.playingArea.last
        : null;
    final deckTop = gameState.deck.isNotEmpty ? gameState.deck.last : null;

    final rummy = gameState.rummyState;
    if (rummy == null) {
      throw StateError('Rummy bot requires gameState.rummyState');
    }
    final contract = rummy.contract;

    if (hand.length == 7) {
      // Must take to 8, then we'll discard on the next bot tick.
      final currentScore = _contractScoreForSeven(contract, hand);

      if (tableCard != null) {
        final afterTake = [...hand, tableCard];
        final tableBest = _bestScoreAfterDiscard(contract, afterTake);
        if (tableBest > currentScore) {
          return PossibleSelection(
            playAction: TakeCardAction(
              performedById: pid,
              usedCard: tableCard,
              targetCard: tableCard,
              fromZone: ZoneType.table,
            ),
            cardSelection: CurrentCardSelection(
              pid: pid,
              selectedCard: null,
              selectedCards: [tableCard],
              selectedStacks: const [],
            ),
            scoreValue: tableBest,
          );
        }
      }

      if (deckTop != null) {
        final afterTake = [...hand, deckTop];
        final best = _bestScoreAfterDiscard(contract, afterTake);
        return PossibleSelection(
          playAction: TakeCardAction(
            performedById: pid,
            usedCard: deckTop,
            targetCard: deckTop,
            fromZone: ZoneType.gameDeck,
          ),
          cardSelection: CurrentCardSelection(
            pid: pid,
            selectedCard: null,
            selectedCards: [deckTop],
            selectedStacks: const [],
          ),
          scoreValue: best,
        );
      }

      // Fallback (should not happen in a proper deal).
      if (tableCard != null) {
        return PossibleSelection(
          playAction: TakeCardAction(
            performedById: pid,
            usedCard: tableCard,
            targetCard: tableCard,
            fromZone: ZoneType.table,
          ),
          cardSelection: CurrentCardSelection(
            pid: pid,
            selectedCard: null,
            selectedCards: [tableCard],
            selectedStacks: const [],
          ),
          scoreValue: currentScore,
        );
      }

      throw StateError('No available take card for $pid');
    }

    if (hand.length == 8) {
      // Must discard to 7. Look for a winning go-out first.
      for (final discard in hand) {
        final remaining = [...hand]..removeWhere((c) => c.id == discard.id);
        final partition = _findWinningPartition(contract, remaining);
        if (partition != null) {
          // Mutate overlay so the engine's win check can use it.
          _applyOverlay(rummy, pid, partition.$1, partition.$2);

          return PossibleSelection(
            playAction: PlayCardAction(
              performedById: pid,
              usedCard: discard,
            ),
            cardSelection: CurrentCardSelection(
              pid: pid,
              selectedCard: discard,
              selectedCards: const [],
              selectedStacks: const [],
            ),
            scoreValue: 1000000,
          );
        }
      }

      // No go-out exists: discard to maximize heuristic.
      var bestDiscard = hand.first;
      var bestScore = -1;
      for (final discard in hand) {
        final remaining = [...hand]..removeWhere((c) => c.id == discard.id);
        final score = _contractScoreForSeven(contract, remaining);
        if (score > bestScore) {
          bestScore = score;
          bestDiscard = discard;
        }
      }

      return PossibleSelection(
        playAction: PlayCardAction(
          performedById: pid,
          usedCard: bestDiscard,
        ),
        cardSelection: CurrentCardSelection(
          pid: pid,
          selectedCard: bestDiscard,
          selectedCards: const [],
          selectedStacks: const [],
        ),
        scoreValue: bestScore,
      );
    }

    // Unexpected hand size.
    throw StateError('Unexpected hand size=${hand.length} for Rummy bot');
  }

  static void _applyOverlay(
    RummyState rummy,
    String pid,
    List<PlayingCardModel> groupA,
    List<PlayingCardModel> groupB,
  ) {
    rummy.boxAByPid.putIfAbsent(pid, () => []);
    rummy.boxBByPid.putIfAbsent(pid, () => []);
    rummy.boxAByPid[pid] = groupA.map((c) => c.id).toList();
    rummy.boxBByPid[pid] = groupB.map((c) => c.id).toList();
  }

  /// Returns a winning (exact contract) partition for [cards], or null.
  ///
  /// Partition is returned as (groupA, groupB).
  static (List<PlayingCardModel>, List<PlayingCardModel>)?
      _findWinningPartition(
    RummyContract contract,
    List<PlayingCardModel> cards,
  ) {
    if (cards.length != contract.totalCards) return null;
    if (contract.requirements.length == 1) {
      final req = contract.requirements.first;
      if (req.matches(cards)) return (cards, const []);
      return null;
    }
    if (contract.requirements.length != 2) return null;

    final r1 = contract.requirements[0];
    final r2 = contract.requirements[1];
    final sizesToTry = <int>{r1.count, r2.count};

    final ids = cards.map((c) => c.id).toList();
    final byId = {for (final c in cards) c.id: c};

    for (final sizeA in sizesToTry) {
      // Enumerate subsets of indices for groupA.
      final idxs = List<int>.generate(cards.length, (i) => i);
      final maxMask = 1 << idxs.length;
      for (var mask = 0; mask < maxMask; mask++) {
        if (_popCount(mask) != sizeA) continue;
        final groupAIds = <String>[];
        final groupBIds = <String>[];
        for (var i = 0; i < idxs.length; i++) {
          final id = byId[ids[idxs[i]]]!.id;
          if (((mask >> i) & 1) == 1) {
            groupAIds.add(id);
          } else {
            groupBIds.add(id);
          }
        }
        final groupA = groupAIds.map((id) => byId[id]!).toList();
        final groupB = groupBIds.map((id) => byId[id]!).toList();
        final ok = RummyMatcher.contractSatisfied(
          contract: contract,
          allCards: cards,
          groupA: groupA,
          groupB: groupB,
        );
        if (ok) return (groupA, groupB);
      }
    }

    return null;
  }

  static int _bestScoreAfterDiscard(RummyContract contract, List<PlayingCardModel> hand8) {
    var best = -1;
    for (final discard in hand8) {
      final remaining = [...hand8]..removeWhere((c) => c.id == discard.id);
      final score = _contractScoreForSeven(contract, remaining);
      best = math.max(best, score);
    }
    return best;
  }

  static int _contractScoreForSeven(
    RummyContract contract,
    List<PlayingCardModel> sevenCards,
  ) {
    if (sevenCards.length != contract.totalCards) return -100000;

    final exact = _findWinningPartition(contract, sevenCards);
    if (exact != null) return 100000; // decisive go-out

    if (contract.requirements.length == 1) {
      return _requirementBestFit(contract.requirements.first, sevenCards);
    }
    if (contract.requirements.length != 2) return 0;

    final r1 = contract.requirements[0];
    final r2 = contract.requirements[1];
    return _requirementBestFit(r1, sevenCards) +
        _requirementBestFit(r2, sevenCards);
  }

  /// Best possible match length toward this requirement.
  static int _requirementBestFit(
    RummyRequirement requirement,
    List<PlayingCardModel> cards,
  ) {
    switch (requirement.kind) {
      case RummyKind.set:
        final counts = <int, int>{};
        for (final c in cards) {
          counts[c.valueLow] = (counts[c.valueLow] ?? 0) + 1;
        }
        final best = counts.values.fold<int>(0, (a, b) => math.max(a, b));
        return math.min(best, requirement.count) * 100;
      case RummyKind.color:
        final expectedRed = requirement.color == RummyColor.red;
        var redCount = 0;
        for (final c in cards) {
          final isRed = c.suit == '♥' || c.suit == '♦';
          if (isRed) redCount++;
        }
        final best = expectedRed ? redCount : cards.length - redCount;
        return math.min(best, requirement.count) * 70;
      case RummyKind.run:
        return _bestRunLen(cards, requirement.count) * 90;
    }
  }

  static int _bestRunLen(List<PlayingCardModel> cards, int maxN) {
    // Run requires same suit and consecutive ranks (Ace low or high, no wrap).
    var best = 0;
    for (final suit in const <String>['♠', '♥', '♦', '♣']) {
      final suited = cards.where((c) => c.suit == suit).toList();
      if (suited.length < 2) continue;

      best = math.max(best, _bestConsecutiveLen(suited, maxN, aceHigh: false));
      best = math.max(best, _bestConsecutiveLen(suited, maxN, aceHigh: true));
    }
    return best;
  }

  static int _bestConsecutiveLen(
    List<PlayingCardModel> suited,
    int maxN, {
    required bool aceHigh,
  }) {
    final values = <int>{};
    for (final c in suited) {
      final r = c.rank.trim().toUpperCase();
      if (r == 'A') values.add(aceHigh ? 14 : 1);
      else if (r == 'J') values.add(11);
      else if (r == 'Q') values.add(12);
      else if (r == 'K') values.add(13);
      else {
        final n = int.tryParse(r);
        if (n != null) values.add(n);
      }
    }
    if (values.length < 2) return 0;
    final sorted = values.toList()..sort();

    var current = 1;
    var best = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) {
        current++;
      } else {
        best = math.max(best, current);
        current = 1;
      }
    }
    best = math.max(best, current);
    return math.min(best, maxN);
  }

  static int _popCount(int x) {
    var c = 0;
    var n = x;
    while (n != 0) {
      c += n & 1;
      n >>= 1;
    }
    return c;
  }
}

