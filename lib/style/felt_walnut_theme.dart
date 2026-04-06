import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class FeltWalnutTheme extends AppTheme {
  @override
  double get radius => 12;
  @override
  String get appLogo => 'assets/images/logo_icon_wooden_transparent.png';

  @override
  String get cardBack => "assets/images/card_wood_back.png";
  // Base
  @override
  Color get background => const Color.fromARGB(255, 10, 41, 29);
  @override
  Color get surface => const Color.fromARGB(255, 49, 33, 27);
  @override
  Color get surfaceRaised => const Color.fromARGB(255, 54, 37, 29);
  @override
  Color get surfaceAlt => const Color.fromARGB(255, 93, 65, 49);
  @override
  Color get textPrimary => const Color(0xFFF3ECE2);
  @override
  Color get muted => const Color(0xFFC2B6A8);
  @override
  Color get border => const Color(0xFF5A4032);

  // Accents
  @override
  Color get turnHighlight => const Color.fromARGB(255, 151, 122, 47);
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
        Color.fromARGB(255, 32, 111, 81),
           Color.fromARGB(255, 10, 41, 29)],
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
      color: surface.withValues(alpha: .30),

      borderRadius: BorderRadius.circular(radius),

      border: Border.all(
        color: highlight
            ? hc.withValues(alpha: .25)
            : border.withValues(alpha: .25),
        width: 1,
      ),

      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          surfaceRaised.withValues(alpha: .22),
          surface.withValues(alpha: .12),
        ],
      ),

      boxShadow: [
        // Very soft depth
        BoxShadow(
          color: Colors.black.withValues(alpha: .12),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),

        // Turn glow but subtle
        if (highlight)
          BoxShadow(
            color: hc.withValues(alpha: .18),
            blurRadius: 14,
            spreadRadius: 0.5,
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
    color: border.withValues(alpha: .8),
    strokeWidth: 1.4,
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
