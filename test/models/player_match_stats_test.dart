import 'package:dominican_casino/models/game_pill_data.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player_match_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerMatchStats', () {
    test('recordResult increments overall and by mode', () {
      var stats = PlayerMatchStats.empty;
      stats = stats.recordResult(
        modeName: GameMode.casino.name,
        won: true,
        place: 1,
      );
      stats = stats.recordResult(
        modeName: GameMode.casino.name,
        won: false,
        place: 2,
      );
      stats = stats.recordResult(
        modeName: GameMode.rummy.name,
        won: true,
        place: 1,
      );

      expect(stats.wins, 2);
      expect(stats.losses, 1);
      expect(stats.gamesPlayed, 3);
      expect(stats.modeStats(GameMode.casino.name).wins, 1);
      expect(stats.modeStats(GameMode.casino.name).losses, 1);
      expect(stats.modeStats(GameMode.casino.name).places[1], 1);
      expect(stats.modeStats(GameMode.casino.name).places[2], 1);
      expect(stats.modeStats(GameMode.rummy.name).wins, 1);
    });

    test('json round-trip preserves places', () {
      final original = PlayerMatchStats.empty
          .recordResult(modeName: 'bs', won: false, place: 3)
          .recordResult(modeName: 'bs', won: true, place: 1);
      final restored = PlayerMatchStats.fromJson(original.toJson());
      expect(restored.wins, 1);
      expect(restored.losses, 1);
      expect(restored.modeStats('bs').places[1], 1);
      expect(restored.modeStats('bs').places[3], 1);
    });

    test('prefer picks the side with more games', () {
      final a = PlayerMatchStats.empty.recordResult(
        modeName: 'casino',
        won: true,
        place: 1,
      );
      final b = a
          .recordResult(modeName: 'casino', won: false, place: 2)
          .recordResult(modeName: 'rummy', won: true, place: 1);
      expect(
        PlayerMatchStats.prefer(preferred: a, other: b).gamesPlayed,
        3,
      );
      expect(
        PlayerMatchStats.prefer(preferred: b, other: a).gamesPlayed,
        3,
      );
    });

    test('fromArchivedGames aggregates finished pills', () {
      final pills = [
        GamePillData(
          id: 'g1',
          playersInfo: {
            'me': {'id': 'me', 'name': 'Me'},
            'bot': {'id': 'bot', 'name': 'Bot'},
          },
          currentTurnPlayerId: null,
          gameMode: GameMode.casino,
          gameStatus: GameStatus.gameOver,
          winnerId: 'me',
          scores: const {'me': 21, 'bot': 10},
        ),
        GamePillData(
          id: 'g2',
          playersInfo: {
            'me': {'id': 'me', 'name': 'Me'},
            'bot': {'id': 'bot', 'name': 'Bot'},
          },
          currentTurnPlayerId: null,
          gameMode: GameMode.rummy,
          gameStatus: GameStatus.gameOver,
          winnerId: 'bot',
          scores: const {'me': 40, 'bot': 0},
        ),
        GamePillData(
          id: 'g3',
          playersInfo: {
            'me': {'id': 'me', 'name': 'Me'},
            'bot': {'id': 'bot', 'name': 'Bot'},
          },
          currentTurnPlayerId: 'me',
          gameMode: GameMode.casino,
          gameStatus: GameStatus.inProgress,
          winnerId: null,
        ),
      ];

      final stats = PlayerMatchStats.fromArchivedGames(pills, 'me');
      expect(stats.wins, 1);
      expect(stats.losses, 1);
      expect(stats.modeStats(GameMode.casino.name).wins, 1);
      expect(stats.modeStats(GameMode.rummy.name).losses, 1);
      expect(stats.modeStats(GameMode.rummy.name).places[2], 1);
    });

    test('withGame is a no-op when not game over', () {
      final game = GameState.create('g', 'me', GameMode.casino);
      final stats = PlayerMatchStats.empty.withGame(game, 'me');
      expect(stats.isEmpty, isTrue);
    });
  });
}
