import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';

abstract class GameService {
  /// Lightweight lobby rows for in-progress matches only.
  Stream<List<GamePillData>> listenActiveGames(String pid);

  /// One-shot paginated history — not a live listener.
  Future<List<GamePillData>> fetchArchivedGames(
    String pid, {
    int limit = 20,
    DateTime? startAfterUpdatedAt,
  });

  Stream<GameState?> streamGame(String gid);

  //FIND AND LOAD GAME
  Future<GameState> loadGame(String gid);

  //GAME LIFECYCLE
  //FOR NOW MODE, BUT WILL change
  Future<String> newCreateGame(GameState gState);
  Future<GameState> updateGame(GameState gState);
  Future<void> deleteGame(String gid);
}
