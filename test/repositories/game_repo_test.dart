import 'dart:async';

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/game_state_fixtures.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  group('GameRepo', () {
    test('listenToGame updates gameState and notifies listeners', () async {
      const gameId = 'GAME123';
      final controller = StreamController<GameState?>();

      final fs = MockFirestoreService();
      when(() => fs.streamGame(gameId)).thenAnswer((_) => controller.stream);

      final repo = GameRepo(fs: fs);
      final notified = Completer<void>();
      late final GameState state;
      repo.addListener(() {
        if (repo.gameState != null && identical(repo.gameState, state)) {
          if (!notified.isCompleted) notified.complete();
        }
      });

      state = GameStateFixtures.casinoTwoPlayerState(
        gameMode: GameMode.casino,
        gameStatus: GameStatus.inProgress,
        controllerId: GameStateFixtures.pid1,
        currentTurnPlayerId: GameStateFixtures.pid1,
        started: true,
        deck: [],
        table: const [],
        p1Hand: const [],
        p2Hand: const [],
      );

      repo.listenToGame(gameId);
      controller.add(state);

      await notified.future.timeout(const Duration(seconds: 1));
      expect(repo.gameState, same(state));

      await controller.close();
    });

    test('switching listenToGame cancels old subscription', () async {
      const gameId1 = 'GAME1';
      const gameId2 = 'GAME2';
      final controller1 = StreamController<GameState?>();
      final controller2 = StreamController<GameState?>();

      final fs = MockFirestoreService();
      when(() => fs.streamGame(gameId1))
          .thenAnswer((_) => controller1.stream);
      when(() => fs.streamGame(gameId2))
          .thenAnswer((_) => controller2.stream);

      final repo = GameRepo(fs: fs);

      final state1 = GameStateFixtures.casinoTwoPlayerState(
        gameMode: GameMode.casino,
        gameStatus: GameStatus.inProgress,
        controllerId: GameStateFixtures.pid1,
        currentTurnPlayerId: GameStateFixtures.pid1,
        started: true,
        deck: [],
        table: const [],
        p1Hand: const [],
        p2Hand: const [],
      );
      final state2 = GameStateFixtures.casinoTwoPlayerState(
        gameMode: GameMode.casino,
        gameStatus: GameStatus.inProgress,
        controllerId: GameStateFixtures.pid2,
        currentTurnPlayerId: GameStateFixtures.pid2,
        started: true,
        deck: [],
        table: const [],
        p1Hand: const [],
        p2Hand: const [],
      );

      repo.listenToGame(gameId1);
      controller1.add(state1);
      await Future<void>.delayed(Duration.zero);
      expect(repo.gameState, same(state1));

      repo.listenToGame(gameId2);
      controller2.add(state2);
      await Future<void>.delayed(Duration.zero);
      expect(repo.gameState, same(state2));

      // Old controller emits again; GameRepo should remain on state2.
      controller1.add(GameStateFixtures.casinoTwoPlayerState(
        gameMode: GameMode.casino,
        gameStatus: GameStatus.inProgress,
        controllerId: 'other',
        currentTurnPlayerId: 'other',
        started: true,
        deck: [],
        table: const [],
        p1Hand: const [],
        p2Hand: const [],
      ));
      await Future<void>.delayed(Duration.zero);
      expect(repo.gameState, same(state2));

      await controller1.close();
      await controller2.close();
    });
  });
}

