import 'package:dominican_casino/models/game_state.dart';

class GameStateHandler {
  //USE TO MAKE CHANGES TO THE GAME STATTE...
  
  //UPDATING GAMESTATE CURRENTPLAYER ID
  static String getNextPlayerId(GameState gameState, String pid) {
    final players = gameState.playersInfo?.keys.toList() ?? [];

    if (players.isEmpty) return "";

    final index = players.indexOf(pid);
    if (index == -1) return players.first;

    final nextIndex = (index + 1) % players.length;
    return players[nextIndex];
  }
}
