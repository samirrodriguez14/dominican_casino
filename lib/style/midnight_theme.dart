import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class MidnightNeonTheme extends AppTheme {
  @override
  double get radius => 14;
  @override
  String get appLogo => 'assets/images/logo_icon_transparent.png';

  @override
  String get cardBack => "assets/images/card_back.png";
  // Base
  @override
  Color get background => const Color(0xFF070A12);
  @override
  Color get surface => const Color(0xFF0F1426);
  @override
  Color get surfaceRaised => const Color(0xFF141B33);
  @override
  Color get surfaceAlt => const Color(0xFF1E2A52);
  @override
  Color get textPrimary => const Color(0xFFEAF0FF);
  @override
  Color get muted => const Color(0xFF9AA7C7);
  @override
  Color get border => const Color(0xFF2A355F);

  // Accents (neon but tasteful)
  @override
  Color get turnHighlight => const Color(0xFF3DF2E5); // cyan neon
  @override
  Color get opponentHighlight => const Color(0xFFB06CFF); // purple neon
  @override
  Color get danger => const Color(0xFFFF4D6D);
  @override
  Color get warning => const Color(0xFFFFD166);
  @override
  Color get success => const Color(0xFF47F29A);

  // Cards
  @override
  Color get cardBackground => const Color(0xFFFDFBFF);
  @override
  Color get cardBorder => const Color(0xFFD2D6E6);
  @override
  Color get suitRed => danger;
  @override
  Color get suitBlack => const Color(0xFF121212);

  @override
  BoxDecoration surfaceBox({Color? color}) => BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border.withValues(alpha: .70)),
      );

  @override
  BoxDecoration raisedSurfaceBox({Color? color}) => BoxDecoration(
        color: color ?? surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border.withValues(alpha: .80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .55),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      );

  @override
  BoxDecoration tableBackground() => const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.35,
          colors: [
            Color(0xFF0E1633),
            Color(0xFF070A12),
          ],
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
      color: joined ? (highlight ? background : surface) : surface.withValues(alpha: .50),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlight ? hc.withValues(alpha: .85) : border.withValues(alpha: .70),
        width: highlight ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .55),
          blurRadius: 16,
          offset: const Offset(0, 9),
        ),
        if (highlight)
          BoxShadow(
            color: hc.withValues(alpha: .22),
            blurRadius: 26,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
      ],
    );
  }

  @override
  TextStyle get title => TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: .25,
      );

  @override
  TextStyle get body => TextStyle(color: textPrimary, fontSize: 14);

  @override
  TextStyle get mutedText => TextStyle(color: muted.withValues(alpha: .92), fontSize: 13);

  @override
  TextStyle get caption => TextStyle(color: muted.withValues(alpha: .85), fontSize: 12);

@override
Widget dottedBox({
  required Widget child,
  Color? color,
  EdgeInsets padding = const EdgeInsets.all(2),
}) {
  return DottedBorder(
    color: border.withValues(alpha: .8),
    strokeWidth: 1.8,
    dashPattern: const [4, 4],
    borderType: BorderType.RRect,
    radius: Radius.circular(radius),
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    ),
  );
}
}