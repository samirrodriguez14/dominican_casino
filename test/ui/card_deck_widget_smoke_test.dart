import '../helpers/game_state_fixtures.dart';
import 'package:dominican_casino/ui/cards/card_deck.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CardDeck renders at least one face card when back=false', (tester) async {
    final card = GameStateFixtures.card(
      id: 'smoke_card',
      rank: '7',
      suit: '♣',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardDeck(
            cards: [card],
            back: false,
            showLabel: false,
            title: 'Smoke',
            cardWidth: 60,
            extraPoints: 0,
            onTap: () {},
            holdExtraReveal: false,
            lastTakenCards: const [],
            lastCapturer: false,
          ),
        ),
      ),
    );

    expect(find.byType(CardDeck), findsOneWidget);
    expect(find.byType(PlayingCard), findsWidgets);
  });
}

