import 'dart:async';

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
import 'package:dominican_casino/ui/widgets/wallet_dialogs.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Side-by-side energy and coins cards on the profile face.
class ProfileWalletCards extends StatefulWidget {
  const ProfileWalletCards({super.key});

  @override
  State<ProfileWalletCards> createState() => _ProfileWalletCardsState();
}

class _ProfileWalletCardsState extends State<ProfileWalletCards> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openStore() {
    AppHaptics.mediumImpact();
    goToStoreTab(context);
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<AppRepo>().wallet;
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final recharging = wallet.energy < WalletConfig.energyCap;
    final energySubtitle = recharging
        ? l10n.nextEnergyIn(CurrencyBar.formatCountdown(wallet.timeToNextEnergy()))
        : l10n.energyFull;

    return Row(
      children: [
        Expanded(
          child: _WalletCard(
            icon: CupertinoIcons.bolt_fill,
            iconColor: theme.warning,
            label: l10n.energy,
            value: '${wallet.energy}',
            subtitle: energySubtitle,
            onPressed: _openStore,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _WalletCard(
            icon: coinIcon,
            iconColor: theme.turnHighlight,
            label: l10n.coins,
            value: '${wallet.coins}',
            subtitle: l10n.buyCoins,
            onPressed: _openStore,
          ),
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    // Extra inset so the corner plus badge doesn't overflow this card.
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 14),
              decoration: BoxDecoration(
                color: theme.surface.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.border.withValues(alpha: .55)),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: .22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: iconColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.title.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.muted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.surfaceAlt,
                  border: Border.all(color: theme.background, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: .28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  CupertinoIcons.plus,
                  size: 16,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
