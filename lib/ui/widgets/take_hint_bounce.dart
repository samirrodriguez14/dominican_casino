import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

/// Occasional hop on a pile's top card. [slot] 0 then 1 so deck and
/// discard take turns instead of bouncing together.
class TakeHintBounce extends StatefulWidget {
  const TakeHintBounce({
    super.key,
    required this.active,
    required this.child,
    this.slot = 0,
  });

  final bool active;
  final Widget child;
  final int slot;

  @override
  State<TakeHintBounce> createState() => _TakeHintBounceState();
}

class _TakeHintBounceState extends State<TakeHintBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant TakeHintBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final lift = _liftFor(_c.value);
        if (lift == 0) return child!;
        return Transform.translate(
          offset: Offset(0, -8 * lift),
          child: child,
        );
      },
      child: widget.child,
    );
  }

  double _liftFor(double t) {
    const hop = 0.10;
    const gap = 0.12;
    final start = widget.slot * (hop + gap);
    final end = start + hop;
    if (t < start || t >= end) return 0;
    return math.sin(((t - start) / hop) * math.pi);
  }
}
