import 'dart:math' as math;

import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/coin_gain_badge.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

/// Avatar with match score at the top-left and pending coins at the bottom-right.
class PlayerScoreAvatar extends StatelessWidget {
  const PlayerScoreAvatar({
    super.key,
    required this.avatarId,
    required this.score,
    required this.pendingCoins,
    this.name,
    this.onPressed,
    this.size = 64,
    this.isTurn = false,
    this.isOpen = false,
    this.turnDeadline,
    this.turnTotal,
  });

  final String? avatarId;
  final dynamic score;
  final int pendingCoins;
  final String? name;
  final VoidCallback? onPressed;
  final double size;
  final bool isTurn;
  final bool isOpen;

  /// Remaining time is drawn as a ring around this seat.
  final DateTime? turnDeadline;
  final Duration? turnTotal;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    if (isOpen) return _openSeat(theme);

    final chipSize = size < 52 ? 10.0 : 11.0;
    final timed = turnDeadline != null && turnTotal != null;
    final gold = theme.turnHighlight;
    final avatar = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _TurnHalo(
            active: isTurn && !timed,
            size: size,
            color: gold,
            child: timed
                ? _TurnCountdownRing(
                    deadline: turnDeadline!,
                    total: turnTotal!,
                    size: size,
                    color: gold,
                    danger: theme.danger,
                    child: _avatarDisc(
                      theme: theme,
                      gold: gold,
                      timed: true,
                      discSize: size - (size * 0.2).clamp(11.0, 14.0),
                    ),
                  )
                : _avatarDisc(
                    theme: theme,
                    gold: gold,
                    timed: false,
                  ),
          ),
          Positioned(
            left: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isTurn ? gold : theme.surfaceAlt,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.background, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '$score',
                style: theme.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isTurn ? theme.background : theme.textPrimary,
                  fontSize: chipSize,
                ),
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -2,
            child: CoinGainBadge(pending: pendingCoins, compact: size < 56),
          ),
        ],
      ),
    );

    final label = name?.trim();
    final body = (label == null || label.isEmpty)
        ? avatar
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(height: 4),
              SizedBox(
                width: size + 20,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isTurn ? gold : theme.textPrimary,
                    fontSize: size < 52 ? 9.5 : 11,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          );

    if (onPressed == null) return body;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onPressed!),
      child: body,
    );
  }

  Widget _openSeat(AppTheme theme) {
    final iconSize = size < 52 ? 18.0 : 24.0;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.surfaceAlt.withValues(alpha: .4),
        border: Border.all(
          color: theme.muted.withValues(alpha: .5),
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        CupertinoIcons.person,
        size: iconSize,
        color: theme.muted.withValues(alpha: .85),
      ),
    );
    final label = name?.trim();
    if (label == null || label.isEmpty) return avatar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: 4),
        SizedBox(
          width: size + 20,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.muted,
              fontSize: size < 52 ? 9.5 : 11,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarDisc({
    required AppTheme theme,
    required Color gold,
    required bool timed,
    double? discSize,
  }) {
    final s = discSize ?? size;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: timed
              ? theme.background
              : isTurn
                  ? gold
                  : theme.textPrimary.withValues(alpha: .18),
          width: timed ? 1.6 : (isTurn ? 2.4 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: timed ? .4 : .28),
            blurRadius: s * 0.18,
            offset: Offset(0, s * 0.09),
          ),
        ],
      ),
      child: PlayerAvatarView(
        avatarId: avatarId,
        size: s,
        showBorder: false,
      ),
    );
  }
}

class _TurnHalo extends StatefulWidget {
  const _TurnHalo({
    required this.active,
    required this.size,
    required this.color,
    required this.child,
  });

  final bool active;
  final double size;
  final Color color;
  final Widget child;

  @override
  State<_TurnHalo> createState() => _TurnHaloState();
}

class _TurnHaloState extends State<_TurnHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant _TurnHalo oldWidget) {
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
        final t = (math.sin(_c.value * math.pi * 2) + 1) / 2;
        final glow = 0.22 + t * 0.38;
        final spread = 1.0 + t * 2.2;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: glow),
                blurRadius: widget.size * 0.32,
                spreadRadius: spread,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _TurnCountdownRing extends StatefulWidget {
  const _TurnCountdownRing({
    required this.deadline,
    required this.total,
    required this.size,
    required this.color,
    required this.danger,
    required this.child,
  });

  final DateTime deadline;
  final Duration total;
  final double size;
  final Color color;
  final Color danger;
  final Widget child;

  @override
  State<_TurnCountdownRing> createState() => _TurnCountdownRingState();
}

class _TurnCountdownRingState extends State<_TurnCountdownRing>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (!mounted) return;
      setState(() {});
      if (_remaining <= 0) _ticker.stop();
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TurnCountdownRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deadline != oldWidget.deadline && !_ticker.isTicking) {
      _ticker.start();
    }
  }

  double get _remaining {
    final totalMs = widget.total.inMilliseconds;
    if (totalMs <= 0) return 0;
    final left = widget.deadline.difference(DateTime.now()).inMilliseconds;
    return (left / totalMs).clamp(0.0, 1.0);
  }

  Color get _ringColor {
    final t = _remaining;
    if (t > 0.42) return widget.color;
    if (t > 0.18) {
      return Color.lerp(
        const Color(0xFFE8A04A),
        widget.color,
        (t - 0.18) / 0.24,
      )!;
    }
    return Color.lerp(widget.danger, const Color(0xFFE8A04A), t / 0.18)!;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final urgent = remaining <= 0.22 && remaining > 0;
    final pulse = urgent
        ? 0.55 + 0.45 * (0.5 + 0.5 * math.sin(
            DateTime.now().millisecondsSinceEpoch / 160,
          ))
        : 1.0;
    final color = _ringColor;
    final stroke = (widget.size * 0.085).clamp(3.2, 4.6);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _CountdownRingPainter(
                progress: remaining,
                color: color,
                strokeWidth: stroke,
                glowStrength: pulse,
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.glowStrength,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final double glowStrength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2 - 0.6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = -math.pi / 2;
    final sweep = math.pi * 2 * progress;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xCC111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2.2,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth - 0.8,
    );

    if (progress <= 0) return;

    final cap = progress > 0.97 ? StrokeCap.butt : StrokeCap.round;

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.28 * glowStrength)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 5.5
        ..strokeCap = cap
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
    );
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = cap,
    );
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = Color.lerp(color, const Color(0xFFFFFFFF), 0.38)!
            .withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (strokeWidth * 0.38).clamp(1.1, 1.8)
        ..strokeCap = cap,
    );

    if (progress >= 0.985) return;

    final end = start + sweep;
    final bead = Offset(
      center.dx + radius * math.cos(end),
      center.dy + radius * math.sin(end),
    );
    canvas.drawCircle(
      bead,
      strokeWidth * 0.92,
      Paint()
        ..color = color.withValues(alpha: 0.45 * glowStrength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
    );
    canvas.drawCircle(bead, strokeWidth * 0.62, Paint()..color = color);
    canvas.drawCircle(
      bead,
      strokeWidth * 0.28,
      Paint()..color = const Color(0xF2FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.glowStrength != glowStrength;
  }
}
