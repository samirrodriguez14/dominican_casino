import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> playersInfo(String p1, String p2) => {
      p1: {'name': 'P1'},
      p2: {'name': 'P2'},
    };

Map<String, dynamic> playersInfo3(String p1, String p2, String p3) => {
      p1: {'name': 'P1'},
      p2: {'name': 'P2'},
      p3: {'name': 'P3'},
    };

GameState rummyGameOverState({
  required GameMode mode,
  required List<String> pids,
  required String winnerId,
  required int entryCost,
}) {
  final p1 = pids[0];
  final p2 = pids[1];
  final p3 = pids.length >= 3 ? pids[2] : null;

  final info = p3 == null
      ? playersInfo(p1, p2)
      : playersInfo3(p1, p2, p3);

  return GameState(
    gameStatus: GameStatus.gameOver,
    gameMode: mode,
    id: 'gid',
    controllerId: p1,
    started: true,
    currentTurnPlayerId: '',
    deck: const [],
    scores: {
      for (final pid in pids) pid: pid == winnerId ? 1 : 0,
    },
    extraPoints: 0,
    extraPointsHolderId: '',
    playingArea: const [],
    playingAreaStacks: const [],
    hands: {
      for (final pid in pids) pid: const [],
    },
    playersDeck: {
      for (final pid in pids) pid: const [],
    },
    lastTookCardId: '',
    cardMoveEvents: const [],
    round: Round(
      id: 0,
      roundStatus: RoundStatus.completed,
      roundScores: const {},
    ),
    winnerId: winnerId,
    playersInfo: info,
    entryCost: entryCost,
    entryPaidBy: pids,
    payoutClaimedBy: const [],
  );
}

void main() {
  group('Rummy pot payout (winner-takes-all)', () {
    test('2 seats: 1st takes full pot, 2nd gets 0', () {
      const entry = 100;
      final s = rummyGameOverState(
        mode: GameMode.rummy,
        pids: const ['p1', 'p2'],
        winnerId: 'p1',
        entryCost: entry,
      );

      expect(s.winPotCoins('p1'), equals(200));
      expect(s.winPotCoins('p2'), equals(0));
    });

    test('3 seats: 1st takes full pot, 2nd gets 0', () {
      const entry = 100;
      final s = rummyGameOverState(
        mode: GameMode.rummy,
        pids: const ['p1', 'p2', 'p3'],
        winnerId: 'p1',
        entryCost: entry,
      );

      expect(s.winPotCoins('p1'), equals(300));
      expect(s.winPotCoins('p2'), equals(0));
      expect(s.winPotCoins('p3'), equals(0));
    });
  });
}

