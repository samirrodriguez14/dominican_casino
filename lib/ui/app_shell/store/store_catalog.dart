import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

enum StoreBundleKind { energy, coins }

class StoreBundle {
  const StoreBundle({
    required this.kind,
    required this.amount,
    required this.priceLabel,
  });

  final StoreBundleKind kind;
  final int amount;
  final String priceLabel;

  IconData get icon => kind == StoreBundleKind.energy
      ? CupertinoIcons.bolt_fill
      : CupertinoIcons.circle_grid_3x3_fill;

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

/// 3×2 packs for energy.
const energyBundles = <StoreBundle>[
  StoreBundle(kind: StoreBundleKind.energy, amount: 5, priceLabel: '\$0.99'),
  StoreBundle(kind: StoreBundleKind.energy, amount: 15, priceLabel: '\$1.99'),
  StoreBundle(kind: StoreBundleKind.energy, amount: 40, priceLabel: '\$3.99'),
  StoreBundle(kind: StoreBundleKind.energy, amount: 80, priceLabel: '\$6.99'),
  StoreBundle(kind: StoreBundleKind.energy, amount: 160, priceLabel: '\$11.99'),
  StoreBundle(kind: StoreBundleKind.energy, amount: 400, priceLabel: '\$19.99'),
];

/// 3×2 packs for coins.
const coinBundles = <StoreBundle>[
  StoreBundle(kind: StoreBundleKind.coins, amount: 100, priceLabel: '\$0.99'),
  StoreBundle(kind: StoreBundleKind.coins, amount: 250, priceLabel: '\$1.99'),
  StoreBundle(kind: StoreBundleKind.coins, amount: 600, priceLabel: '\$3.99'),
  StoreBundle(kind: StoreBundleKind.coins, amount: 1500, priceLabel: '\$6.99'),
  StoreBundle(kind: StoreBundleKind.coins, amount: 4000, priceLabel: '\$12.99'),
  StoreBundle(
    kind: StoreBundleKind.coins,
    amount: 10000,
    priceLabel: '\$19.99',
  ),
];

String themePriceLabel(Theme themeType) {
  return switch (themeType) {
    Theme.casino || Theme.midnight => '\$2.99',
    Theme.feltWaltnut || Theme.sage => '\$1.99',
  };
}
