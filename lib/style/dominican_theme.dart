import 'package:flutter/material.dart';
import 'app_theme.dart'; 
import 'package:flutter/cupertino.dart';

class DominicanTheme extends AppTheme {
  @override
  double get radius => 16;

  // ---- Base colors ----
  @override
  Color get background => const Color(0xFF0E4A86); // Dominican blue

  @override
  Color get surface => const Color(0xFFF6F1E7); // warm ivory

  @override
  Color get surfaceRaised => const Color(0xFFFFFBF5); // lighter card/panel

  @override
  Color get surfaceAlt => const Color(0xFFE8DCC7); // sand/beige accent surface

  @override
  Color get textPrimary => const Color(0xFF1A1A1A);

  @override
  Color get muted => const Color(0xFF6B6B6B);

  @override
  Color get border => const Color(0xFFD6C7AE);

  // ---- Game / Card accents ----
  @override
  Color get turnHighlight => const Color(0xFFD72638); // Dominican red

  @override
  Color get opponentHighlight => const Color(0xFFFFC857); // festive gold

  @override
  Color get danger => const Color(0xFFD93A49);

  @override
  Color get warning => const Color(0xFFF0A43A);

  @override
  Color get success => const Color(0xFF2F9E66);

  @override
  Color get xp => const Color(0xFFB48AE0);

  // ---- Card colors ----
  @override
  Color get cardBackground => const Color(0xFFFFFCF8);

  @override
  Color get cardBorder => const Color(0xFFD9CCBA);

  @override
  Color get suitRed => const Color(0xFFD72638);

  @override
  Color get suitBlack => const Color(0xFF1D2430);

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
          color: Color(0x22000000),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    );
  }

  @override
  BoxDecoration tableBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1565A9),
          Color(0xFF0E4A86),
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
    final active = highlightColor ?? turnHighlight;

    return BoxDecoration(
      color: joined ? surface : surfaceAlt.withValues(alpha: .8),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlight ? active : border,
        width: highlight ? 2.2 : 1.2,
      ),
      boxShadow: highlight
          ? [
              BoxShadow(
                color: active.withValues(alpha: .28),
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
        color: Color(0xFF1A1A1A),
      );

  @override
  TextStyle get body => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A1A),
      );

  @override
  TextStyle get mutedText => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color(0xFF6B6B6B),
      );

  @override
  TextStyle get caption => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Color(0xFF8A8278),
      );

  @override
  Widget dottedBox({
    required Widget child,
    Color? color,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: color ?? turnHighlight.withValues(alpha: .65),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}