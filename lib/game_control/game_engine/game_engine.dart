import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

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

/// Pure game rules orchestrator. Callers persist [GameState] via [GameService].
abstract class GameEngine {
  List<PlayAction> getAvailableActions(
    GameState gameState,
    CurrentCardSelection currentCardSelection,
  );

  ValidateResult validateAction(
    GameState state,
    CurrentCardSelection cardSelection,
    PlayAction action,
  );

  /// Mutates and returns state. Does not write to the network.
  GameState performPlayAction(
    GameState state,
    CurrentCardSelection cardSelection,
    PlayAction action,
  );

  /// Query only — no side effects / no persistence.
  InGameAction getInGameAction(GameState gameState, String pid);

  /// Mutates and returns state. Does not write to the network.
  GameState performInGameAction(
    GameState state,
    InGameAction action,
    String pid,
  );

  /// When both seats are filled and the game has not started, callers should
  /// set [GameStatus.readyToStart] and persist (do not do that inside getters).
  bool shouldMarkReadyToStart(GameState gameState) {
    const maxPlayers = 2;
    if (gameState.gameStatus == GameStatus.inProgress ||
        gameState.gameStatus == GameStatus.gameOver) {
      return false;
    }
    final joined = gameState.playersInfo.keys.where((k) => k.isNotEmpty);
    return joined.length >= maxPlayers;
  }
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
