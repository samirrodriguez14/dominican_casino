import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> playersInfoFor(List<String> pids) => {
      for (var i = 0; i < pids.length; i++)
        pids[i]: {'name': 'P${i + 1}'},
    };

GameState rummyGameOverState({
  required GameMode mode,
  required List<String> pids,
  required String winnerId,
  required int entryCost,
  Map<String, int>? scores,
}) {
  return GameState(
    gameStatus: GameStatus.gameOver,
    gameMode: mode,
    id: 'gid',
    controllerId: pids.first,
    started: true,
    currentTurnPlayerId: '',
    deck: const [],
    scores: scores ??
        {
          for (final pid in pids) pid: pid == winnerId ? 0 : -20,
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
    playersInfo: playersInfoFor(pids),
    entryCost: entryCost,
    entryPaidBy: pids,
    payoutClaimedBy: const [],
  );
}

void main() {
  group('Rummy pot payout (shared field splits)', () {
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

    test('3 seats: 75/25 for 1st/2nd', () {
      const entry = 100;
      final s = rummyGameOverState(
        mode: GameMode.rummy,
        pids: const ['p1', 'p2', 'p3'],
        winnerId: 'p1',
        entryCost: entry,
        scores: {'p1': 0, 'p2': -10, 'p3': -40},
      );

      expect(s.winPotCoins('p1'), equals(225));
      expect(s.winPotCoins('p2'), equals(75));
      expect(s.winPotCoins('p3'), equals(0));
    });

    test('4 seats Tres y Dos: 75/25 for 1st/2nd', () {
      const entry = 100;
      final s = rummyGameOverState(
        mode: GameMode.tresydos,
        pids: const ['p1', 'p2', 'p3', 'p4'],
        winnerId: 'p1',
        entryCost: entry,
        scores: {'p1': 0, 'p2': -5, 'p3': -12, 'p4': -30},
      );

      expect(s.winPotCoins('p1'), equals(300)); // 75% of 400
      expect(s.winPotCoins('p2'), equals(100)); // 25%
      expect(s.winPotCoins('p3'), equals(0));
      expect(s.winPotCoins('p4'), equals(0));
    });

    test('local AI: bots show theoretical pot shares without paying entry', () {
      const entry = 100;
      final s = rummyGameOverState(
        mode: GameMode.bs,
        pids: const ['me', 'b1', 'b2', 'b3', 'b4', 'b5'],
        winnerId: 'b2',
        entryCost: entry,
        scores: {
          'b2': 0,
          'me': -5,
          'b1': -10,
          'b3': -20,
          'b4': -30,
          'b5': -40,
        },
      );
      s.isLocalBot = true;
      s.botPlayerIds = const ['b1', 'b2', 'b3', 'b4', 'b5'];
      s.entryPaidBy = const ['me']; // only the human paid

      // 6 seats → 70/20/10 of 600.
      expect(s.winPotCoins('b2'), equals(420));
      expect(s.winPotCoins('me'), equals(120));
      expect(s.winPotCoins('b1'), equals(60));
      expect(s.winPotCoins('b3'), equals(0));
    });
  });
}
