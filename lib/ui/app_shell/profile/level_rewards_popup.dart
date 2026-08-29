import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/experience.dart';
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

/// Highest level at the top of the list, level 1 at the bottom.
final List<LevelRewardDef> _roadmapLevels = levelRewards.reversed.toList();

class LevelRewardsPopupCard extends StatefulWidget {
  const LevelRewardsPopupCard({super.key});

  @override
  State<LevelRewardsPopupCard> createState() => _LevelRewardsPopupCardState();
}

class _LevelRewardsPopupCardState extends State<LevelRewardsPopupCard> {
  final ScrollController _scroll = ScrollController();
  static const double _rowExtent = 76;
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
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
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
                // Path above connects this node to the higher level above.
                final pathAboveReached = def.level < progress.level;
                // Path below connects to the lower level under this node.
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
                  onClaim: claimable && !_claiming
                      ? (origin) => _claim(def, origin)
                      : null,
                );
              },
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
    this.onClaim,
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
  final void Function(Offset? origin)? onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
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
                    Text(
                      l10n.levelLabel(def.level),
                      style: theme.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.xp,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, size: 20, color: iconColor),
                    const SizedBox(width: 4),
                    Text(
                      '+${def.amount}',
                      style: theme.title.copyWith(
                        fontSize: 15,
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
