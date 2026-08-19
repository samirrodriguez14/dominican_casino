/// First-time Sign in with Apple includes given/family name; later auths do not.
String? appleFullName({String? givenName, String? familyName}) {
  final parts = <String>[
    ?givenName?.trim(),
    ?familyName?.trim(),
  ].where((part) => part.isNotEmpty);
  if (parts.isEmpty) return null;
  return parts.join(' ');
}

/// In-game names are a short first word. Skip blank auth values so Apple/Google
/// names still apply when Firebase stores an empty displayName.
String? playerDisplayName({
  String? authDisplayName,
  String? providerDisplayName,
  String? fallback,
  int maxLength = 10,
}) {
  for (final candidate in [authDisplayName, providerDisplayName, fallback]) {
    final raw = candidate?.trim();
    if (raw == null || raw.isEmpty) continue;
    final first = raw.split(RegExp(r'\s+')).first;
    if (first.isEmpty) continue;
    return first.length <= maxLength ? first : first.substring(0, maxLength);
  }
  return null;
}
