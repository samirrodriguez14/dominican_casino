import 'dart:ui';

import 'package:flutter/cupertino.dart';

abstract class AppTheme {
  double get radius;

  // Colors
  Color get background;
  Color get surface;
  Color get surfaceRaised;
  Color get surfaceAlt;
  Color get textPrimary;
  Color get muted;
  Color get border;

  // Decorations
  BoxDecoration surfaceBox();
  BoxDecoration raisedSurfaceBox();
  BoxDecoration tableBackground();
  BoxDecoration playerSectionBox({
    required Color highlightColor,
    bool highlight,
    bool joined,
  });

  // Text
  TextStyle get title;
  TextStyle get body;
  TextStyle get mutedText;
  TextStyle get caption;
}