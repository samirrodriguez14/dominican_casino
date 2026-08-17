import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/models/round.dart';

/// Casino in-game coin bonuses. Accrued on the match and claimed at home.
class CasinoCoinBonuses {
  /// Takes of this many cards or fewer award no coins.
  static const int takeBonusMinCards = 8;

  static int coinsForTake(PlayAction action) {
    final cards = cardsFromTake(action);
    if (cards.length <= takeBonusMinCards) return 0;
    var total = cards.length;
    for (final card in cards) {
      total += specialBonus(card);
    }
    return total;
  }

  static int specialBonus(PlayingCardModel card) {
    final rank = card.rank.trim().toUpperCase();
    if (rank == '10' && card.suit == '♦') return 2;
    if (rank == '2' && card.suit == '♠') return 1;
    if (card.isAce) return 1;
    return 0;
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

  /// Accrue take + virao bonuses onto [game.pendingCoins]. Call on the
  /// client that applied the action, before persist.
  /// Take coins: only when more than [takeBonusMinCards] cards are captured.
  static void accrueAfterPlay(GameState game, PlayAction action) {
    if (game.gameMode != GameMode.casino) return;
    if (isTake(action)) {
      final pid = action.performedById;
      if (!_isBot(game, pid)) {
        game.addPendingCoins(pid, coinsForTake(action));
      }
    }
    accrueViraosIfNeeded(game);
  }

  static void accrueViraosIfNeeded(GameState game) {
    if (game.gameMode != GameMode.casino) return;
    if (game.round.roundStatus != RoundStatus.completed) return;
    if (game.viraosCreditedRoundId == game.round.id) return;
    game.viraosCreditedRoundId = game.round.id;
    final holder = game.extraPointsHolderId;
    if (holder.isEmpty || game.extraPoints <= 0) return;
    if (_isBot(game, holder)) return;
    game.addPendingCoins(holder, game.extraPoints);
  }

  static bool _isBot(GameState game, String pid) {
    final bot = game.localBotPid;
    return bot != null && bot.isNotEmpty && bot == pid;
  }
}
