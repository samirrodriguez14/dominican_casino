/// Economy numbers for coins, energy, match stakes, and store packs.
class WalletConfig {
  static const int startingCoins = 1000;
  static const int startingEnergy = 100;
  static const int energyCap = 100;
  static const Duration regenInterval = Duration(minutes: 5);

  static const int entryCost = 100;
  static const int winPayoutMultiplier = 2;

  /// Energy to start a Tres y Dos (or Robaito) match vs Puli.
  static const int puliloEnergyCost = 5;

  /// Energy to start a Casino match vs Puli.
  static const int casinoPuliloEnergyCost = 10;

  static int puliloEnergyCostFor(String gameMode) {
    return gameMode == 'casino' ? casinoPuliloEnergyCost : puliloEnergyCost;
  }

  static int winPayout(int entry) => entry * winPayoutMultiplier;
}

class EnergyCoinPack {
  const EnergyCoinPack({required this.energy, required this.coinCost});

  final int energy;
  final int coinCost;
}

/// Energy bought with coins. ~10 coins each, cheaper in bulk.
const energyForCoinPacks = <EnergyCoinPack>[
  EnergyCoinPack(energy: 5, coinCost: 50),
  EnergyCoinPack(energy: 15, coinCost: 140),
  EnergyCoinPack(energy: 40, coinCost: 360),
  EnergyCoinPack(energy: 80, coinCost: 680),
  EnergyCoinPack(energy: 160, coinCost: 1280),
  EnergyCoinPack(energy: 400, coinCost: 2800),
];
