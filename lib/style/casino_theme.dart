import 'dart:ui';

import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
class CasinoTheme extends AppTheme {
  @override
  double get radius => 12;

  @override
  Color get background => const Color(0xFF0D1B2A);
  @override
  Color get surface => const Color(0xFF1B263B);
  @override
  Color get surfaceRaised => const Color(0xFF22324B);
  @override
  Color get surfaceAlt => const Color(0xFF415A77);
  @override
  Color get textPrimary => const Color(0xFFE0E1DD);
  @override
  Color get muted => const Color(0xFF778DA9);
  @override
  Color get border => surfaceAlt.withValues(alpha:.55);

  // NEW accents
  @override
  Color get turnHighlight => const Color(0xFF2ECC71);
  @override
  Color get opponentHighlight => const Color(0xFFFFC857);
  @override
  Color get danger => const Color(0xFFC1121F);
  @override
  Color get warning => const Color(0xFFFFC857);
  @override
  Color get success => const Color(0xFF2ECC71);

  // Cards
  @override
  Color get cardBackground => const Color(0xFFFFFFFF);
  @override
  Color get cardBorder => const Color(0xFFCCCCCC);
  @override
  Color get suitRed => danger;
  @override
  Color get suitBlack => const Color(0xFF000000);

  @override
  BoxDecoration surfaceBox({Color? color}) => BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      );

  @override
  BoxDecoration raisedSurfaceBox({Color? color}) => BoxDecoration(
        color: color ?? surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha:.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      );

  @override
  BoxDecoration tableBackground() => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF0B1422), background],
        ),
      );

  @override
  BoxDecoration playerSectionBox({
    Color? highlightColor,
    bool highlight = false,
    bool joined = true,
  }) {
    final hc = (highlightColor ?? turnHighlight);

    return BoxDecoration(
      color: joined ? (highlight ? background : surface) : CupertinoColors.black.withValues(alpha:.12),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlight ? hc.withValues(alpha:.75) : border,
        width: highlight ? 2 : 1,
      ),
      boxShadow: highlight
          ? [
              BoxShadow(
                color: hc.withValues(alpha:.20),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ]
          : [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha:.20),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  @override
  TextStyle get title => TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      );

  @override
  TextStyle get body => TextStyle(color: textPrimary, fontSize: 14);

  @override
  TextStyle get mutedText => TextStyle(color: muted, fontSize: 13);

  @override
  TextStyle get caption => TextStyle(color: muted.withValues(alpha:.9), fontSize: 12);
}