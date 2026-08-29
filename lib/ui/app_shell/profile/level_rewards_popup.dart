import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/level_rewards.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/ui/animations/currency_burst.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

Future<void> showLevelRewardsPopup(BuildContext context) {
  AppHaptics.mediumImpact();
  return showAppCenterPopup<void>(
    context: context,
    builder: (dialogContext) => const LevelRewardsPopupCard(),
  );
}

class LevelRewardsPopupCard extends StatefulWidget {
  const LevelRewardsPopupCard({super.key});

  @override
  State<LevelRewardsPopupCard> createState() => _LevelRewardsPopupCardState();
}

class _LevelRewardsPopupCardState extends State<LevelRewardsPopupCard> {
  final ScrollController _scroll = ScrollController();
  static const double _rowExtent = 64;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocus());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToFocus() {
    if (!mounted || !_scroll.hasClients) return;
    final repo = context.read<AppRepo>();
    final level = repo.experienceProgress.level;
    var focusIndex = 0;
    for (var i = 0; i < levelRewards.length; i++) {
      final def = levelRewards[i];
      if (repo.canClaimLevelReward(def.level)) {
        focusIndex = i;
        break;
      }
      if (def.level > level) {
        focusIndex = i;
        break;
      }
      focusIndex = i;
    }
    final max = _scroll.position.maxScrollExtent;
    final target = (focusIndex * _rowExtent - 24).clamp(0.0, max);
    _scroll.jumpTo(target);
  }

  Future<void> _claim(LevelRewardDef def, Offset? origin) async {
    if (_claiming) return;
    final repo = context.read<AppRepo>();
    if (!repo.canClaimLevelReward(def.level)) return;

    _claiming = true;
    setState(() {});
    try {
      AppHaptics.mediumImpact();
      final energy = def.isEnergy;
      final to = CurrencyBar.centerOf(
        energy ? CurrencyBar.energyChipKey : CurrencyBar.coinsChipKey,
      );
      if (origin != null && to != null && mounted) {
        await CurrencyBurst.play(
          context: context,
          from: origin,
          to: to,
          icon: energy ? CupertinoIcons.bolt_fill : coinIcon,
          color: energy
              ? AppStyle.theme.warning
              : AppStyle.theme.turnHighlight,
          count: def.amount.clamp(5, 12),
        );
      }
      if (!mounted) return;
      await repo.claimLevelReward(def.level);
    } finally {
      _claiming = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final repo = context.watch<AppRepo>();
    final progress = repo.experienceProgress;
    final nextLocked = progress.level < maxLevelRewardLevel
        ? progress.level + 1
        : null;

    return Container(
      width: 340,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withValues(alpha: .7)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .45),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.levelRewardsTitle,
            textAlign: TextAlign.center,
            style: theme.title.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.levelLabel(progress.level),
            style: theme.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.xp,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: theme.xp.withValues(alpha: 0.18),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.progress.clamp(0.0, 1.0),
                    child: ColoredBox(color: theme.xp),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${progress.xpInLevel} / ${progress.xpToNext} ${l10n.xp}',
            style: theme.caption.copyWith(
              color: theme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.builder(
              controller: _scroll,
              itemExtent: _rowExtent,
              itemCount: levelRewards.length,
              itemBuilder: (context, index) {
                final def = levelRewards[index];
                final claimed = repo.isLevelRewardClaimed(def.level);
                final claimable = repo.canClaimLevelReward(def.level);
                final locked = !claimed && !claimable;
                final emphasizeNext =
                    locked && nextLocked != null && def.level == nextLocked;
                return _RewardRow(
                  def: def,
                  claimed: claimed,
                  claimable: claimable,
                  locked: locked,
                  emphasizeNext: emphasizeNext,
                  claimBusy: _claiming,
                  onClaim: claimable && !_claiming
                      ? (origin) => _claim(def, origin)
                      : null,
                );
              },
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(top: 4),
            onPressed: SoundService.wrapTap(() => Navigator.pop(context)),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: theme.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.def,
    required this.claimed,
    required this.claimable,
    required this.locked,
    required this.emphasizeNext,
    required this.claimBusy,
    this.onClaim,
  });

  final LevelRewardDef def;
  final bool claimed;
  final bool claimable;
  final bool locked;
  final bool emphasizeNext;
  final bool claimBusy;
  final void Function(Offset? origin)? onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final energy = def.isEnergy;
    final icon = energy ? CupertinoIcons.bolt_fill : coinIcon;
    final iconColor = energy ? theme.warning : theme.turnHighlight;
    final opacity = claimed ? 0.55 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: emphasizeNext
                ? theme.xp.withValues(alpha: 0.10)
                : theme.background.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: emphasizeNext
                  ? theme.xp.withValues(alpha: 0.45)
                  : theme.border.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.xp.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${def.level}',
                  style: theme.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.xp,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 6),
              Text(
                '+${def.amount}',
                style: theme.title.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (claimed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      size: 16,
                      color: theme.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.claimed,
                      style: theme.caption.copyWith(
                        color: theme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else if (claimable)
                Builder(
                  builder: (buttonContext) {
                    final enabled = onClaim != null && !claimBusy;
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      color: enabled
                          ? theme.xp
                          : theme.muted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                      onPressed: enabled
                          ? SoundService.wrapTap(() {
                              final box = buttonContext.findRenderObject()
                                  as RenderBox?;
                              final origin = box == null || !box.hasSize
                                  ? null
                                  : box.localToGlobal(
                                      box.size.center(Offset.zero),
                                    );
                              onClaim!(origin);
                            })
                          : null,
                      child: Text(
                        l10n.claim,
                        style: theme.caption.copyWith(
                          fontWeight: FontWeight.w800,
                          color: enabled
                              ? const Color(0xFF1A1224)
                              : theme.muted,
                        ),
                      ),
                    );
                  },
                )
              else
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        CupertinoIcons.lock_fill,
                        size: 14,
                        color: theme.muted,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.reachLevelToUnlock(def.level),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.caption.copyWith(
                            color: emphasizeNext
                                ? theme.textPrimary
                                : theme.muted,
                            fontWeight: emphasizeNext
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
