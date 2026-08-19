import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

/// Short particle burst for round-win celebrations.
class WinConfettiOverlay extends StatefulWidget {
  const WinConfettiOverlay({
    super.key,
    required this.originFraction,
  });

  /// Origin of the confetti burst within this widget, as a fraction of width/height.
  /// (0,0)=top-left, (1,1)=bottom-right.
  final Offset originFraction;

  @override
  State<WinConfettiOverlay> createState() => _WinConfettiOverlayState();
}

class _WinConfettiOverlayState extends State<WinConfettiOverlay>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFFE8C547),
    Color(0xFF5BC4A8),
    Color(0xFFE86B6B),
    Color(0xFF7EB6FF),
    Color(0xFFD4A5FF),
  ];

  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..forward();
    _particles = List.generate(64, (_) => _ConfettiParticle.random(_rng));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              originFraction: widget.originFraction,
              progress: _controller.value,
              particles: _particles,
              colors: _colors,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.originXOffset,
    required this.originYOffset,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.size,
    required this.colorIndex,
  });

  final double originXOffset;
  final double originYOffset;
  final double vx;
  final double vy;
  final double spin;
  final double size;
  final int colorIndex;

  factory _ConfettiParticle.random(math.Random rng) {
    // Firework-ish: strong outward burst + upward initial velocity.
    final angle = rng.nextDouble() * math.pi * 2;
    final speed = 0.16 + rng.nextDouble() * 0.65; // fraction-per-t
    return _ConfettiParticle(
      // Small jitter around the supplied origin.
      originXOffset: (rng.nextDouble() - 0.5) * 0.06,
      originYOffset: (rng.nextDouble() - 0.5) * 0.06,
      vx: math.cos(angle) * speed,
      // Negative y is "up" in our canvas math.
      vy: -0.55 * speed - (0.08 + rng.nextDouble() * 0.18),
      spin: (rng.nextDouble() - 0.5) * 8,
      size: 4 + rng.nextDouble() * 5,
      colorIndex: rng.nextInt(5),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.originFraction,
    required this.progress,
    required this.particles,
    required this.colors,
  });

  final Offset originFraction;
  final double progress;
  final List<_ConfettiParticle> particles;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    // Pop bright quickly, then fade out.
    final pop = progress < 0.18 ? (progress / 0.18) : 1.0;
    final tail = progress > 0.65 ? (1 - progress) / 0.35 : 1.0;
    final alpha = pop * tail;
    if (alpha <= 0) return;

    for (final p in particles) {
      final t = progress;
      final x =
          (originFraction.dx + p.originXOffset + p.vx * t) * size.width;
      // Add a gravity term so it arcs back down like a firework tail.
      final y = (originFraction.dy +
              p.originYOffset +
              p.vy * t +
              0.42 * t * t) *
          size.height;
      final paint = Paint()
        ..color = colors[p.colorIndex % colors.length].withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: (p.size * (1 - 0.35 * t)).clamp(0.0, p.size),
            height: ((p.size * 0.55) * (1 - 0.25 * t)).clamp(0.0, 999),
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
