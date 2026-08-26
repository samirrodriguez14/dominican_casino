import 'dart:math' as math;

import 'package:dominican_casino/models/avatar_catalog.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter/cupertino.dart';

class AvatarOption {
  const AvatarOption({
    required this.id,
    required this.background,
    required this.foreground,
    required this.paint,
  });

  final String id;
  final Color background;
  final Color foreground;
  final void Function(Canvas canvas, Offset center, double radius, Color color)
  paint;
}

/// Simple painted avatars (sun, palm, suits, moon, star, acorn, leaf).
class PlayerAvatars {
  static const defaultId = AvatarCatalog.defaultId;

  static final List<AvatarOption> all = [
    AvatarOption(
      id: 'sun',
      background: const Color(0xFF6A5840),
      foreground: const Color(0xFFEDE4D0),
      paint: _paintSun,
    ),
    AvatarOption(
      id: 'palm',
      background: const Color(0xFF3A634F),
      foreground: const Color(0xFFE8F0E8),
      paint: _paintPalm,
    ),
    AvatarOption(
      id: 'heart',
      background: const Color(0xFF5A3A48),
      foreground: const Color(0xFFF4ECEC),
      paint: _paintHeart,
    ),
    AvatarOption(
      id: 'spade',
      background: const Color(0xFF3A5558),
      foreground: const Color(0xFFEEF3F2),
      paint: _paintSpade,
    ),
    AvatarOption(
      id: 'diamond',
      background: const Color(0xFF6B4336),
      foreground: const Color(0xFFD4A07A),
      paint: _paintDiamond,
    ),
    AvatarOption(
      id: 'club',
      background: const Color(0xFF3D4F48),
      foreground: const Color(0xFFF4F2EC),
      paint: _paintClub,
    ),
    AvatarOption(
      id: 'moon',
      background: const Color(0xFF3D4F58),
      foreground: const Color(0xFFE8D9A8),
      paint: _paintMoon,
    ),
    AvatarOption(
      id: 'star',
      background: const Color(0xFF3A634F),
      foreground: const Color(0xFFC4B07A),
      paint: _paintStar,
    ),
    AvatarOption(
      id: 'acorn',
      background: const Color(0xFF4A3D32),
      foreground: const Color(0xFFF3ECE2),
      paint: _paintAcorn,
    ),
    AvatarOption(
      id: 'leaf',
      background: const Color(0xFF3E4A38),
      foreground: const Color(0xFFE8D9A8),
      paint: _paintLeaf,
    ),
  ];

  static AvatarOption byId(String? id) {
    return all.firstWhere(
      (a) => a.id == id,
      orElse: () => all.firstWhere((a) => a.id == defaultId),
    );
  }
}

/// Scoreboard colors derived from a player's avatar.
class AvatarScoreTheme {
  const AvatarScoreTheme({
    required this.option,
    required this.background,
    required this.foreground,
    required this.ink,
    required this.muted,
    required this.panel,
    required this.border,
    required this.isLight,
  });

  factory AvatarScoreTheme.of(String? avatarId) {
    final option = PlayerAvatars.byId(paintedAvatarIdFor(avatarId));
    final background = option.background;
    final foreground = option.foreground;
    final isLight = background.computeLuminance() > 0.42;
    final ink = isLight ? const Color(0xFF1C1612) : const Color(0xFFF7F4EC);
    return AvatarScoreTheme(
      option: option,
      background: background,
      foreground: foreground,
      ink: ink,
      muted: ink.withValues(alpha: 0.68),
      panel: Color.lerp(
        background,
        isLight ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
        0.16,
      )!,
      border: Color.lerp(foreground, background, 0.18)!.withValues(alpha: 0.55),
      isLight: isLight,
    );
  }

  final AvatarOption option;
  final Color background;
  final Color foreground;
  final Color ink;
  final Color muted;
  final Color panel;
  final Color border;
  final bool isLight;
}

/// Pure avatar disc — no Provider / AppRepo. Looks up [AvatarCatalog].
class PlayerAvatarView extends StatelessWidget {
  const PlayerAvatarView({
    super.key,
    required this.avatarId,
    required this.size,
    this.avatarAsset,
    this.selected = false,
    this.showBorder = true,
    this.silhouette = false,
    this.showJourneyAces = false,
    this.defeatedAces,
    this.wearJourneyAccessories = true,
    this.onAceTap,
  });

  final String? avatarId;
  /// When set, shows this asset instead of the catalog / painted icon.
  final String? avatarAsset;
  final double size;
  final bool selected;
  final bool showBorder;
  final bool silhouette;
  /// When true and [defeatedAces] is non-empty (and wear is on), stacks Ace
  /// ornaments. Parents must pass data — this widget never reads AppRepo.
  final bool showJourneyAces;
  final Set<JourneyWorld>? defeatedAces;
  final bool wearJourneyAccessories;
  final ValueChanged<JourneyWorld>? onAceTap;

  @override
  Widget build(BuildContext context) {
    final look = AvatarLook.fromId(avatarId, assetOverride: avatarAsset);
    final option = PlayerAvatars.byId(look.paintedFallbackId);
    final ring = selected ? const Color(0xFFF4F2EC) : const Color(0x33000000);
    final asset = silhouette ? null : look.resolvedAssetPath;

    final disc = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(color: ring, width: selected ? 3 : 1.2)
              : null,
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .28),
              blurRadius: size * 0.12,
              offset: Offset(0, size * 0.06),
            ),
          ],
        ),
        child: ClipOval(
          child: asset != null && asset.isNotEmpty
              ? ColoredBox(
                  color: option.background,
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    width: size,
                    height: size,
                    alignment: Alignment.bottomCenter,
                    cacheWidth: (size * 3).ceil().clamp(48, 512),
                    errorBuilder: (_, _, _) => CustomPaint(
                      painter: _AvatarPainter(option, silhouette: silhouette),
                      size: Size.square(size),
                    ),
                  ),
                )
              : CustomPaint(
                  painter: _AvatarPainter(option, silhouette: silhouette),
                  size: Size.square(size),
                ),
        ),
      ),
    );

    if (!showJourneyAces) return disc;

    return AvatarAceOrnaments(
      size: size,
      defeatedAces: defeatedAces ?? const {},
      wear: wearJourneyAccessories,
      onAceTap: onAceTap,
      child: disc,
    );
  }
}

/// Props-only Ace trophy overlay. Parents supply [defeatedAces] / [wear].
class AvatarAceOrnaments extends StatelessWidget {
  const AvatarAceOrnaments({
    super.key,
    required this.child,
    required this.size,
    required this.defeatedAces,
    this.wear = true,
    this.onAceTap,
  });

  final Widget child;
  final double size;
  final Set<JourneyWorld> defeatedAces;
  final bool wear;
  final ValueChanged<JourneyWorld>? onAceTap;

  @override
  Widget build(BuildContext context) {
    if (!wear || defeatedAces.isEmpty) return child;

    final medallion = size * 0.28;
    Widget corner(
      JourneyWorld world, {
      required bool top,
      required bool bottom,
      required bool left,
      required bool right,
    }) {
      if (!defeatedAces.contains(world)) return const SizedBox.shrink();
      final badge = _AceSuitMedallion(world: world, size: medallion);
      return Positioned(
        top: top ? -medallion * 0.35 : null,
        bottom: bottom ? -medallion * 0.35 : null,
        left: left ? -medallion * 0.35 : null,
        right: right ? -medallion * 0.35 : null,
        child: onAceTap == null
            ? badge
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onAceTap!(world),
                child: badge,
              ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          child,
          corner(
            JourneyWorld.diamonds,
            top: true,
            bottom: false,
            left: false,
            right: false,
          ),
          corner(
            JourneyWorld.clubs,
            top: false,
            bottom: false,
            left: false,
            right: true,
          ),
          corner(
            JourneyWorld.hearts,
            top: false,
            bottom: true,
            left: false,
            right: false,
          ),
          corner(
            JourneyWorld.spades,
            top: false,
            bottom: false,
            left: true,
            right: false,
          ),
        ],
      ),
    );
  }
}

/// Ace challenger card art in a circular medallion (matches trophies popup).
class _AceSuitMedallion extends StatelessWidget {
  const _AceSuitMedallion({required this.world, required this.size});

  final JourneyWorld world;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(world);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surface,
        border: Border.all(
          color: palette.accent.withValues(alpha: .85),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          world.aceCardAssetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(color: palette.surface),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.option, {this.silhouette = false});

  final AvatarOption option;
  final bool silhouette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final background = silhouette
        ? const Color(0xFF2C2C2C)
        : option.background;
    final foreground = silhouette
        ? const Color(0xFF1A1A1A)
        : option.foreground;
    canvas.drawCircle(center, radius, Paint()..color = background);
    option.paint(canvas, center, radius * 0.58, foreground);
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.option.id != option.id ||
        oldDelegate.silhouette != silhouette;
  }
}

void _paintSun(Canvas canvas, Offset c, double r, Color color) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  canvas.drawCircle(c, r * 0.42, paint);
  final ray = Paint()
    ..color = color
    ..strokeWidth = r * 0.16
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4;
    final inner = Offset(
      c.dx + math.cos(a) * r * 0.58,
      c.dy + math.sin(a) * r * 0.58,
    );
    final outer = Offset(
      c.dx + math.cos(a) * r * 0.96,
      c.dy + math.sin(a) * r * 0.96,
    );
    canvas.drawLine(inner, outer, ray);
  }
}

void _paintPalm(Canvas canvas, Offset c, double r, Color color) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.28),
        width: r * 0.22,
        height: r * 1.15,
      ),
      Radius.circular(r * 0.1),
    ),
    paint,
  );
  for (final angle in [-1.15, -0.55, 0.0, 0.55, 1.15]) {
    canvas.save();
    canvas.translate(c.dx, c.dy - r * 0.18);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -r * 0.38),
        width: r * 0.38,
        height: r * 0.85,
      ),
      paint,
    );
    canvas.restore();
  }
}

void _paintHeart(Canvas canvas, Offset c, double r, Color color) {
  final path = Path()
    ..moveTo(c.dx, c.dy + r * 0.78)
    ..cubicTo(
      c.dx - r * 1.15,
      c.dy + r * 0.12,
      c.dx - r * 0.85,
      c.dy - r * 0.85,
      c.dx,
      c.dy - r * 0.22,
    )
    ..cubicTo(
      c.dx + r * 0.85,
      c.dy - r * 0.85,
      c.dx + r * 1.15,
      c.dy + r * 0.12,
      c.dx,
      c.dy + r * 0.78,
    );
  canvas.drawPath(path, Paint()..color = color);
}

void _paintSpade(Canvas canvas, Offset c, double r, Color color) {
  final paint = Paint()..color = color;
  final path = Path()
    ..moveTo(c.dx, c.dy - r * 0.92)
    ..cubicTo(
      c.dx - r * 1.15,
      c.dy - r * 0.05,
      c.dx - r * 0.7,
      c.dy + r * 0.55,
      c.dx,
      c.dy + r * 0.18,
    )
    ..cubicTo(
      c.dx + r * 0.7,
      c.dy + r * 0.55,
      c.dx + r * 1.15,
      c.dy - r * 0.05,
      c.dx,
      c.dy - r * 0.92,
    );
  canvas.drawPath(path, paint);
  final stem = Path()
    ..moveTo(c.dx, c.dy + r * 0.05)
    ..lineTo(c.dx - r * 0.38, c.dy + r * 0.92)
    ..lineTo(c.dx + r * 0.38, c.dy + r * 0.92)
    ..close();
  canvas.drawPath(stem, paint);
}

void _paintDiamond(Canvas canvas, Offset c, double r, Color color) {
  final path = Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + r * 0.72, c.dy)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - r * 0.72, c.dy)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}

void _paintClub(Canvas canvas, Offset c, double r, Color color) {
  final paint = Paint()..color = color;
  final lobe = r * 0.42;
  canvas.drawCircle(Offset(c.dx, c.dy - r * 0.38), lobe, paint);
  canvas.drawCircle(Offset(c.dx - r * 0.42, c.dy + r * 0.12), lobe, paint);
  canvas.drawCircle(Offset(c.dx + r * 0.42, c.dy + r * 0.12), lobe, paint);
  final stem = Path()
    ..moveTo(c.dx, c.dy)
    ..lineTo(c.dx - r * 0.32, c.dy + r * 0.95)
    ..lineTo(c.dx + r * 0.32, c.dy + r * 0.95)
    ..close();
  canvas.drawPath(stem, paint);
}

void _paintMoon(Canvas canvas, Offset c, double r, Color color) {
  final path = Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.92));
  final cut = Path()
    ..addOval(
      Rect.fromCircle(
        center: Offset(c.dx + r * 0.38, c.dy - r * 0.12),
        radius: r * 0.78,
      ),
    );
  canvas.drawPath(
    Path.combine(PathOperation.difference, path, cut),
    Paint()..color = color,
  );
}

void _paintStar(Canvas canvas, Offset c, double r, Color color) {
  const points = 5;
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final isOuter = i.isEven;
    final rr = isOuter ? r : r * 0.42;
    final a = -math.pi / 2 + i * math.pi / points;
    final p = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  canvas.drawPath(path, Paint()..color = color);
}

void _paintAcorn(Canvas canvas, Offset c, double r, Color color) {
  final paint = Paint()..color = color;
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(c.dx, c.dy + r * 0.22),
      width: r * 1.18,
      height: r * 1.22,
    ),
    paint,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy - r * 0.22),
        width: r * 1.42,
        height: r * 0.62,
      ),
      Radius.circular(r * 0.28),
    ),
    paint,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy - r * 0.72),
        width: r * 0.18,
        height: r * 0.42,
      ),
      Radius.circular(r * 0.08),
    ),
    paint,
  );
}

void _paintLeaf(Canvas canvas, Offset c, double r, Color color) {
  final paint = Paint()..color = color;
  final path = Path()
    ..moveTo(c.dx, c.dy - r)
    ..cubicTo(
      c.dx + r * 0.95,
      c.dy - r * 0.45,
      c.dx + r * 0.88,
      c.dy + r * 0.28,
      c.dx,
      c.dy + r * 0.78,
    )
    ..cubicTo(
      c.dx - r * 0.88,
      c.dy + r * 0.28,
      c.dx - r * 0.95,
      c.dy - r * 0.45,
      c.dx,
      c.dy - r,
    );
  canvas.drawPath(path, paint);
  final vein = Paint()
    ..color = color
    ..strokeWidth = r * 0.12
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
    Offset(c.dx, c.dy - r * 0.55),
    Offset(c.dx, c.dy + r * 0.98),
    vein,
  );
}
