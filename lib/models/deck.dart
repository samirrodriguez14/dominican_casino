import 'dart:math';
import 'playing_card_model.dart';

class Deck {
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
          PlayingCardModel(suit: s, rank: r, isSpecial: isSpecial(r, s)),
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
}
