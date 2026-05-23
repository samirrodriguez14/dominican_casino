import 'dart:math';
import 'package:uuid/uuid.dart';

import 'playing_card_model.dart';

class Deck {
  static final Uuid _uuid = const Uuid();

  static List<PlayingCardModel> standard() {
    bool isSpecial(String rank, String suit) {
      if (rank == 'A') return true;
      if (rank == '10' && suit == '♦') return true;
      if (suit == '♠') return true;
      if (rank == '2' && suit == '♠') return true;
      return false;
    }

    final suits = ['♠', '♥', '♦', '♣'];
    final ranks = [
      'A',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
    ];
    // final ranks = ['A','2','3'];//Uncomment for test round

    return [
      for (var s in suits)
        for (var r in ranks)
          PlayingCardModel(
            id: _uuid.v4().substring(0, 8),
            suit: s,
            rank: r,
            isSpecial: isSpecial(r, s),
          ),
    ];
  }

  static List<PlayingCardModel> shuffle(List<PlayingCardModel> deck) {
    final rnd = Random();
    final list = List<PlayingCardModel>.from(deck);
    for (var i = list.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }

  static PlayingCardModel card({
    required String id,
    required String rank,
    required String suit,
  }) {
    bool isSpecial(String rank, String suit) {
      if (rank == 'A') return true;
      if (rank == '10' && suit == '♦') return true;
      if (suit == '♠') return true;
      if (rank == '2' && suit == '♠') return true;
      return false;
    }

    return PlayingCardModel(
      id: id,
      rank: rank,
      suit: suit,
      isSpecial: isSpecial(rank, suit),
    );
  }

  static List<PlayingCardModel> casinoTutorialDeck() {
    return [
      // First deal / scripted tutorial cards
      card(id: 'tutorial_5', rank: '5', suit: '♦'),
      card(id: 'tutorial_8', rank: '8', suit: '♠'),

      card(id: 'opp_4', rank: '4', suit: '♣'),
      card(id: 'opp_7', rank: '7', suit: '♥'),

      card(id: 'table_2', rank: '2', suit: '♣'),
      card(id: 'table_3', rank: '3', suit: '♥'),
      card(id: 'table_9', rank: '9', suit: '♠'),
      card(id: 'table_A', rank: 'A', suit: '♦'),

      // Redeal cards
      card(id: 'tutorial_9', rank: '9', suit: '♦'),
      card(id: 'tutorial_A', rank: 'A', suit: '♣'),

      card(id: 'opp_6', rank: '6', suit: '♠'),
      card(id: 'opp_10', rank: '10', suit: '♦'),

      // Extra filler cards
      card(id: 'deck_1', rank: 'J', suit: '♣'),
      card(id: 'deck_2', rank: 'Q', suit: '♥'),
      card(id: 'deck_3', rank: 'K', suit: '♣'),
      card(id: 'deck_4', rank: '6', suit: '♦'),
      card(id: 'deck_5', rank: '7', suit: '♣'),
      card(id: 'deck_6', rank: '8', suit: '♥'),
      card(id: 'deck_7', rank: '10', suit: '♣'),
      card(id: 'deck_8', rank: '2', suit: '♠'),
    ];
  } 
}
