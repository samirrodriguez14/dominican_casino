class Wallet {
  const Wallet({this.coins = 100, this.energy = 5});

  final int coins;
  final int energy;

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      coins: (json['coins'] as num?)?.toInt() ?? 100,
      energy: (json['energy'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'energy': energy,
  };

  Wallet copyWith({int? coins, int? energy}) {
    return Wallet(
      coins: coins ?? this.coins,
      energy: energy ?? this.energy,
    );
  }
}
