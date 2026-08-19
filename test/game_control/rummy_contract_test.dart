import 'dart:math';

import 'package:dominican_casino/game_control/game_engine/rummy/rummy_contract.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_matcher.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_requirement.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:flutter_test/flutter_test.dart';

PlayingCardModel card({
  required String id,
  required String rank,
  required String suit,
}) {
  return PlayingCardModel(
    id: id,
    rank: rank,
    suit: suit,
  );
}

void main() {
  group('Rummy matcher kernel', () {
    test('Run matches Ace-low sequence (A-2-3) same suit', () {
      final requirement = RummyRequirement.run(3);
      final group = [
        card(id: 'a', rank: 'A', suit: '♠'),
        card(id: '2', rank: '2', suit: '♠'),
        card(id: '3', rank: '3', suit: '♠'),
      ];

      expect(requirement.matches(group), isTrue);
    });

    test('Run accepts Ace-high sequence (Q-K-A) same suit', () {
      final requirement = RummyRequirement.run(3);
      final group = [
        card(id: 'q', rank: 'Q', suit: '♣'),
        card(id: 'k', rank: 'K', suit: '♣'),
        card(id: 'a', rank: 'A', suit: '♣'),
      ];

      expect(requirement.matches(group), isTrue);
    });

    test('Run rejects wraparound (K-A-2)', () {
      final requirement = RummyRequirement.run(3);
      final group = [
        card(id: 'k', rank: 'K', suit: '♠'),
        card(id: 'a', rank: 'A', suit: '♠'),
        card(id: '2', rank: '2', suit: '♠'),
      ];

      expect(requirement.matches(group), isFalse);
    });

    test('Color matches all red suits', () {
      final requirement = RummyRequirement.colorOf(3, RummyColor.red);
      final group = [
        card(id: 'h', rank: '7', suit: '♥'),
        card(id: 'd', rank: '9', suit: '♦'),
        card(id: 'h2', rank: 'J', suit: '♥'),
      ];

      expect(requirement.matches(group), isTrue);
    });

    test('Color rejects mixed colors', () {
      final requirement = RummyRequirement.colorOf(3, RummyColor.red);
      final group = [
        card(id: 'h', rank: '7', suit: '♥'),
        card(id: 'd', rank: '9', suit: '♦'),
        card(id: 's', rank: 'J', suit: '♠'),
      ];

      expect(requirement.matches(group), isFalse);
    });

    test('ContractSatisfied is order-insensitive across the two dotted boxes', () {
      final contract = RummyContract(
        requirements: [
          RummyRequirement.run(5),
          RummyRequirement.set(2),
        ],
      );

      final run5 = [
        card(id: '2s', rank: '2', suit: '♠'),
        card(id: '3s', rank: '3', suit: '♠'),
        card(id: '4s', rank: '4', suit: '♠'),
        card(id: '5s', rank: '5', suit: '♠'),
        card(id: '6s', rank: '6', suit: '♠'),
      ];

      final set2 = [
        card(id: '9h', rank: '9', suit: '♥'),
        card(id: '9c', rank: '9', suit: '♣'),
      ];

      final all7 = [...run5, ...set2];

      // Swap: boxA gets the set, boxB gets the run.
      expect(
        RummyMatcher.contractSatisfied(
          contract: contract,
          allCards: all7,
          groupA: set2,
          groupB: run5,
        ),
        isTrue,
      );
    });

    test('ContractSatisfied requires the two boxes to cover all 7 cards', () {
      final contract = RummyContract(
        requirements: [
          RummyRequirement.run(5),
          RummyRequirement.set(2),
        ],
      );

      final run5 = [
        card(id: '2s', rank: '2', suit: '♠'),
        card(id: '3s', rank: '3', suit: '♠'),
        card(id: '4s', rank: '4', suit: '♠'),
        card(id: '5s', rank: '5', suit: '♠'),
        card(id: '6s', rank: '6', suit: '♠'),
      ];

      final set2 = [
        card(id: '9h', rank: '9', suit: '♥'),
        card(id: '9c', rank: '9', suit: '♣'),
      ];

      final leftover = card(id: '7d', rank: '7', suit: '♦');
      final all7 = [...run5, ...set2, leftover];

      expect(
        RummyMatcher.contractSatisfied(
          contract: contract,
          allCards: all7,
          groupA: run5,
          groupB: set2,
        ),
        isFalse,
      );
    });

    test('ContractSatisfied rejects duplicate card ids inside a group', () {
      final contract = RummyContract(
        requirements: [
          RummyRequirement.run(5),
          RummyRequirement.set(2),
        ],
      );

      final run5 = [
        card(id: '2s', rank: '2', suit: '♠'),
        card(id: '3s', rank: '3', suit: '♠'),
        card(id: '4s', rank: '4', suit: '♠'),
        card(id: '5s', rank: '5', suit: '♠'),
        card(id: '2s', rank: '6', suit: '♠'), // duplicate id
      ];

      final set2 = [
        card(id: '9h', rank: '9', suit: '♥'),
        card(id: '9c', rank: '9', suit: '♣'),
      ];

      final all7 = [...run5, ...set2];

      expect(
        RummyMatcher.contractSatisfied(
          contract: contract,
          allCards: all7,
          groupA: run5,
          groupB: set2,
        ),
        isFalse,
      );
    });

    test('RummyContract.pickRandom always returns 2 requirements totaling 7', () {
      final rng = Random(1);
      for (var i = 0; i < 30; i++) {
        final contract = RummyContract.pickRandom(rng: rng);
        expect(contract.requirements, hasLength(2));
        expect(contract.totalCards, equals(7));
      }
    });
  });
}

