import 'package:dominican_casino/models/tutorial_step.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dominican_casino/style/app_theme.dart';

class TutorialOverlay extends StatefulWidget {
  final TutorialStep step;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentStep;
  final int totalSteps;
  final bool canGoNext;

  const TutorialOverlay({
    super.key,
    required this.step,
    required this.onNext,
    required this.onSkip,
    required this.currentStep,
    required this.totalSteps,
    required this.canGoNext,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const double _tooltipWidth = 320;
  static const double _tooltipMinHeight = 160;
  static const double _highlightPadding = 4;

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
  }

  @override
  void didUpdateWidget(TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.step.step != widget.step.step) {
      _animationController.reset();
      _animationController.forward();
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
        children: [
          if (widget.step.targetKey != null)
            IgnorePointer(child: _buildHighlight(context)),

          if (widget.step.targetKey != null)
            _buildTooltipForTarget(context)
          else
            _buildFloatingTooltip(context),
        ],
      ),
    );
  }

  Widget _buildHighlight(BuildContext context) {
    final renderObject = widget.step.targetKey?.currentContext
        ?.findRenderObject();

    if (renderObject == null || renderObject is! RenderBox) {
      return _buildFloatingTooltip(context);
    }

    final targetSize = renderObject.size;
    final targetOffset = renderObject.localToGlobal(Offset.zero);

    return Stack(
      children: [
        Positioned(
          left: targetOffset.dx - _highlightPadding,
          top: targetOffset.dy - _highlightPadding,
          width: targetSize.width + (_highlightPadding * 2),
          height: targetSize.height + (_highlightPadding * 2),
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: AppStyle.theme.turnHighlight.withValues(alpha: .03),
                border: Border.all(
                  color: AppStyle.theme.turnHighlight,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(AppStyle.theme.radius),
                boxShadow: [
                  BoxShadow(
                    color: AppStyle.theme.turnHighlight.withValues(alpha: .28),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTooltipForTarget(BuildContext context) {
    final renderObject = widget.step.targetKey?.currentContext
        ?.findRenderObject();

    if (renderObject == null || renderObject is! RenderBox) {
      return _buildFloatingTooltip(context);
    }

    final targetSize = renderObject.size;
    final targetOffset = renderObject.localToGlobal(Offset.zero);

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    Offset tooltipOffset;

    // Above if lower half of screen
    if (targetOffset.dy > screenHeight * 0.5) {
      tooltipOffset = Offset(
        targetOffset.dx + targetSize.width / 2 - _tooltipWidth / 2,
        targetOffset.dy - _tooltipMinHeight - 45,
      );
    } else {
      // Below otherwise
      tooltipOffset = Offset(
        targetOffset.dx + targetSize.width / 2 - _tooltipWidth / 2,
        targetOffset.dy + targetSize.height + 30,
      );
    }

    // Clamp inside screen
    tooltipOffset = Offset(
      tooltipOffset.dx.clamp(12.0, screenWidth - _tooltipWidth - 12),
      tooltipOffset.dy.clamp(12.0, screenHeight - _tooltipMinHeight - 12),
    );

    return Positioned(
      left: tooltipOffset.dx,
      top: tooltipOffset.dy,
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
    final isLastStep = widget.currentStep == widget.totalSteps - 1;
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
              const Spacer(),
              Row(
                children: List.generate(widget.totalSteps, (index) {
                  final isCurrent = index == widget.currentStep;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isCurrent ? 14 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? theme.turnHighlight
                          : theme.muted.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
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
              if (widget.step.showSkipButton) ...[
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(theme.radius),
                    onPressed: widget.onSkip,
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
                        ? widget.step.onShow != null
                              ? () => widget.step.onShow!(context)
                              : widget.onNext
                        : null,
                    child: Text(
                      isLastStep ? 'Finish' : 'Next',
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
          ),
        ],
      ),
    );
  }
}
