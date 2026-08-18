import 'dart:async';

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/ui/widgets/wallet_dialogs.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Side-by-side energy and coins cards on the profile face.
class ProfileWalletCards extends StatefulWidget {
  const ProfileWalletCards({
    super.key,
    this.embeddedInCard = false,
    this.scoreTheme,
  });

  /// Flatter chrome when sitting on a playing-card face.
  final bool embeddedInCard;
  final AvatarScoreTheme? scoreTheme;

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
            embeddedInCard: widget.embeddedInCard,
            scoreTheme: widget.scoreTheme,
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
            embeddedInCard: widget.embeddedInCard,
            scoreTheme: widget.scoreTheme,
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
    this.embeddedInCard = false,
    this.scoreTheme,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback onPressed;
  final bool embeddedInCard;
  final AvatarScoreTheme? scoreTheme;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final score = scoreTheme;
    final fill = score != null
        ? score.ink.withValues(alpha: 0.12)
        : embeddedInCard
        ? theme.textPrimary.withValues(alpha: .10)
        : theme.surface.withValues(alpha: .92);
    final stroke = score != null
        ? score.ink.withValues(alpha: 0.22)
        : embeddedInCard
        ? theme.textPrimary.withValues(alpha: .14)
        : theme.border.withValues(alpha: .55);
    final labelColor = score?.muted ?? theme.muted;
    final valueColor = score?.ink ?? theme.textPrimary;
    final badgeFill = score?.panel ?? theme.surfaceAlt;
    final badgeBorder = score != null
        ? score.background
        : embeddedInCard
        ? theme.textPrimary.withValues(alpha: .22)
        : theme.background;
    final badgeIcon = score?.foreground ?? iconColor;

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
                color: fill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: stroke),
                boxShadow: embeddedInCard
                    ? null
                    : [
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
                      Icon(icon, size: 16, color: badgeIcon),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: labelColor,
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
                      color: valueColor,
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
                      color: labelColor,
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
                  color: badgeFill,
                  border: Border.all(color: badgeBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: .28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(CupertinoIcons.plus, size: 16, color: badgeIcon),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
