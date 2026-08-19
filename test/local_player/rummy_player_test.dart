import 'package:dominican_casino/game_control/game_engine/rummy/rummy_contract.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_matcher.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_requirement.dart';
import 'package:dominican_casino/game_control/game_engine/rummy/rummy_state.dart';
import 'package:dominican_casino/local_player/rummy_player.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/game_state_fixtures.dart';

void main() {
  const pid = GameStateFixtures.pid1;
  const other = GameStateFixtures.pid2;

  PlayingCardModel c(String id, String rank, String suit) =>
      GameStateFixtures.card(id: id, rank: rank, suit: suit);

  GameState baseState({
    required List<PlayingCardModel> hand,
    required List<PlayingCardModel> deck,
    required List<PlayingCardModel> playingArea,
    required RummyState rummyState,
  }) {
    return GameStateFixtures.rummyTwoPlayerState(
      gameStatus: GameStatus.inProgress,
      controllerId: pid,
      currentTurnPlayerId: pid,
      deck: deck,
      playingArea: playingArea,
      p1Hand: hand,
      p2Hand: const [],
      scores: {pid: 0, other: 0},
      round: Round(
        id: 0,
        roundStatus: RoundStatus.playing,
        roundScores: const {},
      ),
      rummyState: rummyState,
    );
  }

  test('take the useful discard when it enables a go-out', () async {
    final contract = RummyContract(
      requirements: [
        RummyRequirement.run(5),
        RummyRequirement.set(2),
      ],
    );

    final hand7 = [
      c('2s', '2', '♠'),
      c('3s', '3', '♠'),
      c('4s', '4', '♠'),
      c('5s', '5', '♠'),
      c('9h', '9', '♥'),
      c('9c', '9', '♣'),
      c('Qh', 'Q', '♥'), // deadwood
    ];

    final tableCard = c('6s', '6', '♠'); // completes 2-6 run
    final deckTop = c('Ks', 'K', '♠'); // not useful

    final state = baseState(
      hand: hand7,
      deck: [deckTop],
      playingArea: [tableCard],
      rummyState: RummyState(
        contract: contract,
        boxAByPid: {pid: [], other: []},
        boxBByPid: {pid: [], other: []},
      ),
    );

    final selection = await RummyPlayer.rummyBestAction(pid, state);
    expect(selection.playAction, isA<TakeCardAction>());

    final take = selection.playAction as TakeCardAction;
    expect(take.usedCard.id, equals(tableCard.id));
    expect(take.fromZone, equals(ZoneType.table));
  });

  test('discard the deadwood when a go-out exists', () async {
    final contract = RummyContract(
      requirements: [
        RummyRequirement.run(5),
        RummyRequirement.set(2),
      ],
    );

    final hand8 = [
      c('2s', '2', '♠'),
      c('3s', '3', '♠'),
      c('4s', '4', '♠'),
      c('5s', '5', '♠'),
      c('6s', '6', '♠'),
      c('9h', '9', '♥'),
      c('9c', '9', '♣'),
      c('Qh', 'Q', '♥'), // deadwood to discard
    ];

    final state = baseState(
      hand: hand8,
      deck: const [],
      playingArea: const [],
      rummyState: RummyState(
        contract: contract,
        boxAByPid: {pid: [], other: []},
        boxBByPid: {pid: [], other: []},
      ),
    );

    final selection = await RummyPlayer.rummyBestAction(pid, state);
    expect(selection.playAction, isA<PlayCardAction>());

    final play = selection.playAction as PlayCardAction;
    expect(play.usedCard.id, equals('Qh'));

    // Bot should have applied a winning overlay for the remaining 7 cards.
    final remaining7 = hand8.where((c) => c.id != 'Qh').toList();

    final rummy = state.rummyState!;
    final idsA = rummy.boxAByPid[pid] ?? [];
    final idsB = rummy.boxBByPid[pid] ?? [];
    final byId = {for (final x in remaining7) x.id: x};
    final groupA = idsA.map((id) => byId[id]).whereType<PlayingCardModel>().toList();
    final groupB = idsB.map((id) => byId[id]).whereType<PlayingCardModel>().toList();

    expect(
      RummyMatcher.contractSatisfied(
        contract: contract,
        allCards: remaining7,
        groupA: groupA,
        groupB: groupB,
      ),
      isTrue,
    );
  });

  test('does not go out with an incomplete layout', () async {
    final contract = RummyContract(
      requirements: [
        RummyRequirement.run(5),
        RummyRequirement.set(2),
      ],
    );

    final hand8 = [
      c('2s', '2', '♠'),
      c('3s', '3', '♠'),
      c('4s', '4', '♠'),
      c('5s', '5', '♠'),
      c('9h', '9', '♥'),
      c('9c', '9', '♣'),
      c('Qh', 'Q', '♥'),
      c('Ks', 'K', '♠'), // still no run-of-5 possible
    ];

    final state = baseState(
      hand: hand8,
      deck: const [],
      playingArea: const [],
      rummyState: RummyState(
        contract: contract,
        boxAByPid: {pid: [], other: []},
        boxBByPid: {pid: [], other: []},
      ),
    );

    final selection = await RummyPlayer.rummyBestAction(pid, state);
    expect(selection.playAction, isA<PlayCardAction>());

    final play = selection.playAction as PlayCardAction;

    final remaining7 = hand8.where((c) => c.id != play.usedCard.id).toList();

    final rummy = state.rummyState!;
    final idsA = rummy.boxAByPid[pid] ?? [];
    final idsB = rummy.boxBByPid[pid] ?? [];
    final byId = {for (final x in remaining7) x.id: x};
    final groupA = idsA.map((id) => byId[id]).whereType<PlayingCardModel>().toList();
    final groupB = idsB.map((id) => byId[id]).whereType<PlayingCardModel>().toList();

    expect(
      RummyMatcher.contractSatisfied(
        contract: contract,
        allCards: remaining7,
        groupA: groupA,
        groupB: groupB,
      ),
      isFalse,
    );
  });
}

