import 'package:dominican_casino/models/daily_challenge.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:flutter/cupertino.dart';

enum StoreBundleKind { energy, coins }

class StoreBundle {
  const StoreBundle({
    required this.kind,
    required this.amount,
    required this.priceLabel,
    this.coinCost,
    this.comingSoon = false,
    this.caption,
  });

  final StoreBundleKind kind;
  final int amount;
  final String priceLabel;
  final int? coinCost;
  final bool comingSoon;
  final String? caption;

  bool get pricedInCoins => coinCost != null;

  IconData get icon => kind == StoreBundleKind.energy
      ? CupertinoIcons.bolt_fill
      : coinIcon;

  IconData get priceIcon => pricedInCoins ? coinIcon : icon;

  String get amountLabel {
    if (amount >= 1000 && amount % 1000 == 0) {
      return '${amount ~/ 1000}K';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      final trimmed = k.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
      return '${trimmed}K';
    }
    return '$amount';
  }
}

StoreBundle dailyRewardBundle(String freeLabel, {String? caption}) =>
    StoreBundle(
      kind: StoreBundleKind.coins,
      amount: WalletConfig.dailyLoginRewardCoins,
      priceLabel: freeLabel,
      caption: caption,
    );

StoreBundle dailyChallengeBundle({
  required DailyChallengeDef def,
  required String priceLabel,
  String? caption,
}) => StoreBundle(
  kind: def.rewardKind == DailyChallengeRewardKind.energy
      ? StoreBundleKind.energy
      : StoreBundleKind.coins,
  amount: def.reward,
  priceLabel: priceLabel,
  caption: caption,
);

final energyBundles = <StoreBundle>[
  for (final pack in energyForCoinPacks)
    StoreBundle(
      kind: StoreBundleKind.energy,
      amount: pack.energy,
      coinCost: pack.coinCost,
      priceLabel: '${pack.coinCost}',
    ),
];
