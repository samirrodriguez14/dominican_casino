import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/local_player/local_player.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

class TresdosPlayer {
  static Future<PossibleSelection> tresdosBestAction(
    String pid,
    GameState gameState,
  ) async {
    final currentHand = gameState.hands[pid] ?? [];
    final tableCard = gameState.playingArea.isNotEmpty
        ? gameState.playingArea.last
        : null;
    final deckTopCard = gameState.deck.isNotEmpty ? gameState.deck.last : null;

    if (currentHand.isEmpty) {
      throw Exception('Player $pid has no cards in hand.');
    }

    // Hand size 5 => must take
    if (currentHand.length == 5) {
      if (tableCard == null && deckTopCard == null) {
        throw Exception('No table card or deck card available to take.');
      }

      return possibleTakeSelection(
        pid,
        currentHand,
        tableCard,
        deckTopCard,
      );
    }

    // Otherwise must play
    final allPossibleSelection = allPossiblePlaySelection(pid, currentHand);
    allPossibleSelection.sort((a, b) => b.scoreValue.compareTo(a.scoreValue));

    developer.log(
      'Tresdos best play: ${allPossibleSelection.first.playAction} score=${allPossibleSelection.first.scoreValue}',
    );

    return allPossibleSelection.first;
  }

  static List<PossibleSelection> allPossiblePlaySelection(
    String pid,
    List<PlayingCardModel> hand,
  ) {
    final possibleSelections = <PossibleSelection>[];

    for (final card in hand) {
      final remainingHand = List<PlayingCardModel>.from(hand)..remove(card);
      final score = _handShapeScore(remainingHand);

      possibleSelections.add(
        PossibleSelection(
          playAction: PlayCardAction(
            performedById: pid,
            usedCard: card,
          ),
          cardSelection: CurrentCardSelection(
            pid: pid,
            selectedCard: card,
            selectedCards: [],
            selectedStacks: [],
          ),
          scoreValue: score,
        ),
      );
    }

    possibleSelections.sort((a, b) => b.scoreValue.compareTo(a.scoreValue));
    return possibleSelections;
  }

  static PossibleSelection possibleTakeSelection(
    String pid,
    List<PlayingCardModel> hand,
    PlayingCardModel? tableCard,
    PlayingCardModel? deckCard,
  ) {
    developer.log('Tresdos take decision: visible table=$tableCard');

    final currentScore = _handShapeScore(hand);

    // Only evaluate the visible table card.
    if (tableCard != null) {
      final tableHand = List<PlayingCardModel>.from(hand)..add(tableCard);
      final tableScore = _handShapeScore(tableHand);

      // Take visible table card only if it actually improves the hand.
      if (tableScore > currentScore) {
        final selection = PossibleSelection(
          playAction: TakeCardAction(
            performedById: pid,
            usedCard: tableCard,
            targetCard: tableCard,
          ),
          cardSelection: CurrentCardSelection(
            pid: pid,
            selectedCard: null,
            selectedCards: [tableCard],
            selectedStacks: [],
          ),
          scoreValue: tableScore,
        );

        developer.log(
          'Tresdos chose visible table card: score=$tableScore > current=$currentScore',
        );

        return selection;
      }
    }

    // Otherwise default to deck, since it is unknown and may be better.
    if (deckCard != null) {
      final selection = PossibleSelection(
        playAction: TakeCardAction(
          performedById: pid,
          usedCard: deckCard,
          targetCard: deckCard,
        ),
        cardSelection: CurrentCardSelection(
          pid: pid,
          selectedCard: null,
          selectedCards: [deckCard],
          selectedStacks: [],
        ),
        scoreValue: currentScore,
      );

      developer.log('Tresdos chose deck card (table not useful enough)');
      return selection;
    }

    // Fallback only if deck is empty
    if (tableCard != null) {
      final fallbackScore = _handShapeScore(
        List<PlayingCardModel>.from(hand)..add(tableCard),
      );

      return PossibleSelection(
        playAction: TakeCardAction(
          performedById: pid,
          usedCard: tableCard,
          targetCard: tableCard,
        ),
        cardSelection: CurrentCardSelection(
          pid: pid,
          selectedCard: null,
          selectedCards: [tableCard],
          selectedStacks: [],
        ),
        scoreValue: fallbackScore,
      );
    }

    throw Exception('No valid take selection available.');
  }

  /// Higher score = better hand shape toward 3 + 2.
  static int _handShapeScore(List<PlayingCardModel> hand) {
    final countsMap = _rankCounts(hand);
    final counts = countsMap.values.toList()..sort((a, b) => b.compareTo(a));

    final first = counts.isNotEmpty ? counts[0] : 0;
    final second = counts.length > 1 ? counts[1] : 0;
    final third = counts.length > 2 ? counts[2] : 0;

    if (first == 3 && second == 2) {
      return 10000;
    }

    if (first == 3 && second == 1 && hand.length == 4) {
      return 8000;
    }
    if (first == 2 && second == 2 && hand.length == 4) {
      return 7000;
    }
    if (first == 3 && second == 1 && third == 1) {
      return 6000;
    }
    if (first == 2 && second == 2 && third == 1) {
      return 5500;
    }
    if (first == 2 && second == 1 && third == 1 && hand.length == 4) {
      return 4000;
    }

    int score = 0;
    score += first * 1000;
    score += second * 300;
    score += third * 100;

    score -= countsMap.length * 25;
    score -= hand.fold<int>(0, (sum, c) => sum + c.valueHigh);

    return score;
  }

  static Map<int, int> _rankCounts(List<PlayingCardModel> hand) {
    final counts = <int, int>{};
    for (final card in hand) {
      counts[card.valueLow] = (counts[card.valueLow] ?? 0) + 1;
    }
    return counts;
  }
}