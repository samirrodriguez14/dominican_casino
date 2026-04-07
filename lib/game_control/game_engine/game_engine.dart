import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/services/game_service.dart';

class CurrentCardSelection {
  String pid;
  PlayingCardModel? selectedCard;
  List<PlayingCardModel> selectedCards;
  List<PlayingAreaStackModel> selectedStacks;
  CurrentCardSelection({
    required this.pid,
    this.selectedCard,
    required this.selectedCards,
    required this.selectedStacks,
  });
  @override
  String toString() {
    return "$selectedCard, $selectedCards, $selectedStacks";
  }
}

abstract class GameEngine {
  GameService gameService;
  GameEngine({required this.gameService});
  //GET PLAY ACTIONS
  List<PlayAction> getAvailableActions(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  );

  //VALIDATE PLAY ACTIONS
  ValidateResult validateAction(
    GameState state,
    CurrentCardSelection cardSelection,
    PlayAction action,
  );
  //PERFORM PLAY ACTIONS
  Future<GameState> performPlayAction(
    GameState state,
    CurrentCardSelection cardSelection,
    PlayAction action,
  );

  //GET INGAME ACTIONS
  InGameAction getInGameAction(GameState gameState, String pid);

  //PERFORM INGAME ACTIONS
  Future<GameState> performInGameAction(
    GameState state,
    InGameAction action,
    String pid,
  );
}


class ValidateResult {
  bool result;
  String reason;
  ValidateResult({required this.reason, required this.result});

  factory ValidateResult.notTurn() {
    return ValidateResult(reason: "Not your turn", result: false);
  }
  factory ValidateResult.noSelectedCard() {
    return ValidateResult(reason: "Must Have a selected Card", result: false);
  }
  factory ValidateResult.exactlyOneTable() {
    return ValidateResult(
      reason: "Must select exactly one table card",
      result: false,
    );
  }
  factory ValidateResult.mustBeOnTable() {
    return ValidateResult(reason: "Must actually be on table", result: false);
  }
  factory ValidateResult.success() {
    return ValidateResult(reason: "Valid action", result: true);
  }
  factory ValidateResult.failure(String reason) {
    return ValidateResult(reason: reason, result: false);
  }
  factory ValidateResult.canTake(bool isValid) {
    return ValidateResult(reason: "canTake", result: isValid);
  }
  factory ValidateResult.canTakeStack(bool isValid) {
    return ValidateResult(reason: "canTakeStack", result: isValid);
  }
  factory ValidateResult.invalidSelection(String message) {
    return ValidateResult(reason: message, result: false);
  }
}
