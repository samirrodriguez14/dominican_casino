import 'package:dominican_casino/game_control/game_engine/rummy/rummy_contract.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_matcher.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_state.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

class RummyGameStateHandler {
  static void assignContractForDeal(GameState gameState) {
    final contract = RummyContract.pickRandom();
    final boxA = <String, List<String>>{};
    final boxB = <String, List<String>>{};

    for (final pid in gameState.playersInfo.keys) {
      boxA[pid] = [];
      boxB[pid] = [];
    }

    gameState.rummyState = RummyState(
      contract: contract,
      boxAByPid: boxA,
      boxBByPid: boxB,
    );
  }

  static bool shouldReshuffle(GameState gameState) => gameState.deck.isEmpty;

  static GameState handleShuffleRound(GameState gameState) {
    // Reshuffle the discard pile back into the deck.
    if (gameState.playingArea.isNotEmpty) {
      gameState.deck = Deck.shuffle(gameState.playingArea);
      gameState.playingArea.clear();
      gameState.tableOrder.clear();
    } else {
      // Safety fallback: if both deck and discard are empty, reset.
      gameState.deck = Deck.shuffle(Deck.standard());
    }
    return gameState;
  }

  static bool roundEnded(GameState gameState, String performedBy) {
    if (gameState.gameStatus != GameStatus.inProgress) return false;
    if (gameState.round.roundStatus != RoundStatus.playing) return false;
    final rummy = gameState.rummyState;
    if (rummy == null) return false;

    final hand = gameState.hands[performedBy];
    if (hand == null) return false;
    if (hand.isEmpty) return false;

    // Win is only checked after discard, when the hand is back to 7.
    if (hand.length != 7) return false;

    final allById = {for (final c in hand) c.id: c};

    List<PlayingCardModel> buildGroup(
      String pid,
      Map<String, List<String>> map,
    ) {
      final ids = map[pid] ?? const [];
      final out = <PlayingCardModel>[];
      for (final id in ids) {
        final card = allById[id];
        if (card == null) {
          // Overlay contains an id that's not in the remaining hand.
          return const <PlayingCardModel>[];
        }
        out.add(card);
      }
      return out;
    }

    final groupA = buildGroup(performedBy, rummy.boxAByPid);
    if (groupA.isEmpty && (rummy.boxAByPid[performedBy]?.isNotEmpty ?? false)) {
      return false;
    }

    final groupB = buildGroup(performedBy, rummy.boxBByPid);
    if (groupB.isEmpty && (rummy.boxBByPid[performedBy]?.isNotEmpty ?? false)) {
      return false;
    }

    return RummyMatcher.contractSatisfied(
      contract: rummy.contract,
      allCards: hand,
      groupA: groupA,
      groupB: groupB,
    );
  }

  static GameState handleRoundEnded(GameState gameState, String performedBy) {
    gameState.round.roundStatus = RoundStatus.completed;
    gameState.round.nextAcknowledged = false;
    gameState.winnerId = performedBy;
    gameState.gameStatus = GameStatus.gameOver;
    gameState.scores[performedBy] = (gameState.scores[performedBy] ?? 0) + 1;
    // No next round for Rummy (single go-out contract).
    return gameState;
  }
}
