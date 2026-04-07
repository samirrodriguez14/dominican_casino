import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/local_player/local_player.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

class CasinoPlayer {
  static Map<String, double> scoreValsCasino = {
    "Api": 1,
    "Aheart": 1,
    "Atrebol": 1,
    "Acorazon": 1,
    "pi": 1 / 7,
    "10diamond": 2,
    "2pi": 1,
  };

  static Future<PossibleSelection> casinoBestAction(
    String pid,
    GameState gameState,
  ) async {
    final List<PossibleSelection> allPossibleSelection = [];
    //Opp
    // final opp = _gameState.playersInfo.keys.firstWhere((k) => k != pid);
    //CURRENT HAND
    final currentHand = gameState.hands[pid]!;
    //PLAYING AREA
    final playingArea = gameState.playingArea;

    allPossibleSelection.addAll(
      allPossibleTakeSelection(pid, currentHand, playingArea),
    );

    //POSSIBLE PLAY VALUES
    allPossibleSelection.addAll(allPossiblePlaySelection(pid, currentHand));
    allPossibleSelection.sort((a, b) => b.scoreValue.compareTo(a.scoreValue));
    return allPossibleSelection[0];
  }

  static List<PossibleSelection> allPossibleTakeSelection(
    String pid,
    List<PlayingCardModel> hand,
    List<PlayingCardModel> table,
  ) {
    final List<PossibleSelection> possibleSelections = [];

    for (var myCard in hand) {
      for (var tableCard in table) {
        if (myCard.valueHigh == tableCard.valueHigh) {
          //REDUNDANT CURRENT CARD SELECTION???
          var currentCardSelection = CurrentCardSelection(
            pid: pid,
            selectedCard: myCard,
            selectedCards: [tableCard],
            selectedStacks: [],
          );
          var possibleSelection = PossibleSelection(
            playAction: TakeCardAction(
              usedCard: myCard,
              targetCard: tableCard,
              performedById: pid,
            ),
            cardSelection: currentCardSelection,
            scoreValue: getScoreValue(currentCardSelection),
          );

          developer.log("possible Selection: ${possibleSelection.toString()}");
          possibleSelections.add(possibleSelection);
        }
      }
    }
    possibleSelections.sort((a, b) => b.scoreValue.compareTo(a.scoreValue));
    return possibleSelections;
  }

  static List<PossibleSelection> allPossiblePlaySelection(
    String pid,
    List<PlayingCardModel> hand,
  ) {
    final List<PossibleSelection> possibleSelections = [];

    for (var card in hand) {
      possibleSelections.add(
        PossibleSelection(
          playAction: PlayCardAction(performedById: pid, usedCard: card),
          cardSelection: CurrentCardSelection(
            pid: pid,
            selectedCard: card,
            selectedCards: [],
            selectedStacks: [],
          ),
          scoreValue: -card.valueHigh,
        ),
      );
    }
    possibleSelections.sort((a, b) => a.scoreValue.compareTo(b.scoreValue));
    return possibleSelections;
  }

  static int getScoreValue(CurrentCardSelection cardSelection) {
    double totalSelectionValue = 0;
    totalSelectionValue +=
        scoreValsCasino[cardSelection.selectedCard!.rank +
            cardSelection.selectedCard!.suit] ??
        0.0;
    for (var card in cardSelection.selectedCards) {
      totalSelectionValue += scoreValsCasino[card.rank + card.suit] ?? 0.0;
    }

    return totalSelectionValue.toInt();
  }
}
