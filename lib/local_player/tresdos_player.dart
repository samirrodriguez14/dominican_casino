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
    final List<PossibleSelection> allPossibleSelection = [];
    //Opp
    // final opp = _gameState.playersInfo.keys.firstWhere((k) => k != pid);
    //CURRENT HAND
    final currentHand = gameState.hands[pid]!;
    //PLAYING AREA
    final playingAreaCard = gameState.playingArea.isNotEmpty
        ? gameState.playingArea[0]
        : null;
    final deckTopCard = gameState.deck[0];

    //IF I ONLY HAVE 5 CARDS, I MUST TAKE
    if (gameState.hands[pid]?.length == 5) {
      return possibleTakeSelection(
        pid,
        currentHand,
        playingAreaCard!,
        deckTopCard,
      );
    }

    //OTHER WISE, PLAY MY LEAST HELPFUL CARD
    allPossibleSelection.addAll(allPossiblePlaySelection(pid, currentHand));
    allPossibleSelection.sort((a, b) => b.scoreValue.compareTo(a.scoreValue));
    return allPossibleSelection[0];
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

  static PossibleSelection possibleTakeSelection(
    String pid,
    List<PlayingCardModel> hand,
    PlayingCardModel tableCard,
    PlayingCardModel deckCard,
  ) {
    PossibleSelection? possibleSelection;
    developer.log("deckCard Selection: $deckCard, $tableCard");

    for (var myCard in hand) {
      if (myCard.valueHigh == tableCard.valueHigh) {
        //REDUNDANT CURRENT CARD SELECTION???
        var currentCardSelection = CurrentCardSelection(
          pid: pid,
          selectedCards: [tableCard],
          selectedStacks: [],
        );
        possibleSelection = PossibleSelection(
          playAction: TakeCardAction(
            usedCard: tableCard,
            targetCard: tableCard,
            performedById: pid,
          ),
          cardSelection: currentCardSelection,
          scoreValue: 0,
        );
        developer.log("possible Selection: ${possibleSelection.toString()}");
        break;
      }
    }

    possibleSelection ??= PossibleSelection(
      playAction: TakeCardAction(
        usedCard: deckCard,
        performedById: pid,
        targetCard: deckCard,
      ),
      cardSelection: CurrentCardSelection(
        pid: pid,
        selectedCards: [deckCard],
        selectedStacks: [],
      ),
      scoreValue: 0,
    );
    return possibleSelection;
  }
}
