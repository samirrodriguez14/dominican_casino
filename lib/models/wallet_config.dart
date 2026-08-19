/// Economy numbers for coins, energy, match stakes, and store packs.
class WalletConfig {
  static const int startingCoins = 500;
  static const int startingEnergy = 50;

  /// Free coins for a Google-linked account once per local calendar day.
  static const int dailyLoginRewardCoins = 50;
  static const int energyCap = 50;
  static const Duration regenInterval = Duration(minutes: 5);

  /// Coins each player stakes to sit at a table (friend or vs Puli).
  static const int entryCost = 100;
  static const int noBetStake = 0;
  static const List<int> entryStakes = [50, 100, 300];

  /// Casino can be played with no bet so coins can still be earned in-game.
  static const List<int> casinoEntryStakes = [noBetStake, 50, 100, 300];

  static List<int> stakesFor({required bool allowNoBet}) =>
      allowNoBet ? casinoEntryStakes : entryStakes;

  static bool isAllowedStake(int entry, {required bool allowNoBet}) =>
      stakesFor(allowNoBet: allowNoBet).contains(entry);

  /// 2-player tables: winner takes the full pot ([entryCost] × seats).
  static const int winPayoutMultiplier = 2;

  /// 3+ player tables: 1st and 2nd split the pot; 3rd and 4th get nothing.
  static const int fieldPayoutMinSeats = 3;
  static const int fieldFirstPercent = 75;
  static const int fieldSecondPercent = 25;

  static int potTotal(int entry, int seats) {
    if (entry <= 0 || seats <= 0) return 0;
    return entry * seats;
  }

  /// Share of the table pot for a 1-based finish place.
  static int potShareForRank(int entry, int seats, int rank) {
    if (rank < 1) return 0;
    final pot = potTotal(entry, seats);
    if (pot <= 0) return 0;
    if (seats < fieldPayoutMinSeats) {
      return rank == 1 ? pot : 0;
    }
    if (rank == 1) return (pot * fieldFirstPercent) ~/ 100;
    if (rank == 2) {
      return pot - ((pot * fieldFirstPercent) ~/ 100);
    }
    return 0;
  }

  static int winPayout(int entry) => potShareForRank(entry, 2, 1);

  /// Per-turn action clock. Shared on the match so every seat sees it.
  static const Duration speedTurnDuration = Duration(seconds: 10);
  static const Duration standardTurnDuration = Duration(seconds: 30);

  /// Energy to start a Tres y Dos (or Robaito) match.
  static const int puliloEnergyCost = 5;

  /// Energy to start a Casino match.
  static const int casinoPuliloEnergyCost = 10;

  static int energyCostFor(String gameMode) {
    return gameMode == 'casino' || gameMode == 'casinoSpeed'
        ? casinoPuliloEnergyCost
        : puliloEnergyCost;
  }

  static int puliloEnergyCostFor(String gameMode) => energyCostFor(gameMode);
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
