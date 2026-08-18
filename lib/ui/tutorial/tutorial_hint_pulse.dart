import 'dart:math' as math;

import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/tutorial_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Highlights a tutorial target: cards bounce, other areas breathe a glow.
class TutorialPulse extends StatelessWidget {
  const TutorialPulse({
    super.key,
    required this.child,
    this.cardId,
    this.stackId,
    this.targetKey,
    this.bounce = true,
  });

  final Widget child;
  final String? cardId;
  final String? stackId;
  final GlobalKey? targetKey;
  final bool bounce;

  @override
  Widget build(BuildContext context) {
    var active = false;
    try {
      active = context.watch<TutorialViewModel>().pulsesTarget(
        cardId: cardId,
        stackId: stackId,
        key: targetKey,
      );
    } on ProviderNotFoundException {
      active = false;
    }
    return TutorialHintPulse(
      active: active,
      bounce: bounce,
      child: child,
    );
  }
}

/// Soft glow, optionally with a small hop on cards.
class TutorialHintPulse extends StatefulWidget {
  const TutorialHintPulse({
    super.key,
    required this.active,
    required this.child,
    this.bounce = true,
  });

  final bool active;
  final bool bounce;
  final Widget child;

  @override
  State<TutorialHintPulse> createState() => _TutorialHintPulseState();
}

class _TutorialHintPulseState extends State<TutorialHintPulse>
    with SingleTickerProviderStateMixin {
  static const _bouncePeriod = Duration(milliseconds: 1600);
  static const _glowPeriod = Duration(milliseconds: 1800);

  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: widget.bounce ? _bouncePeriod : _glowPeriod,
    );
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant TutorialHintPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bounce != widget.bounce) {
      _c.duration = widget.bounce ? _bouncePeriod : _glowPeriod;
    }
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Slow ease in/out. `sin²` starts and ends at rest so the hop isn't snappy.
  double _hop(double t) {
    const hop = 0.48;
    if (t > hop) return 0;
    final s = math.sin((t / hop) * math.pi);
    return s * s;
  }

  double _breathe(double t) => 0.5 * (1 - math.cos(t * 2 * math.pi));

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    final glow = AppStyle.theme.turnHighlight;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        if (!widget.bounce) {
          final wave = _breathe(_c.value);
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.10 + 0.16 * wave),
                  blurRadius: 8 + 6 * wave,
                  spreadRadius: 0.2 + 0.6 * wave,
                ),
              ],
            ),
            child: child,
          );
        }

        final hop = _hop(_c.value);
        return Transform.translate(
          offset: Offset(0, -3.0 * hop),
          child: Transform.scale(
            scale: 1 + 0.016 * hop,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.16 + 0.08 * hop),
                    blurRadius: 7 + 3 * hop,
                    spreadRadius: 0.2 + 0.3 * hop,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
