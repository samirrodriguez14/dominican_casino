import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_area_stack_model.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';

/// Small deterministic fixtures for unit tests.
///
/// These helpers intentionally avoid any widget/Firebase dependencies so
/// `flutter test` can run them in CI quickly.
class GameStateFixtures {
  static const pid1 = "p1";
  static const pid2 = "p2";

  static Map<String, dynamic> twoPlayerInfo({
    required String p1,
    required String p2,
  }) =>
      {
        p1: {"name": "Player 1"},
        p2: {"name": "Player 2"},
      };

  static PlayingCardModel card({
    required String id,
    required String rank,
    required String suit,
  }) =>
      Deck.card(id: id, rank: rank, suit: suit);

  static PlayingAreaStackModel emptyStack() => PlayingAreaStackModel(
        id: "stack_empty",
        cards: const [],
        stackValue: 0,
      );

  static CurrentCardSelection casinoPlaySelection({
    required String pid,
    required PlayingCardModel usedCard,
  }) =>
      CurrentCardSelection(
        pid: pid,
        selectedCard: usedCard,
        selectedCards: const [],
        selectedStacks: const [],
      );

  static CurrentCardSelection casinoTakeCardSelection({
    required String pid,
    required PlayingCardModel usedCard,
    required PlayingCardModel targetTableCard,
  }) =>
      CurrentCardSelection(
        pid: pid,
        selectedCard: usedCard,
        selectedCards: [targetTableCard],
        selectedStacks: const [],
      );

  static CurrentCardSelection tresDosPlaySelection({
    required String pid,
    required PlayingCardModel usedCard,
  }) =>
      CurrentCardSelection(
        pid: pid,
        selectedCard: usedCard,
        selectedCards: const [],
        selectedStacks: const [],
      );

  /// Minimal 2-player Casino/CasinoSpeed state.
  ///
  /// Callers should pass *modifiable* lists (the engines mutate hands/deck).
  static GameState casinoTwoPlayerState({
    required GameMode gameMode,
    required GameStatus gameStatus,
    required String controllerId,
    required String currentTurnPlayerId,
    required bool started,
    required List<PlayingCardModel> deck,
    required List<PlayingCardModel> table,
    required List<PlayingCardModel> p1Hand,
    required List<PlayingCardModel> p2Hand,
    Map<String, dynamic>? scores,
    Round? round,
  }) {
    final p1 = pid1;
    final p2 = pid2;
    final initialScores = scores ?? {p1: 0, p2: 0};
    final initialRound = round ??
        Round(
          id: 0,
          roundStatus: RoundStatus.playing,
          roundScores: const {},
        );

    return GameState(
      gameStatus: gameStatus,
      gameMode: gameMode,
      id: "game_test_casino",
      controllerId: controllerId,
      started: started,
      currentTurnPlayerId: currentTurnPlayerId,
      deck: deck,
      scores: initialScores,
      extraPoints: 0,
      extraPointsHolderId: '',
      playingArea: table,
      playingAreaStacks: const [],
      hands: {
        p1: p1Hand,
        p2: p2Hand,
      },
      playersDeck: {
        p1: [],
        p2: [],
      },
      lastTookCardId: '',
      cardMoveEvents: const [],
      round: initialRound,
      winnerId: '',
      playersInfo: twoPlayerInfo(p1: p1, p2: p2),
    );
  }

  /// Minimal 2-player Tres y Dos state.
  static GameState tresDosTwoPlayerState({
    required GameStatus gameStatus,
    required String controllerId,
    required String currentTurnPlayerId,
    required List<PlayingCardModel> deck,
    required List<PlayingCardModel> playingArea,
    required List<PlayingCardModel> p1Hand,
    required List<PlayingCardModel> p2Hand,
    required Map<String, dynamic> scores,
    Round? round,
  }) {
    final p1 = pid1;
    final p2 = pid2;
    final initialRound = round ??
        Round(
          id: 0,
          roundStatus: RoundStatus.playing,
          roundScores: const {},
        );

    return GameState(
      gameStatus: gameStatus,
      gameMode: GameMode.tresydos,
      id: "game_test_tresdos",
      controllerId: controllerId,
      started: true,
      currentTurnPlayerId: currentTurnPlayerId,
      deck: deck,
      scores: scores,
      extraPoints: 0,
      extraPointsHolderId: '',
      playingArea: playingArea,
      playingAreaStacks: const [],
      hands: {
        p1: p1Hand,
        p2: p2Hand,
      },
      playersDeck: {
        p1: [],
        p2: [],
      },
      lastTookCardId: '',
      cardMoveEvents: const [],
      round: initialRound,
      winnerId: '',
      playersInfo: twoPlayerInfo(p1: p1, p2: p2),
    );
  }
}

