import 'dart:async';

/// Revoke Apple’s token while the Firebase session is still valid, then
/// delete the auth user. A hung revoke must not block deletion.
Future<void> revokeAppleTokenThenDeleteUser({
  required Future<void> Function() revokeToken,
  required Future<void> Function() deleteUser,
  Duration revokeTimeout = const Duration(seconds: 15),
  void Function(Object error, StackTrace stackTrace)? onRevokeError,
}) async {
  try {
    await revokeToken().timeout(revokeTimeout);
  } catch (e, st) {
    onRevokeError?.call(e, st);
  }
  await deleteUser();
}
