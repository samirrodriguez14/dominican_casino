import 'dart:async';

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/quick_match_prefs.dart';
import 'package:dominican_casino/services/firestore_service.dart';

/// Client-side Quick Play: listen for public waiting rooms matching [prefs].
class QuickMatchService {
  QuickMatchService(this._fs);

  final FirestoreService _fs;

  static const Duration searchTimeout = Duration(seconds: 20);

  /// Watches public lobbies until a match is found, [timeout] elapses, or
  /// [cancel] completes. Returns the first eligible [GameState], or null.
  Future<GameState?> findMatch({
    required QuickMatchPrefs prefs,
    required String playerId,
    Duration timeout = searchTimeout,
    Future<void>? cancel,
  }) async {
    final completer = Completer<GameState?>();
    StreamSubscription<List<GameState>>? sub;
    Timer? timer;
    final tried = <String>{};

    void finish(GameState? match) {
      if (completer.isCompleted) return;
      completer.complete(match);
    }

    void consider(List<GameState> rooms) {
      if (completer.isCompleted) return;
      final candidates = rooms.where((g) => matchesPrefs(g, prefs, playerId)).toList()
        ..sort((a, b) {
          // Prefer rooms closer to full, then older ids as a stable tiebreak.
          final aOpen = a.joinSeatCap - a.seatedPlayerCount;
          final bOpen = b.joinSeatCap - b.seatedPlayerCount;
          final byOpen = aOpen.compareTo(bOpen);
          if (byOpen != 0) return byOpen;
          return a.id.compareTo(b.id);
        });
      for (final g in candidates) {
        if (tried.contains(g.id)) continue;
        tried.add(g.id);
        finish(g);
        return;
      }
    }

    sub = _fs.listenPublicWaitingGames().listen(
      consider,
      onError: (_) {
        if (!completer.isCompleted) finish(null);
      },
    );

    timer = Timer(timeout, () => finish(null));
    if (cancel != null) {
      unawaited(cancel.then((_) => finish(null)));
    }

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      await sub.cancel();
    }
  }

  /// Whether [game] is joinable under [prefs] for [playerId].
  static bool matchesPrefs(
    GameState game,
    QuickMatchPrefs prefs,
    String playerId,
  ) {
    if (!game.isPublic) return false;
    if (game.isLocalBot) return false;
    if (game.started) return false;
    if (game.gameStatus != GameStatus.waitingForPlayers) return false;
    if (game.playersInfo.containsKey(playerId)) return false;
    if (game.entryCost > prefs.maxEntryCost) return false;
    if (!prefs.effectiveModes.contains(game.gameMode)) return false;
    if (game.seatedPlayerCount >= game.joinSeatCap) return false;
    final target = game.targetSeats ?? game.maxSeats;
    if (target > prefs.maxPlayers) return false;
    return true;
  }
}
