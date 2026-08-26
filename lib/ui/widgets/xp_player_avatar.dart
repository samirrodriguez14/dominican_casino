import 'dart:math' as math;

import 'package:dominican_casino/models/experience.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Shell avatar with an XP progress ring and level badge.
class XpPlayerAvatar extends StatefulWidget {
  const XpPlayerAvatar({
    super.key,
    required this.avatarId,
    this.size = 36,
  });

  final String? avatarId;
  final double size;

  static final targetKey = GlobalKey(debugLabel: 'xpAvatar');

  static Offset? get center {
    final box = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  State<XpPlayerAvatar> createState() => _XpPlayerAvatarState();
}

class _XpPlayerAvatarState extends State<XpPlayerAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _ring;
  double _shownProgress = 0;
  double _fromProgress = 0;
  double _toProgress = 0;
  int _shownLevel = 1;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addListener(() {
        setState(() {
          final t = Curves.easeOutCubic.transform(_ring.value);
          _shownProgress = _fromProgress + (_toProgress - _fromProgress) * t;
        });
      });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ring.dispose();
    super.dispose();
  }

  void _syncProgress(ExperienceProgress progress) {
    final levelChanged = progress.level != _shownLevel;
    final gained = progress.totalXp > 0 &&
        (progress.progress > _toProgress + 0.001 || levelChanged);
    if (levelChanged) {
      _shownLevel = progress.level;
      _fromProgress = 0;
      _shownProgress = 0;
    } else {
      _fromProgress = _shownProgress;
    }
    _toProgress = progress.progress;
    _ring.forward(from: 0);
    if (gained) {
      _pulse.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepo>();
    final progress = repo.experienceProgress;
    if (!_hydrated) {
      _hydrated = true;
      _shownLevel = progress.level;
      _shownProgress = _fromProgress = _toProgress = progress.progress;
    } else if (progress.level != _shownLevel ||
        (progress.progress - _toProgress).abs() > 0.001) {
      final snap = progress;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncProgress(snap);
      });
    }

    final theme = AppStyle.theme;
    final ringPad = (widget.size * 0.14).clamp(4.0, 6.0);
    final outer = widget.size + ringPad * 2;
    final badgeSize = (widget.size * 0.42).clamp(14.0, 18.0);

    return SizedBox(
      key: XpPlayerAvatar.targetKey,
      width: outer,
      height: outer,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_pulse.value.clamp(0.0, 1.0));
          final scale = 1.0 + (1.0 - t) * 0.08;
          return Transform.scale(scale: scale, child: child);
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(outer),
              painter: _XpRingPainter(
                progress: _shownProgress,
                color: theme.xp,
                strokeWidth: (widget.size * 0.08).clamp(2.4, 3.2),
              ),
            ),
            PlayerAvatarView(
              avatarId: widget.avatarId,
              size: widget.size,
              showBorder: false,
              showJourneyAces: true,
              defeatedAces: repo.journeyProgress.defeatedAceWorlds,
              wearJourneyAccessories: repo.wearJourneyAccessories,
            ),
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: badgeSize,
                  minHeight: badgeSize,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: theme.xp,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.background,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.28),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_shownLevel',
                  style: theme.caption.copyWith(
                    fontSize: (badgeSize * 0.55).clamp(9.0, 11.0),
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: const Color(0xFF1A1224),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpRingPainter extends CustomPainter {
  const _XpRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2 - 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = -math.pi / 2;
    final sweep = math.pi * 2 * progress.clamp(0.0, 1.0);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0.001) return;

    final cap = progress > 0.97 ? StrokeCap.butt : StrokeCap.round;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2.4
        ..strokeCap = cap
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
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
  }

  @override
  bool shouldRepaint(covariant _XpRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
