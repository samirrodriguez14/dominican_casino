import 'package:dominican_casino/style/app_theme.dart';
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
  TextStyle get title =>
      TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16);

  @override
  TextStyle get body => TextStyle(color: textPrimary, fontSize: 14);

  @override
  TextStyle get mutedText => TextStyle(color: muted, fontSize: 13);

  @override
  TextStyle get caption =>
      TextStyle(color: muted.withValues(alpha:(.9)), fontSize: 12);
      
        @override
        // TODO: implement cardBackground
        Color get cardBackground => throw UnimplementedError();
      
        @override
        // TODO: implement cardBorder
        Color get cardBorder => throw UnimplementedError();
      
        @override
        // TODO: implement danger
        Color get danger => throw UnimplementedError();
      
        @override
        // TODO: implement opponentHighlight
        Color get opponentHighlight => throw UnimplementedError();
      
        @override
        // TODO: implement success
        Color get success => throw UnimplementedError();
      
        @override
        // TODO: implement suitBlack
        Color get suitBlack => throw UnimplementedError();
      
        @override
        // TODO: implement suitRed
        Color get suitRed => throw UnimplementedError();
      
        @override
        // TODO: implement turnHighlight
        Color get turnHighlight => throw UnimplementedError();
      
        @override
        // TODO: implement warning
        Color get warning => throw UnimplementedError();
        
          @override
          BoxDecoration playerSectionBox({Color? highlightColor, bool highlight = false, bool joined = true}) {
            // TODO: implement playerSectionBox
            throw UnimplementedError();
          }
          
            @override
            BoxDecoration raisedSurfaceBox({Color? color}) {
              // TODO: implement raisedSurfaceBox
              throw UnimplementedError();
            }
          
            @override
            BoxDecoration surfaceBox({Color? color}) {
              // TODO: implement surfaceBox
              throw UnimplementedError();
            }
}