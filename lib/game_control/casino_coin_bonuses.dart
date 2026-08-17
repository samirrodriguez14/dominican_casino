import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';

/// Casino in-game coin bonuses. Accrued on the match and claimed at home.
class CasinoCoinBonuses {
  /// Takes of this many cards or more award take-size coins.
  static const int takeBonusMinCards = 6;

  /// Table cards that, with one hand card, reach [takeBonusMinCards].
  static const int takePreviewTableCards = takeBonusMinCards - 1;

  static int coinsForTake(PlayAction action) {
    return coinsForTakeCards(cardsFromTake(action));
  }

  static int coinsForTakeCards(List<PlayingCardModel> cards) {
    if (cards.length < takeBonusMinCards) return 0;
    return cards.length;
  }

  /// Preview coins shown on a table stack of [tableCount] cards.
  static int takePreviewForTableCount(int tableCount) {
    final takeSize = tableCount + 1;
    if (takeSize < takeBonusMinCards) return 0;
    return takeSize;
  }

  static int specialBonus(PlayingCardModel card) {
    final rank = card.rank.trim().toUpperCase();
    if (rank == '10' && card.suit == '♦') return 2;
    if (rank == '2' && card.suit == '♠') return 1;
    if (card.isAce) return 1;
    return 0;
  }

  static int specialCoinsForCards(List<PlayingCardModel> cards) {
    var total = 0;
    for (final card in cards) {
      total += specialBonus(card);
    }
    return total;
  }

  static List<PlayingCardModel> cardsFromTake(PlayAction action) {
    switch (action) {
      case TakeCardAction a:
        return [a.usedCard, a.targetCard];
      case TakeStackAction a:
        return [a.usedCard, ...a.targetStack.cards];
      case AddAndTakeAction a:
        return [a.usedCard, ...a.targetCards];
      case PairAndTakeCardsAction a:
        return [
          a.usedCard,
          ...a.targetCards,
          for (final stack in a.targetStacks) ...stack.cards,
        ];
      default:
        return const [];
    }
  }

  static bool isTake(PlayAction action) {
    return action is TakeCardAction ||
        action is TakeStackAction ||
        action is AddAndTakeAction ||
        action is PairAndTakeCardsAction;
  }

  /// Accrue take + special coins on capture; viraos only when the round ends.
  static void accrueAfterPlay(GameState game, PlayAction action) {
    if (game.gameMode != GameMode.casino) return;
    if (isTake(action)) {
      final pid = action.performedById;
      final cards = cardsFromTake(action);
      final take = coinsForTakeCards(cards);
      final special = specialCoinsForCards(cards);
      if (take > 0) {
        game.addPendingCoins(pid, take);
        game.addRoundTakeCoins(pid, take);
      }
      if (special > 0) {
        game.addPendingCoins(pid, special);
        game.addRoundSpecialCoins(pid, special);
      }
    }
    accrueViraosIfNeeded(game);
  }

  /// Once per completed round: virao coins only, then fold all round
  /// coin totals into [game.round.roundScores] for the status sheet.
  static void accrueViraosIfNeeded(GameState game) {
    if (game.gameMode != GameMode.casino) return;
    if (game.round.roundStatus != RoundStatus.completed) return;
    if (game.viraosCreditedRoundId == game.round.id) return;
    game.viraosCreditedRoundId = game.round.id;

    final holder = game.extraPointsHolderId;
    if (holder.isNotEmpty && game.extraPoints > 0) {
      game.addPendingCoins(holder, game.extraPoints);
      game.addRoundViraoCoins(holder, game.extraPoints);
    }
    _writeCoinsIntoRoundScores(game);
    game.clearRoundCoinAccrual();
  }

  static void _writeCoinsIntoRoundScores(GameState game) {
    for (final pid in game.playersInfo.keys) {
      final raw = game.round.roundScores[pid];
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final take = game.roundTakeCoins[pid] ?? 0;
      final special = game.roundSpecialCoins[pid] ?? 0;
      final virao = game.roundViraoCoins[pid] ?? 0;
      map['coinsTake'] = take;
      map['coinsSpecial'] = special;
      map['coinsVirao'] = virao;
      map['coins'] = take + special + virao;
      game.round.roundScores[pid] = map;
    }
  }
}
