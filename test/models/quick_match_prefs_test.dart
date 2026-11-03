import 'package:barajando/models/game_state.dart';
import 'package:barajando/models/quick_match_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const eligible = {GameMode.casino, GameMode.rummy};

  group('QuickMatchPrefs.sanitizedForMatchmaking', () {
    test('empty eligible modes clears selection', () {
      const prefs = QuickMatchPrefs(modes: [GameMode.casino]);
      final out = prefs.sanitizedForMatchmaking({});
      expect(out.modes, isEmpty);
    });

    test('anyMode expands to all eligible modes', () {
      const prefs = QuickMatchPrefs.defaults;
      final out = prefs.sanitizedForMatchmaking(eligible);
      expect(out.modes, containsAll(eligible));
      expect(out.modes.length, eligible.length);
    });

    test('strips ineligible modes and keeps eligible ones', () {
      const prefs = QuickMatchPrefs(
        modes: [GameMode.casino, GameMode.bs, GameMode.rummy],
      );
      final out = prefs.sanitizedForMatchmaking(eligible);
      expect(out.modes, [GameMode.casino, GameMode.rummy]);
    });

    test('falls back to all eligible when selection is fully locked', () {
      const prefs = QuickMatchPrefs(modes: [GameMode.bs]);
      final out = prefs.sanitizedForMatchmaking(eligible);
      expect(out.modes, containsAll(eligible));
    });
  });

  group('QuickMatchPrefs.effectiveModesFor', () {
    test('returns sanitized mode list', () {
      const prefs = QuickMatchPrefs(modes: [GameMode.casino, GameMode.bs]);
      expect(
        prefs.effectiveModesFor(eligible),
        [GameMode.casino],
      );
    });
  });
}
