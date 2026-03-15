import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/lobby_game.dart';

abstract class GameService {
  //STREAM GAMES
  Stream<List<LobbyGame>> listenGames(String pid);
  Stream<GameState?> streamGame(String gid);

  //FIND AND LOAD GAME
  Future<GameState> loadGame(String gid);
  Future<String?> joinGame(
    String gameId,
    String pid,
    Map<String, dynamic> playerInfo,
  );

  //GAME LIFECYCLE
  //FOR NOW MODE, BUT WILL change
  Future<String> createGame(GameMode mode);
  Future<String> newCreateGame(GameState gState);
  Future<GameState> updateGame(GameState gState);
  Future<void> deleteGame(String gid);
}
