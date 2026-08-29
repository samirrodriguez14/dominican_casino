import 'package:dominican_casino/models/wallet_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WalletConfig pot math works for 2-player winner-take-all', () {
    const entry = 100;
    const seats = 2;
    expect(WalletConfig.potTotal(entry, seats), 200);

    expect(WalletConfig.potShareForRank(entry, seats, 1), 200);
    expect(WalletConfig.potShareForRank(entry, seats, 2), 0);
  });

  test('WalletConfig pot math works for 3+ players (75/25 then 0)', () {
    const entry = 100;
    const seats = 3;
    expect(WalletConfig.potTotal(entry, seats), 300);

    expect(WalletConfig.potShareForRank(entry, seats, 1), 225); // floor(300*0.75)
    expect(WalletConfig.potShareForRank(entry, seats, 2), 75);
    expect(WalletConfig.potShareForRank(entry, seats, 3), 0);
  });

  test('WalletConfig pot math works for 5–6 players (70/20/10)', () {
    expect(WalletConfig.potTotal(100, 5), 500);
    expect(WalletConfig.potShareForRank(100, 5, 1), 350);
    expect(WalletConfig.potShareForRank(100, 5, 2), 100);
    expect(WalletConfig.potShareForRank(100, 5, 3), 50);
    expect(WalletConfig.potShareForRank(100, 5, 4), 0);

    expect(WalletConfig.potTotal(100, 6), 600);
    expect(WalletConfig.potShareForRank(100, 6, 1), 420);
    expect(WalletConfig.potShareForRank(100, 6, 2), 120);
    expect(WalletConfig.potShareForRank(100, 6, 3), 60);
    expect(WalletConfig.potShareForRank(100, 6, 4), 0);

    expect(WalletConfig.potTotal(50, 6), 300);
    expect(WalletConfig.potShareForRank(50, 6, 1), 210);
    expect(WalletConfig.potShareForRank(50, 6, 2), 60);
    expect(WalletConfig.potShareForRank(50, 6, 3), 30);
  });

  test('WalletConfig stakesFor uses allowNoBet correctly', () {
    expect(
      WalletConfig.stakesFor(allowNoBet: false),
      equals([50, 100, 300]),
    );
    expect(
      WalletConfig.stakesFor(allowNoBet: true),
      equals([0, 50, 100, 300]),
    );
  });

  test('WalletConfig energy cost matches game mode rules', () {
    expect(WalletConfig.energyCostFor('casino'), WalletConfig.casinoPuliloEnergyCost);
    expect(
      WalletConfig.energyCostFor('casinoSpeed'),
      WalletConfig.casinoPuliloEnergyCost,
    );
    expect(
      WalletConfig.energyCostFor('tresydos'),
      WalletConfig.puliloEnergyCost,
    );
  });
}

