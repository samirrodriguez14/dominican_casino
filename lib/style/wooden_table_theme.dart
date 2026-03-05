import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WoodenTableTheme extends AppTheme {
  @override
  double get radius => 10;

  @override
  Color get background => const Color(0xFF5A341D);

  @override
  Color get surface => const Color(0xFF7B4B2A);

  @override
  Color get surfaceRaised => const Color(0xFF8C5A34);

  @override
  Color get surfaceAlt => const Color(0xFFA47148);

  @override
  Color get textPrimary => Colors.white;

  @override
  Color get muted => const Color(0xFFD7B899);

  @override
  Color get border => const Color(0xFF3A2314);

  @override
  BoxDecoration surfaceBox() {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
    );
  }

  @override
  BoxDecoration raisedSurfaceBox() {
    return BoxDecoration(
      color: surfaceRaised,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.35),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  @override
  BoxDecoration tableBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF7B4B2A),
          Color(0xFF5A341D),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  @override
  BoxDecoration playerSectionBox({
    required Color highlightColor,
    bool highlight = false,
    bool joined = true,
  }) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlight ? highlightColor : border,
        width: highlight ? 2 : 1,
      ),
    );
  }

  @override
  TextStyle get title =>
      TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16);

  @override
  TextStyle get body => TextStyle(color: textPrimary, fontSize: 14);

  @override
  TextStyle get mutedText => TextStyle(color: muted, fontSize: 13);

  @override
  TextStyle get caption =>
      TextStyle(color: muted.withOpacity(.9), fontSize: 12);
}