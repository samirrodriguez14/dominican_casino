import 'package:flutter/material.dart';
import 'app_theme.dart';
class FeltWalnutTheme extends AppTheme {
  @override
  double get radius => 12;

  // Base
  @override
  Color get background => const Color(0xFF071C14);
  @override
  Color get surface => const Color(0xFF1F1511);
  @override
  Color get surfaceRaised => const Color(0xFF2A1D17);
  @override
  Color get surfaceAlt => const Color(0xFF4A3428);
  @override
  Color get textPrimary => const Color(0xFFF3ECE2);
  @override
  Color get muted => const Color(0xFFC2B6A8);
  @override
  Color get border => const Color(0xFF5A4032);

  // Accents
  @override
  Color get turnHighlight => const Color(0xFFE3BE63);
  @override
  Color get opponentHighlight => const Color(0xFF8CB7D9);
  @override
  Color get danger => const Color(0xFFB64136);
  @override
  Color get warning => const Color(0xFFE3BE63);
  @override
  Color get success => const Color(0xFF7DBA8A);

  // Cards
  @override
  Color get cardBackground => const Color(0xFFF8F3EA);
  @override
  Color get cardBorder => const Color(0xFFCDBFAE);
  @override
  Color get suitRed => const Color(0xFFB64136);
  @override
  Color get suitBlack => const Color(0xFF181512);

  @override
  BoxDecoration surfaceBox({Color? color}) => BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border.withValues(alpha: .75)),
      );

  @override
  BoxDecoration raisedSurfaceBox({Color? color}) => BoxDecoration(
        color: color ?? surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border.withValues(alpha: .85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .45),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      );

  @override
  BoxDecoration tableBackground() => const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.15),
          radius: 1.3,
          colors: [
            Color(0xFF114330),
            Color(0xFF071C14),
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

  // More “rail”, less “floating card”
  return BoxDecoration(
    // Joined vs not joined
    color: joined ? surface : surface.withValues(alpha: .45),

    borderRadius: BorderRadius.circular(radius),

    // Keep border subtle unless highlighted
    border: Border.all(
      color: highlight
          ? hc.withValues(alpha: .80)
          : border.withValues(alpha: .55),
      width: highlight ? 2 : 1,
    ),

    // Rail feel (top highlight -> darker bottom)
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        surfaceRaised.withValues(alpha: .98),
        surface.withValues(alpha: .98),
      ],
    ),

    boxShadow: [
      // Very subtle depth (avoid “floating panel”)
      BoxShadow(
        color: Colors.black.withValues(alpha: .22),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),

      // Subtle top edge sheen (feels like lacquer/rail)
      BoxShadow(
        color: Colors.white.withValues(alpha: .045),
        blurRadius: 4,
        offset: const Offset(0, -1.5),
        spreadRadius: -2,
      ),

      // Turn glow (soft, not neon)
      if (highlight)
        BoxShadow(
          color: hc.withValues(alpha: .16),
          blurRadius: 18,
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
        letterSpacing: .2,
      );

  @override
  TextStyle get body => TextStyle(
        color: textPrimary,
        fontSize: 14,
      );

  @override
  TextStyle get mutedText => TextStyle(
        color: muted.withValues(alpha: .92),
        fontSize: 13,
      );

  @override
  TextStyle get caption => TextStyle(
        color: muted.withValues(alpha: .85),
        fontSize: 12,
      );
}