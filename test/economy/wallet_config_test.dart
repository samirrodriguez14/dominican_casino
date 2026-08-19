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

