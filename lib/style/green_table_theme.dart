import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GreenTableTheme extends AppTheme {
  @override
  double get radius => 14;

  // ---- Base colors ----
  @override
  Color get background => const Color(0xFF2F7A57); // main table green

  @override
  Color get surface => const Color(0xFFF6F3EA); // ivory panels

  @override
  Color get surfaceRaised => const Color(0xFFFFFFFF); // cards / elevated panels

  @override
  Color get surfaceAlt => const Color(0xFFE6E1D3); // secondary panel

  @override
  Color get textPrimary => const Color(0xFF1E1E1E);

  @override
  Color get muted => const Color(0xFF6E6E6E);

  @override
  Color get border => const Color(0xFFD4CDBF);

  // ---- Game / Card accents ----
  @override
  Color get turnHighlight => const Color(0xFFFFC857); // gold highlight

  @override
  Color get opponentHighlight => const Color(0xFF2C5E47);

  @override
  Color get danger => const Color(0xFFD94A4A);

  @override
  Color get warning => const Color(0xFFE7A93C);

  @override
  Color get success => const Color(0xFF2F9E66);

  // ---- Card colors ----
  @override
  Color get cardBackground => const Color(0xFFFFFFFF);

  @override
  Color get cardBorder => const Color(0xFFD7D0C2);

  @override
  Color get suitRed => const Color(0xFFC63D3D);

  @override
  Color get suitBlack => const Color(0xFF1A1A1A);

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
          blurRadius: 10,
          offset: Offset(0, 4),
        )
      ],
    );
  }

  @override
  BoxDecoration tableBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF348A63),
          Color(0xFF2F7A57),
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
      color: joined ? surface : surfaceAlt,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlight ? active : border,
        width: highlight ? 2 : 1,
      ),
      boxShadow: highlight
          ? [
              BoxShadow(
                color: active.withValues(alpha: .35),
                blurRadius: 12,
              )
            ]
          : [],
    );
  }

  // ---- Text ----
  @override
  TextStyle get title => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E1E1E),
      );

  @override
  TextStyle get body => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1E1E1E),
      );

  @override
  TextStyle get mutedText => const TextStyle(
        fontSize: 15,
        color: Color(0xFF6E6E6E),
      );

  @override
  TextStyle get caption => const TextStyle(
        fontSize: 13,
        color: Color(0xFF8B8B8B),
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
          color: color ?? border,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: child,
    );
  }
}