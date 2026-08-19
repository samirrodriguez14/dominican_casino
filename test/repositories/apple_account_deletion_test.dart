import 'dart:async';

import 'package:dominican_casino/repositories/apple_account_deletion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('revokes Apple token before deleting the Firebase user', () async {
    final log = <String>[];
    await revokeAppleTokenThenDeleteUser(
      revokeToken: () async => log.add('revoke'),
      deleteUser: () async => log.add('delete'),
    );
    expect(log, ['revoke', 'delete']);
  });

  test('deletes the user even when Apple revoke hangs past the timeout', () async {
    final log = <String>[];
    Object? revokeError;
    await revokeAppleTokenThenDeleteUser(
      revokeToken: () => Completer<void>().future,
      deleteUser: () async => log.add('delete'),
      revokeTimeout: const Duration(milliseconds: 20),
      onRevokeError: (e, _) => revokeError = e,
    );
    expect(log, ['delete']);
    expect(revokeError, isA<TimeoutException>());
  });

  test('deletes the user when Apple revoke fails', () async {
    final log = <String>[];
    await revokeAppleTokenThenDeleteUser(
      revokeToken: () async => throw StateError('revoke-failed'),
      deleteUser: () async => log.add('delete'),
      onRevokeError: (e, _) => log.add('revoke-error'),
    );
    expect(log, ['revoke-error', 'delete']);
  });
}
