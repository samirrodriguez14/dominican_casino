import 'dart:math' as math;

import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Subtle wave for a winning Tres y Dos hand, or a one-shot bounce nudge.
class WinningHandWave extends StatefulWidget {
  const WinningHandWave({
    super.key,
    required this.active,
    required this.index,
    required this.child,
    this.amplitude = 3.5,
    this.glow = true,
    this.period = const Duration(milliseconds: 1600),
    /// When true: cards hop once in a left→right wave, rest, then hop again.
    this.pulse = false,
  });

  final bool active;
  final int index;
  final Widget child;
  final double amplitude;
  final bool glow;
  final Duration period;
  final bool pulse;

  @override
  State<WinningHandWave> createState() => _WinningHandWaveState();
}

class _WinningHandWaveState extends State<WinningHandWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  double _prevHop = 0;
  bool _hapticArmed = true;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: widget.period,
    );
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant WinningHandWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period) {
      _c.duration = widget.period;
    }
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
      _prevHop = 0;
      _hapticArmed = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _hop(double t) {
    if (!widget.pulse) {
      final phase = (t * math.pi * 2) + widget.index * 0.4;
      return math.sin(phase);
    }
    // Bounce window leaves ~half the cycle at rest.
    const bounceEnd = 0.5;
    if (t >= bounceEnd) return 0;
    final start = (widget.index * 0.038).clamp(0.0, 0.18);
    final span = (bounceEnd - start).clamp(0.14, bounceEnd);
    final local = ((t - start) / span).clamp(0.0, 1.0);
    if (local <= 0 || local >= 1) return 0;
    return _softDoubleBounce(local);
  }

  /// Main hop (softer), then a smaller settle bounce that ends at rest.
  double _softDoubleBounce(double local) {
    double arc(double x) {
      if (x <= 0 || x >= 1) return 0;
      return math.sin(x * math.pi);
    }

    if (local < 0.62) return arc(local / 0.62) * 0.7;
    return arc((local - 0.62) / 0.38) * 0.28;
  }

  void _tickHaptic(double hop) {
    if (!widget.pulse) return;
    // Rising edge of each bounce (main + settle) → one light tap per card.
    if (_hapticArmed && hop > 0.12 && _prevHop <= 0.12) {
      _hapticArmed = false;
      AppHaptics.selectionClick();
    }
    if (hop < 0.04) _hapticArmed = true;
    _prevHop = hop;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    final gold = AppStyle.theme.turnHighlight;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = widget.pulse
            ? (DateTime.now().millisecondsSinceEpoch %
                    widget.period.inMilliseconds) /
                widget.period.inMilliseconds
            : _c.value;
        final hop = _hop(t);
        _tickHaptic(hop);
        return Transform.translate(
          offset: Offset(0, -hop * widget.amplitude),
          child: Transform.rotate(
            angle: hop * 0.018,
            child: child,
          ),
        );
      },
      child: widget.glow
          ? DecoratedBox(
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
            )
          : widget.child,
    );
  }
}
