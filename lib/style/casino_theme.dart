import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Diamonds world — ambition / greed. Plum + champagne gold.
class ClayTheme extends AppTheme {
  @override
  double get radius => 14;

  @override
  Color get background => const Color(0xFF1D141D);

  @override
  Color get surface => const Color(0xFF4B3046);

  @override
  Color get surfaceRaised => const Color(0xFF5A3A52);

  @override
  Color get surfaceAlt => const Color(0xFF76556F);

  @override
  Color get textPrimary => const Color(0xFFF4EEE5);

  @override
  Color get muted => const Color(0xFFC4B0B8);

  @override
  Color get border => const Color(0xFF76556F);

  @override
  Color get turnHighlight => const Color(0xFFC9A568);

  @override
  Color get opponentHighlight => const Color(0xFFB898A8);

  @override
  Color get danger => const Color(0xFFC45C55);

  @override
  Color get warning => const Color(0xFFC9A568);

  @override
  Color get success => const Color(0xFF9A7A86);

  @override
  Color get xp => const Color(0xFFB48AE0);

  @override
  Color get cardBackground => const Color(0xFFF7F2EC);

  @override
  Color get cardBorder => const Color(0xFFD4C4C0);

  @override
  Color get suitRed => const Color(0xFFC45C55);

  @override
  Color get suitBlack => const Color(0xFF1D141D);

  @override
  Color get pickerFace => const Color(0xFF4B3046);

  @override
  Color get pickerFaceAlt => const Color(0xFF3A2438);

  @override
  Color get pickerFaceEdge => const Color(0xFF76556F);

  @override
  BoxDecoration surfaceBox({Color? color}) => BoxDecoration(
    color: color ?? surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border.withValues(alpha: .55)),
  );

  @override
  BoxDecoration raisedSurfaceBox({Color? color}) => BoxDecoration(
    color: color ?? surfaceRaised,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border.withValues(alpha: .45)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .28),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );

  @override
  BoxDecoration tableBackground() => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0, -0.12),
      radius: 1.25,
      colors: [Color(0xFF3A2438), Color(0xFF1D141D)],
    ),
  );

  @override
  BoxDecoration playerSectionBox({
    Color? highlightColor,
    bool highlight = false,
    bool joined = true,
  }) {
    final hc = highlightColor ?? turnHighlight;

    return BoxDecoration(
      color: surface.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlight
            ? hc.withValues(alpha: .35)
            : border.withValues(alpha: .35),
        width: 1,
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          surfaceRaised.withValues(alpha: .28),
          surface.withValues(alpha: .14),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .12),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        if (highlight)
          BoxShadow(
            color: hc.withValues(alpha: .16),
            blurRadius: 14,
            spreadRadius: 0.5,
          ),
      ],
    );
  }

  @override
  TextStyle get title => TextStyle(
    color: textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    letterSpacing: .15,
  );

  @override
  TextStyle get body => TextStyle(color: textPrimary, fontSize: 14);

  @override
  TextStyle get mutedText =>
      TextStyle(color: muted.withValues(alpha: .92), fontSize: 13);

  @override
  TextStyle get caption =>
      TextStyle(color: muted.withValues(alpha: .85), fontSize: 12);

  @override
  Widget dottedBox({
    required Widget child,
    Color? color,
    EdgeInsets padding = const EdgeInsets.all(2),
  }) {
    return DottedBorder(
      color: border.withValues(alpha: .7),
      strokeWidth: 1.2,
      dashPattern: const [4, 4],
      borderType: BorderType.RRect,
      radius: Radius.circular(radius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}
