import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/quick_match_prefs.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';

/// Outcome of a Quick Match queue ticket.
enum QuickMatchOutcomeKind { matched, timedOut, cancelled }

class QuickMatchOutcome {
  const QuickMatchOutcome.matched({
    required this.gameId,
    required this.gameMode,
  }) : kind = QuickMatchOutcomeKind.matched;

  const QuickMatchOutcome.timedOut()
      : kind = QuickMatchOutcomeKind.timedOut,
        gameId = null,
        gameMode = null;

  const QuickMatchOutcome.cancelled()
      : kind = QuickMatchOutcomeKind.cancelled,
        gameId = null,
        gameMode = null;

  final QuickMatchOutcomeKind kind;
  final String? gameId;
  final GameMode? gameMode;
}

/// Server-backed Quick Play: enqueue prefs, wait for matcher claim.
class QuickMatchService {
  QuickMatchService(this._fs);

  final FirestoreService _fs;

  /// Client search UI / local give-up; server times out at ~60s too.
  static const Duration searchTimeout = Duration(seconds: 60);

  /// Write [matchmakingQueue/{playerId}] and listen until terminal status.
  Future<QuickMatchOutcome> findMatch({
    required QuickMatchPrefs prefs,
    required String playerId,
    String? displayName,
    String? avatarId,
    Duration timeout = searchTimeout,
    Future<void>? cancel,
  }) async {
    final ticketId = DateTime.now().millisecondsSinceEpoch.toString();
    await _fs.enqueueMatchmaking(
      uid: playerId,
      ticketId: ticketId,
      prefs: prefs,
      displayName: displayName,
      avatarId: avatarId,
    );

    final completer = Completer<QuickMatchOutcome>();
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;
    Timer? timer;
    var cancelledByUser = false;

    void finish(QuickMatchOutcome outcome) {
      if (completer.isCompleted) return;
      completer.complete(outcome);
    }

    void onSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
      if (completer.isCompleted) return;
      final data = snap.data();
      if (data == null) return;
      final status = data['status']?.toString();
      final docTicket = data['ticketId']?.toString();
      if (docTicket != null && docTicket != ticketId) return;

      if (status == 'matched') {
        final gid = data['matchedGameId']?.toString() ?? '';
        if (gid.isEmpty) return;
        final mode = gameModeFrom(
          data['matchedGameMode']?.toString(),
        );
        finish(QuickMatchOutcome.matched(gameId: gid, gameMode: mode));
        return;
      }
      if (status == 'timedOut') {
        finish(const QuickMatchOutcome.timedOut());
        return;
      }
      if (status == 'cancelled') {
        finish(const QuickMatchOutcome.cancelled());
      }
    }

    sub = _fs.listenMatchmakingTicket(playerId).listen(
      onSnap,
      onError: (_) {
        if (!completer.isCompleted) {
          finish(const QuickMatchOutcome.timedOut());
        }
      },
    );

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        finish(const QuickMatchOutcome.timedOut());
      }
    });

    if (cancel != null) {
      unawaited(
        cancel.then((_) {
          cancelledByUser = true;
          finish(const QuickMatchOutcome.cancelled());
        }),
      );
    }

    try {
      final outcome = await completer.future;
      if (cancelledByUser ||
          outcome.kind == QuickMatchOutcomeKind.cancelled ||
          outcome.kind == QuickMatchOutcomeKind.timedOut) {
        try {
          await _fs.cancelMatchmaking(playerId);
        } catch (_) {}
      }
      return outcome;
    } finally {
      timer.cancel();
      await sub.cancel();
    }
  }

  /// Modes to check energy against before enqueue (effective selection).
  static List<GameMode> energyModesFor(QuickMatchPrefs prefs) {
    if (prefs.anyMode) return List<GameMode>.from(gameModeCarouselModes);
    return prefs.effectiveModes;
  }
}
