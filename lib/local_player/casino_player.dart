import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/casino/handlers/casino_rules_handler.dart'
    show CasinoRulesHandler;
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/local_player/local_player.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';

class CasinoPlayer {
  static const double aceWeight = 1.0;
  static const double twoSpadesWeight = 1.0;
  static const double tenDiamondsWeight = 2.0;
  static const double spadeWeight = 1 / 7;

  static Future<PossibleSelection> casinoBestAction(
    String pid,
    GameState gameState,
  ) async {
    final allSelections = getAllPossibleSelections(pid, gameState);

    if (allSelections.isEmpty) {
      final hand = gameState.hands[pid] ?? [];
      final fallback = hand.reduce(
        (a, b) => _playPenalty(a) < _playPenalty(b) ? a : b,
      );

      return PossibleSelection(
        playAction: PlayCardAction(performedById: pid, usedCard: fallback),
        cardSelection: CurrentCardSelection(
          pid: pid,
          selectedCard: fallback,
          selectedCards: [],
          selectedStacks: [],
        ),
        scoreValue: -999,
      );
    }

    allSelections.sort((a, b) => b.scoreValue.compareTo(a.scoreValue));

    developer.log(
      'Best action for $pid => ${allSelections.first.playAction.runtimeType} | score=${allSelections.first.scoreValue}',
    );

    return allSelections.first;
  }

  static List<PossibleSelection> getAllPossibleSelections(
    String pid,
    GameState gameState,
  ) {
    if (gameState.currentTurnPlayerId != pid) {
      developer.log('CasinoPlayer: not $pid turn');
      return [];
    }

    final hand = gameState.hands[pid] ?? [];
    final tableCards = gameState.playingArea;
    final tableStacks = gameState.playingAreaStacks;

    final results = <PossibleSelection>[];

    void tryAdd(CurrentCardSelection selection) {
      final actions = CasinoRulesHandler.getAvailableActions(
        gameState,
        selection,
      );

      for (final action in actions) {
        results.add(
          PossibleSelection(
            playAction: action,
            cardSelection: selection,
            scoreValue: scoreAction(gameState, selection, action),
          ),
        );
      }
    }

    for (final handCard in hand) {
      // 1. Plain play
      tryAdd(
        CurrentCardSelection(
          pid: pid,
          selectedCard: handCard,
          selectedCards: [],
          selectedStacks: [],
        ),
      );

      // 2. Hand + one loose table card
      for (final tableCard in tableCards) {
        tryAdd(
          CurrentCardSelection(
            pid: pid,
            selectedCard: handCard,
            selectedCards: [tableCard],
            selectedStacks: [],
          ),
        );
      }

      // 3. Hand + one stack
      for (final stack in tableStacks) {
        tryAdd(
          CurrentCardSelection(
            pid: pid,
            selectedCard: handCard,
            selectedCards: [],
            selectedStacks: [stack],
          ),
        );
      }

      // 4. Hand + subsets of loose cards
      final cardCombos = _subsets(tableCards);
      for (final cards in cardCombos) {
        tryAdd(
          CurrentCardSelection(
            pid: pid,
            selectedCard: handCard,
            selectedCards: cards,
            selectedStacks: [],
          ),
        );
      }

      // 5. Hand + subsets of stacks
      final stackCombos = _subsets(tableStacks);
      for (final stacks in stackCombos) {
        tryAdd(
          CurrentCardSelection(
            pid: pid,
            selectedCard: handCard,
            selectedCards: [],
            selectedStacks: stacks,
          ),
        );
      }

      // 6. Hand + mixed cards/stacks
      final mixedCardCombos = _subsets(tableCards);
      final mixedStackCombos = _subsets(tableStacks);

      for (final cards in mixedCardCombos) {
        for (final stacks in mixedStackCombos) {
          if (cards.isEmpty && stacks.isEmpty) continue;

          tryAdd(
            CurrentCardSelection(
              pid: pid,
              selectedCard: handCard,
              selectedCards: cards,
              selectedStacks: stacks,
            ),
          );
        }
      }
    }

    // 7. Table-only actions
    final tableOnlyCardCombos = _subsets(tableCards);
    final tableOnlyStackCombos = _subsets(tableStacks);

    for (final cards in tableOnlyCardCombos) {
      tryAdd(
        CurrentCardSelection(
          pid: pid,
          selectedCard: null,
          selectedCards: cards,
          selectedStacks: [],
        ),
      );
    }

    for (final stacks in tableOnlyStackCombos) {
      tryAdd(
        CurrentCardSelection(
          pid: pid,
          selectedCard: null,
          selectedCards: [],
          selectedStacks: stacks,
        ),
      );
    }

    for (final cards in tableOnlyCardCombos) {
      for (final stacks in tableOnlyStackCombos) {
        if (cards.isEmpty && stacks.isEmpty) continue;

        tryAdd(
          CurrentCardSelection(
            pid: pid,
            selectedCard: null,
            selectedCards: cards,
            selectedStacks: stacks,
          ),
        );
      }
    }

    final deduped = _dedupe(results)
      ..sort((a, b) => b.scoreValue.compareTo(a.scoreValue));

    developer.log('CasinoPlayer: found ${deduped.length} legal selections');

    return deduped;
  }

  static int scoreAction(
    GameState gameState,
    CurrentCardSelection selection,
    PlayAction action,
  ) {
    switch (action) {
      case TakeCardAction _:
        return _scoreTakeCard(gameState, action);
      case TakeStackAction _:
        return _scoreTakeStack(gameState, action);
      case AddAndTakeAction _:
        return _scoreAddAndTake(gameState, action);
      case PairAndTakeCardsAction _:
        return _scorePairAndTake(gameState, action);
      case AddCardsAction _:
        return _scoreAddCards(gameState, action);
      case AddCardStackAction _:
        return _scoreAddCardStack(gameState, action);
      case AddTableCardsAction _:
        return _scoreAddTableCards(gameState, action);
      case PairCardsAction _:
        return _scorePairCards(gameState, action);
      case PairTableCardsAction _:
        return _scorePairTableCards(gameState, action);
      case AddAndPairCardsAction _:
        return _scoreAddAndPair(gameState, action);
      case PlayCardAction _:
        return _scorePlayCard(gameState, action);
      default:
        return 0;
    }
  }

  static int _scoreTakeCard(GameState gameState, TakeCardAction a) {
    final captured = [a.usedCard, a.targetCard];
    var score = _scoreCapturedCards(captured);

    score += 6;
    score += _captureCountBonus(captured.length);

    if (gameState.playingArea.length == 1 &&
        gameState.playingAreaStacks.isEmpty) {
      score += 10;
    }

    return score;
  }

  static int _scoreTakeStack(GameState gameState, TakeStackAction a) {
    final captured = [a.usedCard, ...a.targetStack.cards];
    var score = _scoreCapturedCards(captured);

    score += 10;
    score += _captureCountBonus(captured.length);
    if (a.targetStack.paired) score += 3;

    final leftoverLoose = gameState.playingArea.length;
    final leftoverStacks = gameState.playingAreaStacks.length - 1;
    if (leftoverLoose == 0 && leftoverStacks == 0) {
      score += 12;
    }

    return score;
  }

  static int _scoreAddAndTake(GameState gameState, AddAndTakeAction a) {
    final captured = [a.usedCard, ...a.targetCards];
    var score = _scoreCapturedCards(captured);

    score += 12;
    score += _captureCountBonus(captured.length);

    final leftoverLoose = gameState.playingArea.length - a.targetCards.length;
    final leftoverStacks = gameState.playingAreaStacks.length;
    if (leftoverLoose == 0 && leftoverStacks == 0) {
      score += 12;
    }

    return score;
  }

  static int _scorePairAndTake(GameState gameState, PairAndTakeCardsAction a) {
    final captured = [
      a.usedCard,
      ...a.targetCards,
      ...a.targetStacks.expand((s) => s.cards),
    ];

    var score = _scoreCapturedCards(captured);
    score += 14;
    score += _captureCountBonus(captured.length);
    score += a.targetStacks.where((s) => s.paired).length * 3;

    final leftoverLoose = gameState.playingArea.length - a.targetCards.length;
    final leftoverStacks =
        gameState.playingAreaStacks.length - a.targetStacks.length;
    if (leftoverLoose == 0 && leftoverStacks == 0) {
      score += 15;
    }

    return score;
  }

  static int _scoreAddCards(GameState gameState, AddCardsAction a) {
    var score = 5;
    score += _scoreCapturedCards([a.usedCard, ...a.targetCards]);
    score -= _stackRiskPenalty(a.targetCards.length + 1);
    return score;
  }

  static int _scoreAddCardStack(GameState gameState, AddCardStackAction a) {
    final allCards = [a.usedCard, ...a.targetStacks.expand((s) => s.cards)];
    var score = 6;
    score += _scoreCapturedCards(allCards);
    score += a.targetStacks.where((s) => s.paired).length * 2;
    score -= _stackRiskPenalty(allCards.length);
    return score;
  }

  static int _scoreAddTableCards(GameState gameState, AddTableCardsAction a) {
    var score = 4;
    score += _scoreCapturedCards(a.targetCards);
    score -= _stackRiskPenalty(a.targetCards.length);
    return score;
  }

  static int _scorePairCards(GameState gameState, PairCardsAction a) {
    final allCards = [
      a.usedCard,
      ...a.targetCards,
      ...a.targetStacks.expand((s) => s.cards),
    ];

    var score = 8;
    score += _scoreCapturedCards(allCards);
    score += a.targetStacks.where((s) => s.paired).length * 2;
    score -= _stackRiskPenalty(allCards.length - 1);
    return score;
  }

  static int _scorePairTableCards(GameState gameState, PairTableCardsAction a) {
    final allCards = [
      ...a.targetCards,
      ...a.targetStacks.expand((s) => s.cards),
    ];

    var score = 7;
    score += _scoreCapturedCards(allCards);
    score += a.targetStacks.where((s) => s.paired).length * 2;
    score -= _stackRiskPenalty(allCards.length);
    return score;
  }

  static int _scoreAddAndPair(GameState gameState, AddAndPairCardsAction a) {
    final allCards = [
      a.usedCard,
      ...a.targetCards,
      ...a.targetStacks.expand((s) => s.cards),
    ];

    var score = 11;
    score += _scoreCapturedCards(allCards);
    score += a.targetStacks.where((s) => s.paired).length * 2;
    score -= _stackRiskPenalty(allCards.length - 1);
    return score;
  }

  static int _scorePlayCard(GameState gameState, PlayCardAction a) {
    return -_playPenalty(a.usedCard);
  }

  static int _scoreCapturedCards(List<PlayingCardModel> cards) {
    double total = 0;

    for (final c in cards) {
      total += _cardScoreValue(c);
    }

    return (total * 10).round();
  }

  static double _cardScoreValue(PlayingCardModel card) {
    final rank = card.rank.trim().toUpperCase();
    final suit = _normalizeSuit(card.suit);

    double score = 0;

    if (rank == 'A') score += aceWeight;
    if (rank == '2' && suit == 'spade') score += twoSpadesWeight;
    if (rank == '10' && suit == 'diamond') score += tenDiamondsWeight;
    if (suit == 'spade') score += spadeWeight;

    return score;
  }

  static int _playPenalty(PlayingCardModel card) {
    final special = (_cardScoreValue(card) * 12).round();
    final rankWeight = card.valueLow;
    return 4 + special + rankWeight;
  }

  static int _captureCountBonus(int capturedCount) {
    return capturedCount * 2;
  }

  static int _stackRiskPenalty(int size) {
    if (size <= 2) return 0;
    if (size == 3) return 2;
    if (size == 4) return 4;
    return 6 + (size - 4);
  }

  static String _normalizeSuit(String suit) {
    final s = suit.trim().toLowerCase();

    if (s == '♠' || s == 'spade' || s == 'spades' || s == 'pi') {
      return 'spade';
    }
    if (s == '♦' || s == 'diamond' || s == 'diamonds') {
      return 'diamond';
    }
    if (s == '♥' || s == 'heart' || s == 'hearts' || s == 'corazon') {
      return 'heart';
    }
    if (s == '♣' || s == 'club' || s == 'clubs' || s == 'trebol') {
      return 'club';
    }

    return s;
  }

  static List<List<T>> _subsets<T>(List<T> items) {
    final subsets = <List<T>>[];
    final total = 1 << items.length;

    for (int mask = 1; mask < total; mask++) {
      final subset = <T>[];
      for (int i = 0; i < items.length; i++) {
        if ((mask & (1 << i)) != 0) {
          subset.add(items[i]);
        }
      }
      subsets.add(subset);
    }

    return subsets;
  }

  static List<PossibleSelection> _dedupe(List<PossibleSelection> selections) {
    final seen = <String>{};
    final result = <PossibleSelection>[];

    for (final s in selections) {
      final key = _selectionKey(s);
      if (seen.add(key)) {
        result.add(s);
      }
    }

    return result;
  }

  static String _selectionKey(PossibleSelection s) {
    final action = s.playAction;
    final sel = s.cardSelection;

    final selectedCardId = sel.selectedCard?.id ?? 'none';
    final selectedCardIds = sel.selectedCards.map((e) => e.id).toList()..sort();
    final selectedStackIds = sel.selectedStacks.map((e) => e.id).toList()
      ..sort();

    return [
      action.runtimeType.toString(),
      selectedCardId,
      selectedCardIds.join(','),
      selectedStackIds.join(','),
    ].join('|');
  }
}