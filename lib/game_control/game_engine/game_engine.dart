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
  bool validateAction(
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
