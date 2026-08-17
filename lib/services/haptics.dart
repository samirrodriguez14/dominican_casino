import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/services.dart';

/// Haptic helpers that honor the settings switch.
class AppHaptics {
  static bool get enabled => SoundService.instance.hapticEnabled;

  static Future<void> selectionClick() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> lightImpact() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> mediumImpact() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavyImpact() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }
}
