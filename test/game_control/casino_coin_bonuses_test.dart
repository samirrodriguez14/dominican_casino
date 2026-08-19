import 'package:dominican_casino/game_control/casino_coin_bonuses.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/game_state_fixtures.dart';

void main() {
  test('coinsForTakeCards returns 0 below threshold and length above it', () {
    final cards = List.generate(
      CasinoCoinBonuses.takeBonusMinCards,
      (i) => GameStateFixtures.card(id: 'c$i', rank: '5', suit: '♣'),
    );

    expect(
      CasinoCoinBonuses.coinsForTakeCards(cards.sublist(0, 5)),
      0,
    );
    expect(
      CasinoCoinBonuses.coinsForTakeCards(cards),
      CasinoCoinBonuses.takeBonusMinCards,
    );
  });

  test('specialBonus adds correct coins for special ranks/suits', () {
    final tenDiamond = GameStateFixtures.card(
      id: '10d',
      rank: '10',
      suit: '♦',
    );
    final twoSpades = GameStateFixtures.card(
      id: '2s',
      rank: '2',
      suit: '♠',
    );
    final ace = GameStateFixtures.card(
      id: 'a',
      rank: 'A',
      suit: '♥',
    );
    final normal = GameStateFixtures.card(
      id: 'n',
      rank: '7',
      suit: '♣',
    );

    expect(CasinoCoinBonuses.specialBonus(tenDiamond), 2);
    expect(CasinoCoinBonuses.specialBonus(twoSpades), 1);
    expect(CasinoCoinBonuses.specialBonus(ace), 1);
    expect(CasinoCoinBonuses.specialBonus(normal), 0);
  });

  test('specialCoinsForCards sums specialBonus across cards', () {
    final tenDiamond = GameStateFixtures.card(
      id: '10d',
      rank: '10',
      suit: '♦',
    );
    final twoSpades = GameStateFixtures.card(
      id: '2s',
      rank: '2',
      suit: '♠',
    );
    final ace = GameStateFixtures.card(
      id: 'a',
      rank: 'A',
      suit: '♥',
    );

    expect(
      CasinoCoinBonuses.specialCoinsForCards([tenDiamond, twoSpades, ace]),
      2 + 1 + 1,
    );
  });
}

