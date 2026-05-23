import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dominican_casino/ui/walkthrough/walkthrough_step.dart';
import 'package:dominican_casino/style/app_theme.dart';

class GameWalkthroughOverlay extends StatefulWidget {
  final WalkthroughStep step;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentStep;
  final int totalSteps;

  const GameWalkthroughOverlay({
    super.key,
    required this.step,
    required this.onNext,
    required this.onSkip,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  State<GameWalkthroughOverlay> createState() => _GameWalkthroughOverlayState();
}

class _GameWalkthroughOverlayState extends State<GameWalkthroughOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const double _tooltipWidth = 300;
  static const double _tooltipMinHeight = 160;
  static const double _highlightPadding = 8;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(GameWalkthroughOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.step.stepNumber != widget.step.stepNumber) {
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onNext,
            child: Container(
              color: Colors.black.withValues(alpha: .62),
            ),
          ),

          if (widget.step.targetKey != null)
            _buildHighlight(context)
          else
            _buildFloatingTooltip(context),
        ],
      ),
    );
  }

  Widget _buildHighlight(BuildContext context) {
    final renderObject = widget.step.targetKey?.currentContext?.findRenderObject();

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
                color: AppStyle.theme.turnHighlight.withValues(alpha: .08),
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

        _buildTooltipWidget(context, targetOffset, targetSize),
      ],
    );
  }

  Widget _buildTooltipWidget(
    BuildContext context,
    Offset targetOffset,
    Size targetSize,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    Offset tooltipOffset;

    if (targetOffset.dy > screenHeight / 2) {
      tooltipOffset = Offset(
        targetOffset.dx + targetSize.width / 2 - _tooltipWidth / 2,
        targetOffset.dy - _tooltipMinHeight - 24,
      );
    } else {
      tooltipOffset = Offset(
        targetOffset.dx + targetSize.width / 2 - _tooltipWidth / 2,
        targetOffset.dy + targetSize.height + 24,
      );
    }

    tooltipOffset = Offset(
      tooltipOffset.dx.clamp(12, screenWidth - _tooltipWidth - 12),
      tooltipOffset.dy.clamp(12, screenHeight - _tooltipMinHeight - 12),
    );

    return Positioned(
      left: tooltipOffset.dx,
      top: tooltipOffset.dy,
      child: _buildTooltipContent(),
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
                children: List.generate(
                  widget.totalSteps,
                  (index) {
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
                  },
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

              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  color: theme.turnHighlight,
                  borderRadius: BorderRadius.circular(theme.radius),
                  onPressed: widget.onNext,
                  child: Text(
                    isLastStep ? 'Finish' : 'Next',
                    style: theme.body.copyWith(
                      color: theme.background,
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