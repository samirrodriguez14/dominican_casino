import 'dart:async';

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/experience.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
import 'package:dominican_casino/ui/widgets/exp_icon.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/ui/widgets/wallet_dialogs.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Energy, coins, and XP pills on the profile face, with an optional action.
class ProfileWalletPills extends StatefulWidget {
  const ProfileWalletPills({super.key, this.scoreTheme, this.trailing});

  final AvatarScoreTheme? scoreTheme;
  final Widget? trailing;

  @override
  State<ProfileWalletPills> createState() => _ProfileWalletPillsState();
}

class _ProfileWalletPillsState extends State<ProfileWalletPills> {
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
    final repo = context.watch<AppRepo>();
    final wallet = repo.wallet;
    final xpProgress = ExperienceProgress.fromTotal(repo.player?.xp ?? 0);
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final recharging = wallet.energy < WalletConfig.energyCap;
    final energySubtitle = recharging
        ? CurrencyBar.formatCountdown(wallet.timeToNextEnergy())
        : l10n.energyFull;

    return Align(
      alignment: Alignment.centerRight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            _WalletPill(
              icon: CupertinoIcons.bolt_fill,
              iconColor: theme.warning,
              label: l10n.energy,
              value: '${wallet.energy}',
              subtitle: energySubtitle,
              scoreTheme: widget.scoreTheme,
              onPressed: _openStore,
            ),
            const SizedBox(width: 8),
            _WalletPill(
              icon: coinIcon,
              iconColor: theme.turnHighlight,
              label: l10n.coins,
              value: '${wallet.coins}',
              scoreTheme: widget.scoreTheme,
              onPressed: _openStore,
            ),
            const SizedBox(width: 8),
            _WalletPill(
              icon: expIcon,
              iconColor: theme.xp,
              label: l10n.xp,
              value: '${xpProgress.xpInLevel}',
              subtitle: '/ ${xpProgress.xpToNext}',
              scoreTheme: widget.scoreTheme,
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _WalletPill extends StatelessWidget {
  const _WalletPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onPressed,
    this.subtitle,
    this.scoreTheme,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onPressed;
  final AvatarScoreTheme? scoreTheme;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final score = scoreTheme;
    final fill = score?.panel ?? theme.surface;
    final stroke = score != null
        ? score.ink.withValues(alpha: 0.18)
        : theme.border.withValues(alpha: .6);
    final valueColor = score?.ink ?? theme.textPrimary;
    final subtitleColor = score?.muted ?? theme.muted;

    final content = Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: iconColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.title.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: valueColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: theme.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: subtitleColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Semantics(
      button: onPressed != null,
      label: subtitle == null ? '$label $value' : '$label $value, $subtitle',
      child: onPressed == null
          ? content
          : CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onPressed,
              child: content,
            ),
    );
  }
}
