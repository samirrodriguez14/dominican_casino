import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LightCasinoTheme extends AppTheme {
  @override
  double get radius => 14;

  @override
  String get appLogo => 'assets/images/logo_icon_transparent.png';

  @override
  String get cardBack => 'assets/images/card_back.png';

  // ---- Base colors ----
  @override
  Color get background => const Color(0xFFEAF4EE); // soft mint-white

  @override
  Color get surface => const Color(0xFFFFFFFF); // white panels

  @override
  Color get surfaceRaised => const Color(0xFFF7FBF8); // slightly raised white

  @override
  Color get surfaceAlt => const Color.fromARGB(255, 169, 207, 177); // muted green tint

  @override
  Color get textPrimary => const Color(0xFF1E2A24); // dark readable text

  @override
  Color get muted => const Color(0xFF6E7D74); // muted text

  @override
  Color get border => const Color(0xFFC7D8CC); // soft border

  // ---- Game / Card accents ----
  @override
  Color get turnHighlight => const Color(0xFF2E7D5A); // rich casino green

  @override
  Color get opponentHighlight => const Color(0xFFE3B341); // gold

  @override
  Color get danger => const Color(0xFFD9534F);

  @override
  Color get warning => const Color(0xFFF0AD4E);

  @override
  Color get success => const Color(0xFF3FAE6A);

  // ---- Card colors ----
  @override
  Color get cardBackground => const Color(0xFFFFFDF8);

  @override
  Color get cardBorder => const Color(0xFFD8CFC2);

  @override
  Color get suitRed => const Color(0xFFC63D3D);

  @override
  Color get suitBlack => const Color(0xFF1F1F1F);

  // ---- Decorations ----
  @override
  BoxDecoration surfaceBox({Color? color}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
    );
  }

  @override
  BoxDecoration raisedSurfaceBox({Color? color}) {
    return BoxDecoration(
      color: color ?? surfaceRaised,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  @override
  BoxDecoration tableBackground() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFEAF4EE),
          Color(0xFFDCEBDF),
        ],
      ),
    );
  }

  @override
  BoxDecoration playerSectionBox({
    Color? highlightColor,
    bool highlight = false,
    bool joined = true,
  }) {
    final activeColor = highlightColor ?? turnHighlight;

    return BoxDecoration(
      color: joined ? surface : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlight
            ? activeColor
            : joined
                ? border
                : const Color(0xFFD9D9D9),
        width: highlight ? 2 : 1,
      ),
      boxShadow: highlight
          ? [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.18),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ]
          : const [],
    );
  }

  // ---- Text ----
  @override
  TextStyle get title => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1E2A24),
  );

  @override
  TextStyle get body => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1E2A24),
  );

  @override
  TextStyle get mutedText => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6E7D74),
  );

  @override
  TextStyle get caption => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFF8C9A92),
  );

  @override
  Widget dottedBox({
    required Widget child,
    Color? color,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color ?? border,
        radius: radius,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}