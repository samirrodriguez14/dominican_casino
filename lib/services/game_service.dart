import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';

abstract class GameService {
  //STREAM GAMES
  Stream<List<GamePillData>> listenGames(String pid);
  Stream<GameState?> streamGame(String gid);

  //FIND AND LOAD GAME
  Future<GameState> loadGame(String gid);

  //GAME LIFECYCLE
  //FOR NOW MODE, BUT WILL change
  Future<String> newCreateGame(GameState gState);
  Future<GameState> updateGame(GameState gState);
  Future<void> deleteGame(String gid);
}
