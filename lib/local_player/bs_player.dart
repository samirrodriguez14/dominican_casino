import 'dart:math';

import 'package:dominican_casino/game_control/game_engine/bs/bs_state.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

/// Minimal BS bot: plays 1 honest card, rarely calls BS.
class BsPlayer {
  static final _rng = Random();

  static (ClaimPlayAction, CurrentCardSelection) bsBestAction(
    String pid,
    GameState state,
  ) {
    final hand = List<PlayingCardModel>.from(state.hands[pid] ?? const []);
    if (hand.isEmpty) {
      throw StateError('BS bot has empty hand');
    }
    hand.shuffle(_rng);
    final card = hand.first;
    final action = ClaimPlayAction(
      cards: [card],
      claimedRank: card.rank,
      performedById: pid,
    );
    final selection = CurrentCardSelection(
      pid: pid,
      selectedCard: null,
      selectedCards: [card],
      selectedStacks: const [],
    );
    return (action, selection);
  }

  /// Returns a CallBluff about 25% of the time during an open challenge.
  static CallBluffAction? maybeCallBluff(String pid, GameState state) {
    final bs = state.bsState;
    if (bs == null || bs.phase != BsPhase.challenge) return null;
    if (pid == bs.lastClaimPid || bs.challengerPid != null) return null;
    final deadline = bs.challengeDeadline;
    if (deadline != null && !deadline.isAfter(DateTime.now().toUtc())) {
      return null;
    }
    if (_rng.nextDouble() > 0.25) return null;
    return CallBluffAction(performedById: pid);
  }
}
