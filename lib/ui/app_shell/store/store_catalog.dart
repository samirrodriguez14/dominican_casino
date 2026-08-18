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
  });

  final StoreBundleKind kind;
  final int amount;
  final String priceLabel;
  final int? coinCost;
  final bool comingSoon;

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

final energyBundles = <StoreBundle>[
  for (final pack in energyForCoinPacks)
    StoreBundle(
      kind: StoreBundleKind.energy,
      amount: pack.energy,
      coinCost: pack.coinCost,
      priceLabel: '${pack.coinCost}',
    ),
];

/// 3×2 packs for coins (IAP — not wired yet).
const coinBundles = <StoreBundle>[
  StoreBundle(
    kind: StoreBundleKind.coins,
    amount: 100,
    priceLabel: '\$0.99',
    comingSoon: true,
  ),
  StoreBundle(
    kind: StoreBundleKind.coins,
    amount: 250,
    priceLabel: '\$1.99',
    comingSoon: true,
  ),
  StoreBundle(
    kind: StoreBundleKind.coins,
    amount: 600,
    priceLabel: '\$3.99',
    comingSoon: true,
  ),
  StoreBundle(
    kind: StoreBundleKind.coins,
    amount: 1500,
    priceLabel: '\$6.99',
    comingSoon: true,
  ),
  StoreBundle(
    kind: StoreBundleKind.coins,
    amount: 4000,
    priceLabel: '\$12.99',
    comingSoon: true,
  ),
  StoreBundle(
    kind: StoreBundleKind.coins,
    amount: 10000,
    priceLabel: '\$19.99',
    comingSoon: true,
  ),
];
