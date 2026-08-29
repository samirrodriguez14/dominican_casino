import 'dart:async';
import 'dart:math' as math;

import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';

/// Flies a gift widget into the Profile tab (then the tab "eats" it).
class ProfileGiftFlight {
  static Future<void> play({
    required BuildContext context,
    required Offset from,
    required Offset to,
    required Widget child,
    VoidCallback? onNearLanding,
    Duration duration = const Duration(milliseconds: 780),
  }) async {
    if (!context.mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    final done = Completer<void>();

    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _GiftFlightLayer(
          from: from,
          to: to,
          duration: duration,
          onNearLanding: onNearLanding,
          onDone: () {
            entry.remove();
            if (!done.isCompleted) done.complete();
          },
          child: child,
        ),
      ),
    );
    overlay.insert(entry);
    await done.future;
  }
}

class _GiftFlightLayer extends StatefulWidget {
  const _GiftFlightLayer({
    required this.from,
    required this.to,
    required this.duration,
    required this.onDone,
    required this.child,
    this.onNearLanding,
  });

  final Offset from;
  final Offset to;
  final Duration duration;
  final VoidCallback onDone;
  final VoidCallback? onNearLanding;
  final Widget child;

  @override
  State<_GiftFlightLayer> createState() => _GiftFlightLayerState();
}

class _GiftFlightLayerState extends State<_GiftFlightLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;
  late final Offset _control;
  bool _landedPulse = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _t = CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);
    final midX = (widget.from.dx + widget.to.dx) / 2;
    final lift = math.min(widget.from.dy, widget.to.dy) - 120;
    _control = Offset(midX, lift);
    _c.addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _onTick() {
    if (_landedPulse || _t.value < 0.82) return;
    _landedPulse = true;
    AppHaptics.mediumImpact();
    SoundService.instance.play(GameSound.deal);
    widget.onNearLanding?.call();
  }

  Future<void> _run() async {
    AppHaptics.selectionClick();
    SoundService.instance.play(GameSound.deal);
    await _c.forward();
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.removeListener(_onTick);
    _c.dispose();
    super.dispose();
  }

  Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final t = _t.value;
        final pos = _quad(widget.from, _control, widget.to, t);
        final hop = math.sin(t * math.pi);
        final scale = (1.05 + hop * 0.18) * (1.0 - 0.72 * t);
        final opacity = t < 0.9 ? 1.0 : ((1 - t) / 0.1).clamp(0.0, 1.0);
        final angle = (1 - t) * 0.35;
        return Stack(
          children: [
            Positioned(
              left: pos.dx - 40,
              top: pos.dy - 52,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                    scale: scale.clamp(0.15, 1.3),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
