import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/wallet_config.dart';

class Wallet {
  const Wallet({
    this.coins = WalletConfig.startingCoins,
    this.energy = WalletConfig.startingEnergy,
    required this.energyUpdatedAt,
  });

  factory Wallet.starter([DateTime? now]) {
    return Wallet(
      coins: WalletConfig.startingCoins,
      energy: WalletConfig.startingEnergy,
      energyUpdatedAt: now ?? DateTime.now(),
    );
  }

  final int coins;
  final int energy;
  final DateTime energyUpdatedAt;

  bool get isAtOrAboveCap => energy >= WalletConfig.energyCap;

  /// When regen will reach [WalletConfig.energyCap], or null if already full.
  DateTime? get fullAt {
    if (isAtOrAboveCap) return null;
    final room = WalletConfig.energyCap - energy;
    if (room <= 0) return null;
    return energyUpdatedAt.add(WalletConfig.regenInterval * room);
  }

  Duration timeToNextEnergy([DateTime? now]) {
    if (isAtOrAboveCap) return Duration.zero;
    final at = now ?? DateTime.now();
    final next = energyUpdatedAt.add(WalletConfig.regenInterval);
    final remaining = next.difference(at);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Wallet applyRegen([DateTime? now]) {
    if (isAtOrAboveCap) return this;
    final at = now ?? DateTime.now();
    final interval = WalletConfig.regenInterval;
    if (interval <= Duration.zero) return this;
    final gained =
        at.difference(energyUpdatedAt).inMilliseconds ~/ interval.inMilliseconds;
    if (gained <= 0) return this;
    final room = WalletConfig.energyCap - energy;
    final actual = gained < room ? gained : room;
    if (actual <= 0) return this;
    return copyWith(
      energy: energy + actual,
      energyUpdatedAt: energyUpdatedAt.add(interval * actual),
    );
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      coins:
          (json['coins'] as num?)?.toInt() ?? WalletConfig.startingCoins,
      energy:
          (json['energy'] as num?)?.toInt() ?? WalletConfig.startingEnergy,
      energyUpdatedAt: parseWalletTime(json['energyUpdatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'energy': energy,
    'energyUpdatedAt': energyUpdatedAt.millisecondsSinceEpoch,
  };

  Wallet copyWith({
    int? coins,
    int? energy,
    DateTime? energyUpdatedAt,
  }) {
    return Wallet(
      coins: coins ?? this.coins,
      energy: energy ?? this.energy,
      energyUpdatedAt: energyUpdatedAt ?? this.energyUpdatedAt,
    );
  }

  static DateTime parseWalletTime(dynamic raw) {
    return tryParseWalletTime(raw) ?? DateTime.now();
  }

  static DateTime? tryParseWalletTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    if (raw is String) {
      final millis = int.tryParse(raw);
      if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
      return DateTime.tryParse(raw);
    }
    return null;
  }

  static bool hasWalletFields(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data.containsKey('coins') || data.containsKey('energy');
  }
}
