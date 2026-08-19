import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/daily_challenge.dart';
import 'package:dominican_casino/models/theme_pack.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/currency_burst.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:dominican_casino/ui/app_shell/store/store_bundle_card.dart';
import 'package:dominican_casino/ui/app_shell/store/store_catalog.dart';
import 'package:dominican_casino/ui/app_shell/store/store_theme_card.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
import 'package:dominican_casino/ui/widgets/wallet_dialogs.dart';
import 'package:dominican_casino/view_models/app_theme_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  static const _cardAspect = 2.5 / 3.5;
  static const _gridGap = 10.0;

  @override
  State<StoreScreen> createState() => StoreScreenState();
}

class StoreScreenState extends State<StoreScreen> {
  final _scrollController = ScrollController();

  void scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, shellTopBarHeight(context) + 8, 16, 110),
      children: [
        Text(l10n.store, style: theme.title.copyWith(fontSize: 32)),
        const SizedBox(height: 8),
        Text(l10n.noRealMoney, style: theme.body),
        const SizedBox(height: 28),
        const _DailySection(),
        Text(l10n.buyEnergyWithCoins, style: theme.title.copyWith(fontSize: 22)),
        const SizedBox(height: 12),
        _BundleGrid(
          bundles: energyBundles,
          onBundleTap: (bundle, origin) => _buyEnergy(context, bundle, origin),
        ),
        const _ThemePackSection(),
      ],
    );
  }

  Future<void> _buyEnergy(
    BuildContext context,
    StoreBundle bundle,
    Offset? origin,
  ) async {
    final cost = bundle.coinCost;
    if (cost == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmStorePurchase(
      context,
      body: l10n.confirmBuyEnergy(bundle.amount, cost),
    );
    if (!confirmed || !context.mounted) return;

    final repo = context.read<AppRepo>();
    if (repo.wallet.coins < cost) {
      await showInsufficientFundsDialog(context, energy: false);
      return;
    }
    final ok = await repo.buyEnergyWithCoins(
      energy: bundle.amount,
      coinCost: cost,
    );
    if (!ok && context.mounted) {
      await showInsufficientFundsDialog(context, energy: false);
      return;
    }
    if (!context.mounted) return;
    final to = CurrencyBar.centerOf(CurrencyBar.energyChipKey);
    if (origin != null && to != null) {
      await CurrencyBurst.play(
        context: context,
        from: origin,
        to: to,
        icon: CupertinoIcons.bolt_fill,
        color: AppStyle.theme.warning,
        count: bundle.amount.clamp(5, 10),
      );
    }
  }
}

class _DailySection extends StatelessWidget {
  const _DailySection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dailyReward, style: theme.title.copyWith(fontSize: 22)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 3;
            final gap = StoreScreen._gridGap;
            final cardWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            final cardHeight = cardWidth / StoreScreen._cardAspect;
            final cards = <Widget>[
              const _DailyLoginCard(),
              for (final def in dailyChallenges) _DailyChallengeCard(def: def),
            ];
            return SizedBox(
              height: cardHeight,
              child: Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: cards[i],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          Text(
            l10n.debugResetDailyReward,
            style: theme.mutedText.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            color: theme.textPrimary.withValues(alpha: .14),
            onPressed: SoundService.wrapTap(() {
              context.read<AppRepo>().testEnergyFullNotification();
            }),
            child: Text(
              l10n.debugTestEnergyPush,
              style: theme.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 28),
      ],
    );
  }
}

class _DailyLoginCard extends StatelessWidget {
  const _DailyLoginCard();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepo>();
    final l10n = AppLocalizations.of(context);
    final remaining = repo.dailyRewardCooldownRemaining;
    final unavailable = remaining != null;
    final overlayLabel = !unavailable
        ? null
        : remaining.inHours >= 1
            ? l10n.comeBackInHours(remaining.inHours)
            : l10n.comeBackInMinutes(
                remaining.inMinutes.clamp(1, 59).toInt(),
              );

    return StoreBundleCard(
      bundle: dailyRewardBundle(
        l10n.free,
        caption: l10n.dailyLoginCaption,
      ),
      overlayLabel: overlayLabel,
      onLongPress: kDebugMode && unavailable
          ? () => repo.debugRewindDailyClaim()
          : null,
      onTap: unavailable
          ? null
          : (origin) => _claimDailyReward(context, origin),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.def});

  final DailyChallengeDef def;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepo>();
    final l10n = AppLocalizations.of(context);
    final progress = repo.dailyChallengeProgress(def.id);
    final claimed = repo.isDailyChallengeClaimed(def.id);
    final complete = progress >= def.goal;
    final caption = switch (def.id) {
      DailyChallengeId.tydRounds => l10n.dailyChallengeTydCaption,
      DailyChallengeId.casinoClassic => l10n.dailyChallengeCasinoCaption,
    };
    final priceLabel = complete
        ? '${progress.clamp(0, def.goal)}/${def.goal}'
        : '$progress/${def.goal}';

    // Challenges reset on a local calendar day boundary (not the rolling
    // daily-login 23h cooldown), so the "come back" text counts down to
    // the next midnight.
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
    final untilReset = nextMidnight.difference(now);
    final claimedOverlayLabel = untilReset.inHours >= 1
        ? l10n.comeBackInHours(untilReset.inHours)
        : l10n.comeBackInMinutes(untilReset.inMinutes.clamp(1, 59).toInt());

    return StoreBundleCard(
      bundle: dailyChallengeBundle(
        def: def,
        priceLabel: priceLabel,
        caption: caption,
      ),
      overlayLabel: claimed
          ? claimedOverlayLabel
          : (complete ? null : '$progress/${def.goal}'),
      onLongPress: kDebugMode
          ? () => repo.debugTweakDailyChallenge(def.id)
          : null,
      onTap: claimed || !complete
          ? null
          : (origin) => _claimDailyChallenge(context, def, origin),
    );
  }
}

Future<void> _claimDailyChallenge(
  BuildContext context,
  DailyChallengeDef def,
  Offset? origin,
) async {
  var repo = context.read<AppRepo>();
  if (!repo.isGoogleLinked) {
    final linked = await _ensureGoogleForDailyReward(context);
    if (!linked || !context.mounted) return;
    repo = context.read<AppRepo>();
  }

  final result = await repo.claimDailyChallenge(def.id);
  if (result != DailyChallengeClaimResult.claimed || !context.mounted) return;

  final energy = def.rewardKind == DailyChallengeRewardKind.energy;
  final to = CurrencyBar.centerOf(
    energy ? CurrencyBar.energyChipKey : CurrencyBar.coinsChipKey,
  );
  if (origin != null && to != null) {
    await CurrencyBurst.play(
      context: context,
      from: origin,
      to: to,
      icon: energy ? CupertinoIcons.bolt_fill : coinIcon,
      color: energy ? AppStyle.theme.warning : AppStyle.theme.turnHighlight,
      count: def.reward.clamp(5, 10),
    );
  }
}

Future<void> _claimDailyReward(BuildContext context, Offset? origin) async {
  var repo = context.read<AppRepo>();
  if (!repo.isGoogleLinked) {
    final linked = await _ensureGoogleForDailyReward(context);
    if (!linked || !context.mounted) return;
    repo = context.read<AppRepo>();
  }

  final result = await repo.claimDailyReward();
  if (result != DailyRewardClaimResult.claimed || !context.mounted) return;

  final to = CurrencyBar.centerOf(CurrencyBar.coinsChipKey);
  if (origin != null && to != null) {
    await CurrencyBurst.play(
      context: context,
      from: origin,
      to: to,
      icon: coinIcon,
      color: AppStyle.theme.turnHighlight,
      count: 8,
    );
  }
}

Future<bool> _ensureGoogleForDailyReward(BuildContext context) async {
  final repo = context.read<AppRepo>();
  if (repo.isGoogleLinked) return true;
  final l10n = AppLocalizations.of(context);
  final connect = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l10n.googleRequiredForDailyTitle),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '${l10n.googleRequiredForDailyBody}\n\n${l10n.connectGoogleWarning}',
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
          child: Text(l10n.connectGoogle),
        ),
      ],
    ),
  );
  if (connect != true || !context.mounted) return false;

  final result = await repo.linkGoogleAccount();
  if (!context.mounted) return false;
  if (result.status == GoogleAuthStatus.canceled) return false;
  if (result.status == GoogleAuthStatus.failed) {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.google),
        content: Text(l10n.googleSignInError(result.errorCode)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx)),
            child: Text(l10n.back),
          ),
        ],
      ),
    );
    return false;
  }
  return repo.isGoogleLinked;
}

class _BundleGrid extends StatelessWidget {
  const _BundleGrid({required this.bundles, this.onBundleTap});

  final List<StoreBundle> bundles;
  final void Function(StoreBundle bundle, Offset? origin)? onBundleTap;

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
              return StoreBundleCard(
                bundle: bundles[index],
                onTap: onBundleTap == null
                    ? null
                    : (origin) => onBundleTap!(bundles[index], origin),
              );
            },
          ),
        );
      },
    );
  }
}

class _ThemePackSection extends StatelessWidget {
  const _ThemePackSection();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepo>();
    final packs = coinPacksForSale(repo.ownedPacks);
    if (packs.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Text(l10n.themes, style: theme.title.copyWith(fontSize: 22)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 3;
            final gap = StoreScreen._gridGap;
            final cardWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            final cardHeight = cardWidth / StoreScreen._cardAspect;
            final rows = (packs.length / columns).ceil();
            final gridHeight = rows * cardHeight + (rows - 1) * gap;

            return SizedBox(
              height: gridHeight,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: packs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                  childAspectRatio: StoreScreen._cardAspect,
                ),
                itemBuilder: (context, index) {
                  final pack = packs[index];
                  return StoreThemeCard(
                    pack: pack,
                    onTap: () => _buyPack(context, pack),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _buyPack(BuildContext context, ThemePack pack) async {
    final cost = pack.coinCost ?? 0;
    if (cost <= 0) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmStorePurchase(
      context,
      body: l10n.confirmBuyPack(themeLabel(pack.id), cost),
    );
    if (!confirmed || !context.mounted) return;
    final repo = context.read<AppRepo>();
    if (repo.wallet.coins < cost) {
      await showInsufficientFundsDialog(context, energy: false);
      return;
    }
    final ok = await context.read<AppThemeViewModel>().buyPack(pack.id);
    if (!ok && context.mounted) {
      await showInsufficientFundsDialog(context, energy: false);
    }
  }
}
