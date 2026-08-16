/// Canonical paths for match navigation. Always include tutorialMode.
class GameRoutes {
  static const _gameIdPattern = r'^[a-zA-Z0-9_-]{4,64}$';
  static final _gameIdRe = RegExp(_gameIdPattern);

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

  /// Parse /join/{id}/{mode} or /game/{id}/{mode}/... from a universal link.
  static ({String gameId, String gameMode})? parseInvite(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;

    if (segments.first == 'join' && segments.length >= 3) {
      final gameId = segments[1];
      final gameMode = segments[2];
      if (!isValidGameId(gameId)) return null;
      return (gameId: gameId, gameMode: gameMode);
    }

    if (segments.first == 'join' && segments.length >= 2) {
      // Mode missing — cannot open a safe route without guessing.
      return null;
    }

    if (segments.first == 'game' && segments.length >= 3) {
      final gameId = segments[1];
      final gameMode = segments[2];
      if (!isValidGameId(gameId)) return null;
      return (gameId: gameId, gameMode: gameMode);
    }

    return null;
  }
}
