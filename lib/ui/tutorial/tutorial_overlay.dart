import 'dart:math' as math;

import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dominican_casino/style/app_theme.dart';

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
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GlobalKey _overlayKey = GlobalKey();

  static const double _tooltipWidth = 320;
  static const double _tooltipMinHeight = 160;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
    final rect = MatrixUtils.transformRect(
      target.getTransformTo(overlay),
      Offset.zero & target.size,
    );
    if (!rect.isFinite || rect.isEmpty) return null;
    return rect;
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
    if (rect == null) return _buildFloatingTooltip(context);

    final overlay = _overlayKey.currentContext?.findRenderObject();
    final overlaySize = overlay is RenderBox && overlay.hasSize
        ? overlay.size
        : MediaQuery.of(context).size;

    Offset tooltipOffset;

    if (rect.center.dy > overlaySize.height * 0.5) {
      tooltipOffset = Offset(
        rect.center.dx - _tooltipWidth / 2,
        rect.top - _tooltipMinHeight - 20,
      );
    } else {
      tooltipOffset = Offset(
        rect.center.dx - _tooltipWidth / 2,
        rect.bottom + 16,
      );
    }

    tooltipOffset = Offset(
      tooltipOffset.dx.clamp(12.0, overlaySize.width - _tooltipWidth - 12),
      tooltipOffset.dy.clamp(12.0, overlaySize.height - _tooltipMinHeight - 12),
    );

    return Positioned(
      left: tooltipOffset.dx,
      top: tooltipOffset.dy,
      child: Material(color: Colors.transparent, child: _buildTooltipContent()),
    );
  }

  Widget _buildTooltipAboveTable(BuildContext context) {
    final overlay = _overlayKey.currentContext?.findRenderObject();
    final overlaySize = overlay is RenderBox && overlay.hasSize
        ? overlay.size
        : MediaQuery.of(context).size;

    final table = _rectForKey(widget.tableAnchorKey);
    const estimatedH = 210.0;
    final safeTop = MediaQuery.paddingOf(context).top + 8;
    var top = safeTop;
    if (table != null) {
      final preferred = table.top - estimatedH - 10;
      if (preferred > safeTop) top = preferred;
    }
    final maxLeft = math.max(12.0, overlaySize.width - _tooltipWidth - 12);
    final left = ((overlaySize.width - _tooltipWidth) / 2)
        .clamp(12.0, maxLeft)
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      child: Material(color: Colors.transparent, child: _buildTooltipContent()),
    );
  }

  Widget _buildFloatingTooltip(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: _buildTooltipContent(),
      ),
    );
  }

  Widget _buildTooltipContent() {
    final theme = AppStyle.theme;
    final isLastStep = widget.isLastScreen;
    final canPressNext = widget.canGoNext || widget.step.onShow != null;
    return Container(
      width: _tooltipWidth,
      decoration: BoxDecoration(
        color: theme.surfaceRaised,
        borderRadius: BorderRadius.circular(theme.radius),
        border: Border.all(
          color: theme.turnHighlight.withValues(alpha: .65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step ${widget.currentStep + 1} of ${widget.totalSteps}',
                style: theme.caption.copyWith(
                  color: theme.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: List.generate(widget.totalSteps, (index) {
                    final isCurrent = index == widget.currentStep;
                    final isDone = index < widget.currentStep;

                    return Flexible(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 7,
                        decoration: BoxDecoration(
                          color: isCurrent || isDone
                              ? theme.turnHighlight
                              : theme.muted.withValues(alpha: .35),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            widget.step.title,
            style: theme.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.step.description,
            style: theme.body.copyWith(
              color: theme.textPrimary.withValues(alpha: .9),
              fontSize: 13.5,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              if (isLastStep) ...[
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(theme.radius),
                    onPressed: SoundService.wrapTap(widget.onExit),
                    child: Text(
                      'Exit',
                      style: theme.body.copyWith(
                        color: theme.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    color: theme.turnHighlight,
                    borderRadius: BorderRadius.circular(theme.radius),
                    onPressed: SoundService.wrapTap(widget.onPlay),
                    child: Text(
                      'Play',
                      style: theme.body.copyWith(
                        color: theme.background,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                if (widget.step.showSkipButton) ...[
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(theme.radius),
                      onPressed: SoundService.wrapTap(widget.onSkip),
                      child: Text(
                        'Skip',
                        style: theme.body.copyWith(
                          color: theme.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (widget.step.showNextButton)
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      color: canPressNext
                          ? theme.turnHighlight
                          : theme.muted.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(theme.radius),
                      onPressed: canPressNext
                          ? SoundService.wrapTap(
                              widget.step.onShow != null
                                  ? () => widget.step.onShow!(context)
                                  : widget.onNext,
                            )
                          : null,
                      child: Text(
                        'Next',
                        style: theme.body.copyWith(
                          color: canPressNext
                              ? theme.background
                              : theme.textPrimary.withValues(alpha: .45),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
