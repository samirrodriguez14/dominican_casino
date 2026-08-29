import 'package:dominican_casino/models/deck.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('leftoverRankScore is negative sum of face ranks', () {
    final hand = [
      Deck.card(id: 'a', rank: '10', suit: '♠'),
      Deck.card(id: 'b', rank: 'K', suit: '♥'),
      Deck.card(id: 'c', rank: 'A', suit: '♦'),
    ];
    // 10 + 13 + 1 = 24 → −24
    expect(GameState.leftoverRankScore(hand), -24);
    expect(GameState.leftoverRankScore(const []), 0);
  });
}
