import 'package:dominican_casino/repositories/account_display_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appleFullName', () {
    test('joins given and family name', () {
      expect(
        appleFullName(givenName: 'Samir', familyName: 'Rodriguez'),
        'Samir Rodriguez',
      );
    });

    test('uses whichever part Apple sent', () {
      expect(appleFullName(givenName: 'Samir', familyName: '  '), 'Samir');
      expect(appleFullName(givenName: null, familyName: 'Rodriguez'), 'Rodriguez');
    });

    test('is null when Apple sent no name (returning authorization)', () {
      expect(appleFullName(givenName: '  ', familyName: null), isNull);
    });
  });

  group('playerDisplayName', () {
    test('uses Apple fallback when Firebase displayName is empty', () {
      expect(
        playerDisplayName(
          authDisplayName: '',
          fallback: 'Samir Rodriguez',
        ),
        'Samir',
      );
    });

    test('prefers a real auth displayName over fallback', () {
      expect(
        playerDisplayName(
          authDisplayName: 'Guest',
          fallback: 'Samir',
        ),
        'Guest',
      );
    });

    test('uses provider displayName when auth name is blank', () {
      expect(
        playerDisplayName(
          authDisplayName: ' ',
          providerDisplayName: 'Ana Perez',
        ),
        'Ana',
      );
    });

    test('truncates long first names to 10 characters', () {
      expect(
        playerDisplayName(fallback: 'Maximiliano Jose'),
        'Maximilian',
      );
    });
  });
}
