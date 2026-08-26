import 'dart:math' as math;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _BubbleTail { none, up, down }

class TutorialOverlay extends StatefulWidget {
  final TutorialStep step;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onPlay;
  final VoidCallback? onExit;
  final int currentStep;
  final int totalSteps;
  final bool canGoNext;
  final bool isLastScreen;
  final GlobalKey? tableAnchorKey;
  /// When [isLastScreen] and [onExit] is null, label for the single primary button.
  final String? lastPrimaryLabel;

  const TutorialOverlay({
    super.key,
    required this.step,
    required this.onNext,
    required this.onSkip,
    required this.currentStep,
    required this.totalSteps,
    required this.canGoNext,
    this.isLastScreen = false,
    this.onPlay,
    this.onExit,
    this.tableAnchorKey,
    this.lastPrimaryLabel,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _popAnimation;
  final GlobalKey _overlayKey = GlobalKey();

  static const double _avatarSize = 32;
  static const double _avatarGap = 8;
  static const double _bubbleWidth = 248;
  static const double _tooltipWidth = _avatarSize + _avatarGap + _bubbleWidth;
  static const double _tooltipMinHeight = 88;
  /// Conservative height used when [TutorialStep.promptClearance] is set.
  static const double _tooltipPlaceHeight = 168;
  static const double _tailSize = 12;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _popAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.step.step != widget.step.step) {
      _animationController.reset();
      _animationController.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        key: _overlayKey,
        clipBehavior: Clip.none,
        children: [
          if (widget.step.highlightKeys.isNotEmpty)
            _buildTooltipForTarget(context)
          else
            _buildFloatingTooltip(context),
        ],
      ),
    );
  }

  Rect? _rectForKey(GlobalKey? key) {
    if (key == null) return null;
    final overlay = _overlayKey.currentContext?.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) return null;
    final target = key.currentContext?.findRenderObject();
    if (target is! RenderBox || !target.hasSize || target.size.isEmpty) {
      return null;
    }
    try {
      final rect = MatrixUtils.transformRect(
        target.getTransformTo(overlay),
        Offset.zero & target.size,
      );
      if (!rect.isFinite || rect.isEmpty) return null;
      return rect;
    } catch (_) {
      // Ancestors may still be laying out (e.g. Transform under LayoutBuilder).
      return null;
    }
  }

  /// Axis-aligned bounds of highlight targets, in overlay-local space.
  /// Uses [RenderObject.getTransformTo] so fanned / rotated cards line up.
  Rect? _targetRect() {
    final overlay = _overlayKey.currentContext?.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) return null;

    final maxW = overlay.size.width * 0.9;
    final maxH = overlay.size.height * 0.45;

    Rect? union;
    for (final key in widget.step.highlightKeys) {
      final rect = _rectForKey(key);
      if (rect == null) continue;
      // Flex parents (table column, full-width hand strip) are not the target.
      if (rect.width > maxW && rect.height > maxH) continue;
      union = union == null ? rect : union.expandToInclude(rect);
    }
    return union;
  }

  Widget _buildTooltipForTarget(BuildContext context) {
    if (widget.step.promptAboveTable) {
      return _buildTooltipAboveTable(context);
    }

    final rect = _targetRect();
    if (rect == null) {
      // Target may still be laying out; retry next frame instead of staying floating.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return _buildFloatingTooltip(context);
    }

    final overlay = _overlayKey.currentContext?.findRenderObject();
    final overlaySize = overlay is RenderBox && overlay.hasSize
        ? overlay.size
        : MediaQuery.of(context).size;

    // Profile coach (and others that set [promptClearance]) get stronger
    // target clearance. Casino / Journey keep the original placement so
    // training prompts stay where they were tuned.
    final customClearance = widget.step.promptClearance;
    if (customClearance != null) {
      return _buildTooltipClearOfTarget(
        context,
        rect: rect,
        overlaySize: overlaySize,
        gap: customClearance,
      );
    }

    final placeAbove = rect.center.dy > overlaySize.height * 0.5;
    final tail = placeAbove ? _BubbleTail.down : _BubbleTail.up;
    final desiredTooltipOffset = placeAbove
        ? Offset(
            rect.center.dx - _tooltipWidth / 2,
            rect.top - _tooltipMinHeight - 16,
          )
        : Offset(
            rect.center.dx - _tooltipWidth / 2,
            rect.bottom + 12,
          );

    final clampedTooltipOffset = Offset(
      desiredTooltipOffset.dx
          .clamp(12.0, overlaySize.width - _tooltipWidth - 12),
      desiredTooltipOffset.dy.clamp(
        12.0,
        overlaySize.height - _tooltipMinHeight - 12,
      ),
    );

    // Keep the tail pointed at the target rect even if we have to clamp the
    // tooltip to stay on-screen (otherwise clamping shifts the bubble, and
    // the tail "misses" the card/stack).
    final bubbleCenterX = clampedTooltipOffset.dx +
        _avatarSize +
        _avatarGap +
        _bubbleWidth / 2;
    final tailShiftX = rect.center.dx - bubbleCenterX;
    final maxTailShiftX = _bubbleWidth / 2 - 9; // 9 = 18px tail / 2
    final safeTailShiftX = tailShiftX.clamp(-maxTailShiftX, maxTailShiftX);
    final tailShiftY = desiredTooltipOffset.dy - clampedTooltipOffset.dy;

    return Positioned(
      left: clampedTooltipOffset.dx,
      top: clampedTooltipOffset.dy,
      child: Material(
        color: Colors.transparent,
        child: _buildTooltipContent(
          tail: tail,
          tailShiftX: safeTailShiftX,
          tailShiftY: tailShiftY,
        ),
      ),
    );
  }

  /// Places the bubble with extra clearance and flips sides if it would cover
  /// a tappable coach target (Profile tutorial).
  Widget _buildTooltipClearOfTarget(
    BuildContext context, {
    required Rect rect,
    required Size overlaySize,
    required double gap,
  }) {
    final safeTop = MediaQuery.paddingOf(context).top + 8;
    final maxLeft = math.max(12.0, overlaySize.width - _tooltipWidth - 12);
    final maxTop = math.max(
      safeTop,
      overlaySize.height - _tooltipPlaceHeight - 12,
    );

    final spaceAbove = rect.top - safeTop;
    final spaceBelow = overlaySize.height - rect.bottom - 12;
    final placeAbove = spaceAbove >= _tooltipPlaceHeight + gap ||
        (spaceAbove >= spaceBelow && spaceAbove >= gap + 48);

    Offset desiredTooltipOffset = placeAbove
        ? Offset(
            rect.center.dx - _tooltipWidth / 2,
            rect.top - _tooltipPlaceHeight - gap,
          )
        : Offset(
            rect.center.dx - _tooltipWidth / 2,
            rect.bottom + gap,
          );

    var clampedTooltipOffset = Offset(
      desiredTooltipOffset.dx.clamp(12.0, maxLeft),
      desiredTooltipOffset.dy.clamp(safeTop, maxTop),
    );

    final paddedTarget = rect.inflate(gap);
    Rect bubbleRect = Rect.fromLTWH(
      clampedTooltipOffset.dx,
      clampedTooltipOffset.dy,
      _tooltipWidth,
      _tooltipPlaceHeight,
    );
    if (bubbleRect.overlaps(paddedTarget)) {
      final aboveTop =
          (rect.top - _tooltipPlaceHeight - gap).clamp(safeTop, maxTop);
      final belowTop = (rect.bottom + gap).clamp(safeTop, maxTop);
      final aboveRect = Rect.fromLTWH(
        clampedTooltipOffset.dx,
        aboveTop,
        _tooltipWidth,
        _tooltipPlaceHeight,
      );
      final belowRect = Rect.fromLTWH(
        clampedTooltipOffset.dx,
        belowTop,
        _tooltipWidth,
        _tooltipPlaceHeight,
      );
      final aboveClear = !aboveRect.overlaps(paddedTarget);
      final belowClear = !belowRect.overlaps(paddedTarget);
      if (aboveClear && (!belowClear || spaceAbove >= spaceBelow)) {
        clampedTooltipOffset = Offset(clampedTooltipOffset.dx, aboveTop);
        desiredTooltipOffset = Offset(desiredTooltipOffset.dx, aboveTop);
      } else if (belowClear) {
        clampedTooltipOffset = Offset(clampedTooltipOffset.dx, belowTop);
        desiredTooltipOffset = Offset(desiredTooltipOffset.dx, belowTop);
      } else {
        clampedTooltipOffset = Offset(clampedTooltipOffset.dx, safeTop);
        desiredTooltipOffset = Offset(desiredTooltipOffset.dx, safeTop);
      }
      bubbleRect = Rect.fromLTWH(
        clampedTooltipOffset.dx,
        clampedTooltipOffset.dy,
        _tooltipWidth,
        _tooltipPlaceHeight,
      );
    }

    final placedAbove = bubbleRect.center.dy <= rect.center.dy;
    final tail = placedAbove ? _BubbleTail.down : _BubbleTail.up;

    final playerOnRight = widget.step.speaker == TutorialSpeaker.player;
    final bubbleCenterX = playerOnRight
        ? clampedTooltipOffset.dx + _bubbleWidth / 2
        : clampedTooltipOffset.dx +
            _avatarSize +
            _avatarGap +
            _bubbleWidth / 2;
    final tailShiftX = rect.center.dx - bubbleCenterX;
    final maxTailShiftX = _bubbleWidth / 2 - 9;
    final safeTailShiftX = tailShiftX.clamp(-maxTailShiftX, maxTailShiftX);
    final tailShiftY = desiredTooltipOffset.dy - clampedTooltipOffset.dy;

    return Positioned(
      left: clampedTooltipOffset.dx,
      top: clampedTooltipOffset.dy,
      child: Material(
        color: Colors.transparent,
        child: _buildTooltipContent(
          tail: tail,
          tailShiftX: safeTailShiftX,
          tailShiftY: tailShiftY,
        ),
      ),
    );
  }

  Widget _buildTooltipAboveTable(BuildContext context) {
    final overlay = _overlayKey.currentContext?.findRenderObject();
    final overlaySize = overlay is RenderBox && overlay.hasSize
        ? overlay.size
        : MediaQuery.of(context).size;

    final safeTop = MediaQuery.paddingOf(context).top + 8;

    // Aim the tail at the same highlight rect (not just centered above the
    // table). If the tooltip has to be clamped, we also translate the tail
    // to compensate.
    final rect = _targetRect();
    final desiredTop = rect != null
        ? rect.top - _tooltipMinHeight - 16
        : safeTop;
    final desiredLeft = rect != null
        ? rect.center.dx - _tooltipWidth / 2
        : (overlaySize.width - _tooltipWidth) / 2;

    final clampedLeft =
        desiredLeft.clamp(12.0, overlaySize.width - _tooltipWidth - 12);
    final clampedTop = desiredTop.clamp(
      safeTop,
      overlaySize.height - _tooltipMinHeight - 12,
    );

    final playerOnRight = widget.step.speaker == TutorialSpeaker.player;
    final bubbleCenterX = playerOnRight
        ? clampedLeft + _bubbleWidth / 2
        : clampedLeft + _avatarSize + _avatarGap + _bubbleWidth / 2;
    final tailShiftX = rect?.center.dx != null ? rect!.center.dx - bubbleCenterX : 0.0;
    final maxTailShiftX = _bubbleWidth / 2 - 9; // 9 = 18px tail / 2
    final safeTailShiftX = tailShiftX.clamp(-maxTailShiftX, maxTailShiftX);
    final tailShiftY = desiredTop - clampedTop;

    final maxLeft = math.max(12.0, overlaySize.width - _tooltipWidth - 12);

    return Positioned(
      left: clampedLeft.clamp(12.0, maxLeft),
      top: clampedTop,
      child: Material(
        color: Colors.transparent,
        child: _buildTooltipContent(
          tail: _BubbleTail.down,
          tailShiftX: safeTailShiftX,
          tailShiftY: tailShiftY,
        ),
      ),
    );
  }

  Widget _buildFloatingTooltip(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: _buildTooltipContent(tail: _BubbleTail.none),
      ),
    );
  }

  String _resolveAvatarId() {
    final override = widget.step.avatarId;
    if (override != null && override.isNotEmpty) return override;
    switch (widget.step.speaker) {
      case TutorialSpeaker.player:
        final player = context.read<AppRepo>().player;
        return player?.avatarId ?? Player.defaultAvatarId;
      case TutorialSpeaker.guide:
        return GameState.localBotAvatarId;
    }
  }

  Widget _buildTooltipContent({
    required _BubbleTail tail,
    double tailShiftX = 0.0,
    double tailShiftY = 0.0,
  }) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final fill = theme.surfaceRaised;
    final stroke = theme.turnHighlight.withValues(alpha: .45);
    final hasSpeakerLabel =
        widget.step.title.isNotEmpty && widget.step.description.isNotEmpty;
    final message = widget.step.description.isNotEmpty
        ? widget.step.description
        : widget.step.title;
    final playerOnRight = widget.step.speaker == TutorialSpeaker.player;

    final bubble = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: _bubbleWidth,
          padding: const EdgeInsets.fromLTRB(16, 16, 18, 12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: stroke, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .32),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: playerOnRight ? 0 : 36,
                  left: playerOnRight ? 36 : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasSpeakerLabel) ...[
                      Text(
                        widget.step.title,
                        style: theme.body.copyWith(
                          color: theme.muted,
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message,
                      style: theme.body.copyWith(
                        color: theme.textPrimary,
                        fontSize: 20,
                        height: 1.28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildBubbleActions(theme, l10n),
            ],
          ),
        ),
        Positioned(
          top: -6,
          left: playerOnRight ? -6 : null,
          right: playerOnRight ? null : -6,
          child: _StepProgressCircle(
            current: widget.currentStep + 1,
            total: widget.totalSteps,
          ),
        ),
      ],
    );

    Widget tailedBubble = bubble;
    if (tail != _BubbleTail.none) {
      final painter = _TutorialBubbleTailPainter(
        fill: fill,
        stroke: stroke,
        direction: tail,
      );
      tailedBubble = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tail == _BubbleTail.up)
            Transform.translate(
              offset: Offset(tailShiftX, tailShiftY),
              child:
                  CustomPaint(size: const Size(18, _tailSize), painter: painter),
            ),
          bubble,
          if (tail == _BubbleTail.down)
            Transform.translate(
              offset: Offset(tailShiftX, tailShiftY),
              child:
                  CustomPaint(size: const Size(18, _tailSize), painter: painter),
            ),
        ],
      );
    }

    final avatar = Padding(
      padding: EdgeInsets.only(
        bottom: tail == _BubbleTail.down ? _tailSize : 0,
      ),
      child: PlayerAvatarView(
        avatarId: _resolveAvatarId(),
        size: _avatarSize,
      ),
    );
    final scaledBubble = ScaleTransition(scale: _popAnimation, child: tailedBubble);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: playerOnRight
          ? [
              scaledBubble,
              const SizedBox(width: _avatarGap),
              avatar,
            ]
          : [
              avatar,
              const SizedBox(width: _avatarGap),
              scaledBubble,
            ],
    );
  }

  Widget _buildBubbleActions(AppTheme theme, AppLocalizations l10n) {
    final isLastStep = widget.isLastScreen;
    final canPressNext = widget.canGoNext || widget.step.onShow != null;

    if (isLastStep) {
      final primary = widget.onPlay ?? widget.onNext;
      // Single CTA when there is no exit/home action (e.g. Journey coach).
      if (widget.onExit == null) {
        return SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: theme.turnHighlight,
            borderRadius: BorderRadius.circular(14),
            onPressed: SoundService.wrapTap(primary),
            child: Text(
              widget.lastPrimaryLabel ?? l10n.tutorialGotIt,
              style: theme.body.copyWith(
                color: theme.background,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }
      return Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: theme.surface,
              borderRadius: BorderRadius.circular(14),
              onPressed: SoundService.wrapTap(widget.onExit),
              child: Text(
                l10n.home,
                style: theme.body.copyWith(
                  color: theme.muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: theme.turnHighlight,
              borderRadius: BorderRadius.circular(14),
              onPressed: SoundService.wrapTap(widget.onPlay),
              child: Text(
                l10n.play,
                style: theme.body.copyWith(
                  color: theme.background,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (widget.step.showSkipButton)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            minimumSize: Size.zero,
            onPressed: SoundService.wrapTap(widget.onSkip),
            child: Text(
              l10n.skipTutorial,
              style: theme.body.copyWith(
                color: theme.muted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const Spacer(),
        if (widget.step.showNextButton)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size.zero,
            color: canPressNext
                ? theme.turnHighlight
                : theme.muted.withValues(alpha: .35),
            borderRadius: BorderRadius.circular(14),
            onPressed: canPressNext
                ? SoundService.wrapTap(
                    widget.step.onShow != null
                        ? () => widget.step.onShow!(context)
                        : widget.onNext,
                  )
                : null,
            child: Text(
              l10n.next,
              style: theme.body.copyWith(
                color: canPressNext
                    ? theme.background
                    : theme.textPrimary.withValues(alpha: .45),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _StepProgressCircle extends StatelessWidget {
  const _StepProgressCircle({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final progress = total <= 0 ? 0.0 : current / total;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: theme.border.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(40, 40),
            painter: _ProgressRingPainter(
              progress: progress.clamp(0.0, 1.0),
              track: theme.muted.withValues(alpha: .28),
              fill: theme.turnHighlight,
            ),
          ),
          Text(
            '$current/$total',
            style: theme.caption.copyWith(
              color: theme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      track != oldDelegate.track ||
      fill != oldDelegate.fill;
}

class _TutorialBubbleTailPainter extends CustomPainter {
  _TutorialBubbleTailPainter({
    required this.fill,
    required this.stroke,
    required this.direction,
  });

  final Color fill;
  final Color stroke;
  final _BubbleTail direction;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (direction == _BubbleTail.up) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close();
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _TutorialBubbleTailPainter oldDelegate) =>
      fill != oldDelegate.fill ||
      stroke != oldDelegate.stroke ||
      direction != oldDelegate.direction;
}
