import 'dart:async';
import 'dart:math' as math;

import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';

/// Overlay burst of currency icons flying into a target.
class CurrencyBurst {
  static Future<void> play({
    required BuildContext context,
    required Offset from,
    required Offset to,
    required IconData icon,
    required Color color,
    int count = 8,
    bool jump = false,
  }) async {
    if (!context.mounted || count <= 0) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final n = count;
    late OverlayEntry entry;
    final done = Completer<void>();

    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _BurstLayer(
          from: from,
          to: to,
          icon: icon,
          color: color,
          count: n,
          jump: jump,
          onDone: () {
            entry.remove();
            if (!done.isCompleted) done.complete();
          },
        ),
      ),
    );
    overlay.insert(entry);
    await done.future;
  }
}

class _BurstLayer extends StatefulWidget {
  const _BurstLayer({
    required this.from,
    required this.to,
    required this.icon,
    required this.color,
    required this.count,
    required this.jump,
    required this.onDone,
  });

  final Offset from;
  final Offset to;
  final IconData icon;
  final Color color;
  final int count;
  final bool jump;
  final VoidCallback onDone;

  @override
  State<_BurstLayer> createState() => _BurstLayerState();
}

class _BurstLayerState extends State<_BurstLayer>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _t;
  late final List<Offset> _control;
  Duration get _stagger {
    final base = widget.jump ? 55 : 42;
    if (widget.count <= 6) return Duration(milliseconds: base);
    final ms = (360 / widget.count).round().clamp(16, base);
    return Duration(milliseconds: ms);
  }

  Duration get _flight =>
      Duration(milliseconds: widget.jump ? 720 : 520);

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    final lift = widget.jump ? 110.0 : 40.0;
    final mid = Offset(
      (widget.from.dx + widget.to.dx) / 2,
      math.min(widget.from.dy, widget.to.dy) - lift - rnd.nextDouble() * 36,
    );
    _controllers = List.generate(widget.count, (i) {
      return AnimationController(vsync: this, duration: _flight);
    });
    _t = _controllers
        .map(
          (c) => CurvedAnimation(
            parent: c,
            curve: widget.jump ? Curves.easeInOutCubic : Curves.easeInCubic,
          ),
        )
        .toList();
    _control = List.generate(widget.count, (i) {
      final spread = (i - (widget.count - 1) / 2) * (widget.jump ? 26 : 18);
      return mid + Offset(spread + (rnd.nextDouble() - 0.5) * 24, 0);
    });

    _run();
  }

  Future<void> _run() async {
    for (var i = 0; i < _controllers.length; i++) {
      if (!mounted) return;
      AppHaptics.selectionClick();
      SoundService.instance.playLayered(
        GameSound.coin,
        volume: i == 0 ? 1 : 0.62,
      );
      unawaited(_controllers[i].forward());
      await Future<void>.delayed(_stagger);
    }
    await Future.wait(
      _controllers.map((c) => c.forward()),
    );
    if (!mounted) return;
    AppHaptics.mediumImpact();
    widget.onDone();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < widget.count; i++)
          AnimatedBuilder(
            animation: _t[i],
            builder: (context, child) {
              final t = _t[i].value;
              final pos = _quad(widget.from, _control[i], widget.to, t);
              final hop = math.sin(t * math.pi);
              final scale = widget.jump
                  ? 0.9 + hop * 0.7
                  : 1.15 - 0.45 * t;
              final opacity = t < 0.88 ? 1.0 : (1 - t) / 0.12;
              final angle = widget.jump
                  ? (1 - t) * 0.55 * (i.isEven ? 1 : -1)
                  : 0.0;
              return Positioned(
                left: pos.dx - 14,
                top: pos.dy - 14,
                child: Opacity(
                  opacity: opacity.clamp(0, 1),
                  child: Transform.rotate(
                    angle: angle,
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: Icon(widget.icon, size: widget.jump ? 28 : 24, color: widget.color),
          ),
      ],
    );
  }
}
