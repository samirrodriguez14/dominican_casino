import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart'; // wherever your AppTheme abstract class lives

class WalnutTheme extends AppTheme {
  @override
  double get radius => 12;
  @override
  String get appLogo => 'assets/images/logo_icon_wooden_transparent.png';

  @override
  String get cardBack => "assets/images/card_wood_back.png";
  // ---- Base colors (Walnut) ----
  @override
  Color get background => const Color(0xFF1A120E); // deep walnut shadow
  @override
  Color get surface => const Color(0xFF231812); // main panel
  @override
  Color get surfaceRaised => const Color(0xFF2B1E16); // slightly raised
  @override
  Color get surfaceAlt => const Color(0xFF3A2A1F); // accents / buttons
  @override
  Color get textPrimary => const Color(0xFFF3E9DD); // warm off-white
  @override
  Color get muted => const Color(0xFFCDB8A3); // warm muted text
  @override
  Color get border => const Color(0xFF4B3526); // subtle wood edge

  // ---- Accents (better than green on wood) ----
  @override
  Color get turnHighlight => const Color(0xFFE6C36A); // warm gold
  @override
  Color get opponentHighlight => const Color(0xFFB7D6FF); // cool contrast option
  @override
  Color get danger => const Color(0xFFD1544A); // warm red
  @override
  Color get warning => const Color(0xFFE6C36A); // gold
  @override
  Color get success => const Color(0xFF86C29A); // muted green (not neon)

  // ---- Cards ----
  @override
  Color get cardBackground => const Color(0xFFFDFBF8);
  @override
  Color get cardBorder => const Color(0xFFD6C7B8);
  @override
  Color get suitRed => danger;
  @override
  Color get suitBlack => const Color(0xFF1A1A1A);

  // ---- Decorations ----
  @override
  BoxDecoration surfaceBox({Color? color}) => BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border.withValues(alpha: .65)),
      );

  @override
  BoxDecoration raisedSurfaceBox({Color? color}) => BoxDecoration(
        color: color ?? surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border.withValues(alpha: .75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .45),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      );

  /// Whole-app background: walnut + slight vignette (feels like a table)
  @override
  BoxDecoration tableBackground() => const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.3,
          colors: [
            Color(0xFF2A1D15), // lighter center
            Color(0xFF1A120E), // darker edges
          ],
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
      color: joined
          ? (highlight ? background : surface)
          : surface.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlight
            ? hc.withValues(alpha: .80)
            : border.withValues(alpha: .70),
        width: highlight ? 2 : 1,
      ),
      boxShadow: [
        // base shadow
        BoxShadow(
          color: Colors.black.withValues(alpha: .40),
          blurRadius: 12,
          offset: const Offset(0, 7),
        ),
        // warm glow when active turn
        if (highlight)
          BoxShadow(
            color: hc.withValues(alpha: .18),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
      ],
    );
  }

  // ---- Text ----
  @override
  TextStyle get title => TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: .2,
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
        strokeWidth: 1.4,
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