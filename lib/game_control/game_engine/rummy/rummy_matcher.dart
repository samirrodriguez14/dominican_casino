import 'package:dominican_casino/game_control/game_engine/rummy/rummy_contract.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_requirement.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

/// Pure matching logic for Rummy (Romir).
///
/// This module is intentionally UI-agnostic: it only answers whether a
/// given hand can be partitioned into the contract's required groups.
class RummyMatcher {
  static bool contractSatisfied({
    required RummyContract contract,
    required List<PlayingCardModel> allCards,
    required List<PlayingCardModel> groupA,
    required List<PlayingCardModel> groupB,
  }) {
    if (allCards.isEmpty) return false;
    if (allCards.length != contract.totalCards) return false;

    final handIds = allCards.map((c) => c.id).toSet();
    if (handIds.length != allCards.length) return false; // duplicate ids in hand

    // Groups must be disjoint and must cover the full hand for v1.
    final aIds = groupA.map((c) => c.id).toSet();
    final bIds = groupB.map((c) => c.id).toSet();
    if (aIds.length != groupA.length) return false;
    if (bIds.length != groupB.length) return false;

    if (aIds.intersection(bIds).isNotEmpty) return false;

    final unionIds = <String>{}..addAll(aIds)..addAll(bIds);
    if (unionIds.length != allCards.length) return false;
    for (final id in handIds) {
      if (!unionIds.contains(id)) return false;
    }

    if (contract.requirements.length == 1) {
      if (groupB.isNotEmpty) return false;
      return contract.requirements.first.matches(groupA);
    }

    if (contract.requirements.length != 2) {
      // v1 doesn't use >2, but fail closed if contract is extended incorrectly.
      return false;
    }

    final r1 = contract.requirements[0];
    final r2 = contract.requirements[1];

    final aMatchesR1 = r1.matches(groupA);
    final bMatchesR2 = r2.matches(groupB);
    if (aMatchesR1 && bMatchesR2) return true;

    // Order of dotted boxes doesn't matter: boxA can satisfy either requirement.
    return r2.matches(groupA) && r1.matches(groupB);
  }

  static bool matchesRequirement({
    required RummyRequirement requirement,
    required List<PlayingCardModel> cards,
  }) {
    return requirement.matches(cards);
  }
}

