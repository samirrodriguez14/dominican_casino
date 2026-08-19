/// Canonical paths for match navigation. Always include tutorialMode.
class GameRoutes {
  static const inviteHost = 'dominican-casino.web.app';
  static const urlScheme = 'dominicancasino';
  static const _gameIdPattern = r'^[a-zA-Z0-9_-]{4,64}$';
  static final _gameIdRe = RegExp(_gameIdPattern);
  static const _webHosts = {
    inviteHost,
    'www.$inviteHost',
  };

  static bool isValidGameId(String id) => _gameIdRe.hasMatch(id);

  static String game({
    required String gameId,
    required String gameMode,
    bool tutorial = false,
  }) =>
      '/game/$gameId/$gameMode/${tutorial ? 'true' : 'false'}';

  static String join({
    required String gameId,
    required String gameMode,
  }) =>
      '/join/$gameId/$gameMode';

  static String inviteUrl({
    required String gameId,
    required String gameMode,
  }) =>
      'https://$inviteHost${join(gameId: gameId, gameMode: gameMode)}';

  /// FCM tap payload from `onTurnChange`. `gameMode` may be empty on
  /// older pushes — caller should load the match if mode is unknown.
  static ({String gameId, String gameMode})? parseNotificationData(
    Map<String, dynamic> data,
  ) {
    if (data['type']?.toString() == 'energy_full') return null;
    final gid = (data['gid'] ?? data['gameId'])?.toString();
    if (gid == null || !isValidGameId(gid)) return null;
    final raw = (data['gameMode'] ?? data['mode'])?.toString() ?? '';
    return (gameId: gid, gameMode: _normalizeMode(raw));
  }

  /// Parse /join/{id}/{mode} or /game/{id}/{mode}/... from a universal
  /// link or custom-scheme URL (`dominicancasino://join/{id}/{mode}`).
  static ({String gameId, String gameMode})? parseInvite(Uri uri) {
    final segments = _inviteSegments(uri);
    if (segments.isEmpty) return null;

    if (segments.first == 'join' && segments.length >= 3) {
      final gameId = segments[1];
      final gameMode = _normalizeMode(segments[2]);
      if (!isValidGameId(gameId)) return null;
      return (gameId: gameId, gameMode: gameMode);
    }

    if (segments.first == 'join' && segments.length >= 2) {
      // Mode missing — cannot open a safe route without guessing.
      return null;
    }

    if (segments.first == 'game' && segments.length >= 3) {
      final gameId = segments[1];
      final gameMode = _normalizeMode(segments[2]);
      if (!isValidGameId(gameId)) return null;
      return (gameId: gameId, gameMode: gameMode);
    }

    return null;
  }

  /// `dominicancasino://join/id/mode` puts `join` in the host, not the path.
  static List<String> _inviteSegments(Uri uri) {
    final host = uri.host;
    if (host.isNotEmpty &&
        !_webHosts.contains(host) &&
        !host.contains('.')) {
      return [host, ...uri.pathSegments];
    }
    return uri.pathSegments;
  }

  static String _normalizeMode(String raw) {
    const prefix = 'GameMode.';
    if (raw.startsWith(prefix)) return raw.substring(prefix.length);
    return raw;
  }
}
