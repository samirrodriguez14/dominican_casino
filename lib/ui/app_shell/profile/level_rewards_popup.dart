import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/l10n/journey_l10n.dart';
import 'package:dominican_casino/models/experience.dart';
import 'package:dominican_casino/models/level_challenge.dart';
import 'package:dominican_casino/models/level_rewards.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
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

/// Highest level at the top of the list, level 1 at the bottom.
final List<LevelRewardDef> _roadmapLevels = levelRewards.reversed.toList();

final List<int> _challengeLevels = levelChallengeUnlockLevelsReversed();

enum _PopupTab { rewards, challenges }

class LevelRewardsPopupCard extends StatefulWidget {
  const LevelRewardsPopupCard({super.key});

  @override
  State<LevelRewardsPopupCard> createState() => _LevelRewardsPopupCardState();
}

class _LevelRewardsPopupCardState extends State<LevelRewardsPopupCard> {
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _challengeLevelKeys = {
    for (final level in _challengeLevels) level: GlobalKey(),
  };
  static const double _rowExtent = 88;
  bool _claiming = false;
  _PopupTab _tab = _PopupTab.rewards;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = context.read<AppRepo>();
      if (repo.hasUnclaimedLevelChallenges && !repo.hasUnclaimedLevelRewards) {
        setState(() => _tab = _PopupTab.challenges);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToFocus();
        });
        return;
      }
      _scrollToFocus();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToFocus() {
    if (!mounted || !_scroll.hasClients) return;
    if (_tab == _PopupTab.challenges) {
      _scrollToRecentChallengeLevel();
      return;
    }
    final repo = context.read<AppRepo>();
    final level = repo.experienceProgress.level;
    var focusIndex = _roadmapLevels.length - 1;
    for (var i = 0; i < _roadmapLevels.length; i++) {
      final def = _roadmapLevels[i];
      if (repo.canClaimLevelReward(def.level)) {
        focusIndex = i;
        break;
      }
      if (def.level == level || def.level == level + 1) {
        focusIndex = i;
      }
    }
    final max = _scroll.position.maxScrollExtent;
    final target = (focusIndex * _rowExtent - 40).clamp(0.0, max);
    _scroll.jumpTo(target);
  }

  void _scrollToRecentChallengeLevel() {
    final repo = context.read<AppRepo>();
    final focusLevel =
        repo.experienceProgress.level.clamp(1, maxLevelChallengeLevel);
    final key = _challengeLevelKeys[focusLevel];
    final ctx = key?.currentContext;
    if (ctx == null) {
      // List may not be laid out yet (e.g. just switched tabs).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _tab != _PopupTab.challenges) return;
        final retry = _challengeLevelKeys[focusLevel]?.currentContext;
        if (retry != null) {
          Scrollable.ensureVisible(
            retry,
            alignment: 0.05,
            duration: Duration.zero,
          );
        }
      });
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.05,
      duration: Duration.zero,
    );
  }

  Future<void> _claimReward(LevelRewardDef def, Offset? origin) async {
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

  Future<void> _claimChallenge(LevelChallengeDef def, Offset? origin) async {
    if (_claiming) return;
    final repo = context.read<AppRepo>();
    if (!repo.canClaimLevelChallenge(def)) return;

    _claiming = true;
    setState(() {});
    try {
      AppHaptics.mediumImpact();
      final to = CurrencyBar.centerOf(CurrencyBar.coinsChipKey);
      if (origin != null && to != null && mounted && def.coinReward > 0) {
        await CurrencyBurst.play(
          context: context,
          from: origin,
          to: to,
          icon: coinIcon,
          color: AppStyle.theme.turnHighlight,
          count: def.coinReward.clamp(5, 12),
        );
      }
      if (!mounted) return;
      await repo.claimLevelChallenge(def.id);
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
    final title = _tab == _PopupTab.rewards
        ? l10n.levelRewardsTitle
        : l10n.levelChallengesTitle;

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
            title,
            textAlign: TextAlign.center,
            style: theme.title.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _TabBar(
            tab: _tab,
            rewardBadge: repo.unclaimedLevelRewardCount,
            challengeBadge: repo.unclaimedLevelChallengeCount,
            onChanged: (tab) {
              setState(() => _tab = tab);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _scrollToFocus();
              });
            },
          ),
          const SizedBox(height: 12),
          Flexible(
            child: _tab == _PopupTab.rewards
                ? ListView.builder(
                    controller: _scroll,
                    itemExtent: _rowExtent,
                    itemCount: _roadmapLevels.length,
                    padding: const EdgeInsets.only(bottom: 4),
                    itemBuilder: (context, index) {
                      final def = _roadmapLevels[index];
                      final claimed = repo.isLevelRewardClaimed(def.level);
                      final claimable = repo.canClaimLevelReward(def.level);
                      final locked = !claimed && !claimable;
                      final emphasizeNext =
                          locked && nextLocked != null && def.level == nextLocked;
                      final isCurrent = def.level == progress.level;
                      final pathAboveReached = def.level < progress.level;
                      final pathBelowReached = def.level <= progress.level;
                      return _RoadmapRow(
                        def: def,
                        claimed: claimed,
                        claimable: claimable,
                        locked: locked,
                        emphasizeNext: emphasizeNext,
                        isCurrent: isCurrent,
                        claimBusy: _claiming,
                        showTopLine: index > 0,
                        showBottomLine: index < _roadmapLevels.length - 1,
                        topLineReached: pathAboveReached,
                        bottomLineReached: pathBelowReached,
                        kingdomStatus: def.unlocksJourneyWorld == null
                            ? null
                            : journeyKingdomRewardStatus(
                                world: def.unlocksJourneyWorld!,
                                playerLevel: progress.level,
                                hasEntered: repo.journeyProgress
                                    .hasEntered(def.unlocksJourneyWorld!),
                                canUnlock: repo.journeyProgress
                                    .canUnlockThemeFor(
                                  def.unlocksJourneyWorld!,
                                  playerLevel: progress.level,
                                ),
                              ),
                        onClaim: claimable && !_claiming
                            ? (origin) => _claimReward(def, origin)
                            : null,
                        onOpenJourney: () {
                          Navigator.pop(context);
                          repo.requestOpenJourney();
                        },
                      );
                    },
                  )
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.only(bottom: 4),
                    children: [
                      for (final level in _challengeLevels)
                        KeyedSubtree(
                          key: _challengeLevelKeys[level],
                          child: _ChallengeLevelBlock(
                            level: level,
                            playerLevel: progress.level,
                            claimBusy: _claiming,
                            onClaim: (def, origin) =>
                                _claimChallenge(def, origin),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          _CurrentLevelFooter(progress: progress),
          CupertinoButton(
            padding: const EdgeInsets.only(top: 2),
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

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tab,
    required this.rewardBadge,
    required this.challengeBadge,
    required this.onChanged,
  });

  final _PopupTab tab;
  final int rewardBadge;
  final int challengeBadge;
  final ValueChanged<_PopupTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);

    Widget chip(_PopupTab value, String label, int badge) {
      final selected = tab == value;
      return Expanded(
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 8),
          minimumSize: Size.zero,
          onPressed: SoundService.wrapTap(() => onChanged(value)),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.xp.withValues(alpha: 0.18)
                      : theme.background.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? theme.xp.withValues(alpha: 0.5)
                        : theme.border.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected ? theme.xp : theme.muted,
                  ),
                ),
              ),
              if (badge > 0)
                Positioned(
                  top: -4,
                  right: 6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: theme.danger,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(_PopupTab.rewards, l10n.levelRewardsTab, rewardBadge),
        const SizedBox(width: 8),
        chip(_PopupTab.challenges, l10n.levelChallengesTab, challengeBadge),
      ],
    );
  }
}

class _ChallengeLevelBlock extends StatelessWidget {
  const _ChallengeLevelBlock({
    required this.level,
    required this.playerLevel,
    required this.claimBusy,
    required this.onClaim,
  });

  final int level;
  final int playerLevel;
  final bool claimBusy;
  final void Function(LevelChallengeDef def, Offset? origin) onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final repo = context.watch<AppRepo>();
    final defs = levelChallengesForLevel(level);
    final unlocked = playerLevel >= level;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              l10n.levelLabel(level),
              style: theme.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: unlocked ? theme.xp : theme.muted,
              ),
            ),
          ),
          for (final def in defs)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ChallengeRow(
                def: def,
                progress: repo.levelChallengeProgress(def.id),
                claimed: repo.isLevelChallengeClaimed(def.id),
                claimable: repo.canClaimLevelChallenge(def),
                locked: !unlocked,
                claimBusy: claimBusy,
                onClaim: claimBusy
                    ? null
                    : (origin) => onClaim(def, origin),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  const _ChallengeRow({
    required this.def,
    required this.progress,
    required this.claimed,
    required this.claimable,
    required this.locked,
    required this.claimBusy,
    this.onClaim,
  });

  final LevelChallengeDef def;
  final int progress;
  final bool claimed;
  final bool claimable;
  final bool locked;
  final bool claimBusy;
  final void Function(Offset? origin)? onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final opacity = claimed ? 0.55 : 1.0;
    final capped = progress.clamp(0, def.goal);

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: claimable
              ? theme.xp.withValues(alpha: 0.10)
              : theme.background.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: claimable
                ? theme.xp.withValues(alpha: 0.45)
                : theme.border.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    locked
                        ? l10n.reachLevelToUnlock(def.unlockLevel)
                        : l10n.levelChallengeTitle(def.id),
                    style: theme.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.25,
                      color: locked ? theme.muted : theme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                else if (locked)
                  Icon(
                    CupertinoIcons.lock_fill,
                    size: 16,
                    color: theme.muted,
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
                  ),
              ],
            ),
            if (!locked) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(CupertinoIcons.star_fill, size: 14, color: theme.xp),
                  const SizedBox(width: 3),
                  Text(
                    '+${def.xpReward}',
                    style: theme.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.xp,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(coinIcon, size: 14, color: theme.turnHighlight),
                  const SizedBox(width: 3),
                  Text(
                    '+${def.coinReward}',
                    style: theme.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.turnHighlight,
                    ),
                  ),
                  if (!claimed && !claimable) ...[
                    const Spacer(),
                    Text(
                      l10n.levelChallengeProgress(capped, def.goal),
                      style: theme.caption.copyWith(
                        color: theme.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrentLevelFooter extends StatelessWidget {
  const _CurrentLevelFooter({required this.progress});

  final ExperienceProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.xp.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            l10n.levelLabel(progress.level),
            style: theme.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.xp,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: theme.xp.withValues(alpha: 0.18)),
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
        ],
      ),
    );
  }
}

class _RoadmapRow extends StatelessWidget {
  const _RoadmapRow({
    required this.def,
    required this.claimed,
    required this.claimable,
    required this.locked,
    required this.emphasizeNext,
    required this.isCurrent,
    required this.claimBusy,
    required this.showTopLine,
    required this.showBottomLine,
    required this.topLineReached,
    required this.bottomLineReached,
    this.kingdomStatus,
    this.onClaim,
    this.onOpenJourney,
  });

  final LevelRewardDef def;
  final bool claimed;
  final bool claimable;
  final bool locked;
  final bool emphasizeNext;
  final bool isCurrent;
  final bool claimBusy;
  final bool showTopLine;
  final bool showBottomLine;
  final bool topLineReached;
  final bool bottomLineReached;
  final JourneyKingdomRewardStatus? kingdomStatus;
  final void Function(Offset? origin)? onClaim;
  final VoidCallback? onOpenJourney;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final journeyL10n = JourneyL10n.of(context);
    final energy = def.isEnergy;
    final icon = energy ? CupertinoIcons.bolt_fill : coinIcon;
    final iconColor = energy ? theme.warning : theme.turnHighlight;
    final opacity = claimed ? 0.55 : 1.0;
    final reached = claimed || claimable || isCurrent;
    final nodeColor = emphasizeNext || isCurrent
        ? theme.xp
        : reached
            ? theme.xp.withValues(alpha: 0.75)
            : theme.muted.withValues(alpha: 0.55);
    final kingdom = def.unlocksJourneyWorld;

    return Opacity(
      opacity: opacity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: CustomPaint(
              painter: _RoadmapRailPainter(
                showTop: showTopLine,
                showBottom: showBottomLine,
                topReached: topLineReached,
                bottomReached: bottomLineReached,
                nodeColor: nodeColor,
                reachedLine: theme.xp,
                lockedLine: theme.muted.withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: emphasizeNext || isCurrent
                      ? theme.xp.withValues(alpha: 0.10)
                      : theme.background.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: emphasizeNext || isCurrent
                        ? theme.xp.withValues(alpha: 0.45)
                        : theme.border.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.levelLabel(def.level),
                                style: theme.caption.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.xp,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(icon, size: 18, color: iconColor),
                              const SizedBox(width: 4),
                              Text(
                                '+${def.amount}',
                                style: theme.title.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          if (kingdom != null && kingdomStatus != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${kingdom.suitSymbol} ${_kingdomCaption(
                                l10n,
                                journeyL10n,
                                kingdom,
                                kingdomStatus!,
                              )}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kingdomStatus ==
                                            JourneyKingdomRewardStatus
                                                .readyToEnter ||
                                        emphasizeNext ||
                                        isCurrent
                                    ? theme.textPrimary
                                    : theme.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                                    final box = buttonContext
                                        .findRenderObject() as RenderBox?;
                                    final origin =
                                        box == null || !box.hasSize
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
                    else if (kingdomStatus ==
                        JourneyKingdomRewardStatus.readyToEnter)
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        color: theme.turnHighlight.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                        onPressed: onOpenJourney == null
                            ? null
                            : SoundService.wrapTap(onOpenJourney!),
                        child: Text(
                          l10n.goToJourney,
                          style: theme.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1224),
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      Icon(
                        CupertinoIcons.lock_fill,
                        size: 16,
                        color: theme.muted,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _kingdomCaption(
    AppLocalizations l10n,
    JourneyL10n journeyL10n,
    JourneyWorld kingdom,
    JourneyKingdomRewardStatus status,
  ) {
    final name = journeyL10n.worldLabel(kingdom);
    return switch (status) {
      JourneyKingdomRewardStatus.lockedByLevel => l10n.unlocksKingdom(name),
      JourneyKingdomRewardStatus.needsPriorAce =>
        l10n.kingdomNeedsPriorAce(name),
      JourneyKingdomRewardStatus.readyToEnter =>
        l10n.kingdomReadyToEnter(name),
      JourneyKingdomRewardStatus.entered =>
        l10n.kingdomAlreadyUnlocked(name),
    };
  }
}

class _RoadmapRailPainter extends CustomPainter {
  const _RoadmapRailPainter({
    required this.showTop,
    required this.showBottom,
    required this.topReached,
    required this.bottomReached,
    required this.nodeColor,
    required this.reachedLine,
    required this.lockedLine,
  });

  final bool showTop;
  final bool showBottom;
  final bool topReached;
  final bool bottomReached;
  final Color nodeColor;
  final Color reachedLine;
  final Color lockedLine;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final midY = size.height / 2;
    const stroke = 3.0;
    const nodeR = 6.0;

    void drawSeg(double y0, double y1, Color color) {
      canvas.drawLine(
        Offset(x, y0),
        Offset(x, y1),
        Paint()
          ..color = color
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    if (showTop) {
      drawSeg(0, midY - nodeR + 1, topReached ? reachedLine : lockedLine);
    }
    if (showBottom) {
      drawSeg(
        midY + nodeR - 1,
        size.height,
        bottomReached ? reachedLine : lockedLine,
      );
    }

    canvas.drawCircle(
      Offset(x, midY),
      nodeR + 1.5,
      Paint()..color = nodeColor.withValues(alpha: 0.25),
    );
    canvas.drawCircle(Offset(x, midY), nodeR, Paint()..color = nodeColor);
  }

  @override
  bool shouldRepaint(covariant _RoadmapRailPainter oldDelegate) {
    return oldDelegate.showTop != showTop ||
        oldDelegate.showBottom != showBottom ||
        oldDelegate.topReached != topReached ||
        oldDelegate.bottomReached != bottomReached ||
        oldDelegate.nodeColor != nodeColor ||
        oldDelegate.reachedLine != reachedLine ||
        oldDelegate.lockedLine != lockedLine;
  }
}
