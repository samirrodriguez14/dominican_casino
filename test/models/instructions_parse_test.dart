import 'dart:convert';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final mode in GameMode.values) {
    if (mode == GameMode.robaito) {
      // still has assets
    }
    test('parse $mode en', () async {
      final base = switch (mode) {
        GameMode.tresydos => 'assets/config/tresydos_instructions',
        GameMode.rummy => 'assets/config/rummy_instructions',
        GameMode.robaito => 'assets/config/robaito_instructions',
        GameMode.casino => 'assets/config/casino_instructions',
        GameMode.casinoSpeed => 'assets/config/casino_speed_instructions',
        GameMode.bs => 'assets/config/bs_instructions',
      };
      for (final path in ['$base.json', '${base}_es.json']) {
        final raw = await rootBundle.loadString(path);
        final data = InstructionsData.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        expect(data.sections, isNotEmpty, reason: path);
        expect(data.title, isNotEmpty, reason: path);
      }
    });
  }
}
