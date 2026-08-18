import 'dart:math' as math;

import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Subtle continuous wave so a winning Tres y Dos hand reads as the 3+2.
class WinningHandWave extends StatefulWidget {
  const WinningHandWave({
    super.key,
    required this.active,
    required this.index,
    required this.child,
    this.amplitude = 3.5,
  });

  final bool active;
  final int index;
  final Widget child;
  final double amplitude;

  @override
  State<WinningHandWave> createState() => _WinningHandWaveState();
}

class _WinningHandWaveState extends State<WinningHandWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant WinningHandWave oldWidget) {
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
    final gold = AppStyle.theme.turnHighlight;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final phase = (_c.value * math.pi * 2) + widget.index * 0.4;
        return Transform.translate(
          offset: Offset(0, math.sin(phase) * widget.amplitude),
          child: Transform.rotate(
            angle: math.sin(phase) * 0.018,
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: gold.withValues(alpha: 0.28),
              blurRadius: 8,
              spreadRadius: 0.4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
