import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:dominican_casino/ui/app_shell/store/store_bundle_card.dart';
import 'package:dominican_casino/ui/app_shell/store/store_catalog.dart';
import 'package:dominican_casino/ui/app_shell/store/store_theme_card.dart';
import 'package:flutter/cupertino.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  static const _cardAspect = 2.5 / 3.5;
  static const _gridGap = 10.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, shellTopBarHeight(context) + 8, 16, 110),
      children: [
        Text(l10n.store, style: theme.title.copyWith(fontSize: 32)),
        const SizedBox(height: 8),
        Text(l10n.noRealMoney, style: theme.body),
        const SizedBox(height: 28),
        Text(l10n.buyEnergy, style: theme.title.copyWith(fontSize: 22)),
        const SizedBox(height: 12),
        _BundleGrid(bundles: energyBundles),
        const SizedBox(height: 28),
        Text(l10n.buyCoins, style: theme.title.copyWith(fontSize: 22)),
        const SizedBox(height: 12),
        _BundleGrid(bundles: coinBundles),
        const SizedBox(height: 28),
        Text(l10n.themes, style: theme.title.copyWith(fontSize: 22)),
        const SizedBox(height: 12),
        const _ThemeStrip(),
      ],
    );
  }
}

class _BundleGrid extends StatelessWidget {
  const _BundleGrid({required this.bundles});

  final List<StoreBundle> bundles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        final gap = StoreScreen._gridGap;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        final cardHeight = cardWidth / StoreScreen._cardAspect;
        final rows = (bundles.length / columns).ceil();
        final gridHeight = rows * cardHeight + (rows - 1) * gap;

        return SizedBox(
          height: gridHeight,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bundles.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              childAspectRatio: StoreScreen._cardAspect,
            ),
            itemBuilder: (context, index) {
              return StoreBundleCard(bundle: bundles[index]);
            },
          ),
        );
      },
    );
  }
}

class _ThemeStrip extends StatelessWidget {
  const _ThemeStrip();

  @override
  Widget build(BuildContext context) {
    final themes = Theme.values.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = (constraints.maxWidth / 3) / StoreScreen._cardAspect;

        return SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: themes.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: StoreScreen._gridGap),
            itemBuilder: (context, index) {
              final themeType = themes[index];
              final locked = !ownedThemes.contains(themeType);
              return SizedBox(
                width: cardHeight * StoreScreen._cardAspect,
                height: cardHeight,
                child: StoreThemeCard(
                  previewTheme: themeFromEnum(themeType),
                  locked: locked,
                  priceLabel: locked ? themePriceLabel(themeType) : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
