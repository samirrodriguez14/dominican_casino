import 'package:dominican_casino/style/journey_worlds.dart';

/// Royal ranks shown on the Journey table (v1: four cards per world).
enum JourneyRank {
  jack,
  queen,
  king,
  ace;

  String get label => switch (this) {
    JourneyRank.jack => 'Jack',
    JourneyRank.queen => 'Queen',
    JourneyRank.king => 'King',
    JourneyRank.ace => 'Ace',
  };

  /// Next royal rank in Journey order, or null after Ace.
  JourneyRank? get next => switch (this) {
    JourneyRank.jack => JourneyRank.queen,
    JourneyRank.queen => JourneyRank.king,
    JourneyRank.king => JourneyRank.ace,
    JourneyRank.ace => null,
  };
}

/// Visual / progression state for a Journey character card.
enum JourneyCardState {
  defeated,
  available,
  levelLocked,
  mysteryLocked,
}

class JourneyCardDef {
  const JourneyCardDef({
    required this.world,
    required this.rank,
    required this.state,
    this.requiredLevel,
    this.preferredGame = 'Casino',
    this.blurb = '',
  });

  final JourneyWorld world;
  final JourneyRank rank;
  final JourneyCardState state;
  final int? requiredLevel;
  final String preferredGame;
  final String blurb;

  String get assetPath =>
      'assets/images/journey/${world.name}_${rank.name}.png';

  String get title => '${rank.label} of ${world.label}';

  bool get isSelectable =>
      state == JourneyCardState.available || state == JourneyCardState.defeated;

  bool get isChallenge =>
      rank != JourneyRank.ace && state == JourneyCardState.available;

  JourneyCardDef copyWith({
    JourneyWorld? world,
    JourneyRank? rank,
    JourneyCardState? state,
    int? requiredLevel,
    String? preferredGame,
    String? blurb,
  }) {
    return JourneyCardDef(
      world: world ?? this.world,
      rank: rank ?? this.rank,
      state: state ?? this.state,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      preferredGame: preferredGame ?? this.preferredGame,
      blurb: blurb ?? this.blurb,
    );
  }
}

class JourneyWorldDef {
  const JourneyWorldDef({
    required this.world,
    required this.unlocked,
    required this.cards,
  });

  final JourneyWorld world;
  final bool unlocked;
  final List<JourneyCardDef> cards;

  List<JourneyCardDef> get pileCards => [
    for (final card in cards)
      if (card.state != JourneyCardState.defeated) card,
  ];

  List<JourneyCardDef> get defeatedCards => [
    for (final card in cards)
      if (card.state == JourneyCardState.defeated) card,
  ];

  JourneyCardDef? get nextSelectable {
    for (final card in cards) {
      if (card.state == JourneyCardState.available) return card;
    }
    return null;
  }

  JourneyCardDef? cardOf(JourneyRank rank) {
    for (final card in cards) {
      if (card.rank == rank) return card;
    }
    return null;
  }

  JourneyCardDef? cardAfter(JourneyRank rank) {
    final next = rank.next;
    if (next == null) return null;
    return cardOf(next);
  }

  /// Mark [rank] defeated and promote the next card to available (if any).
  JourneyWorldDef withDefeat(JourneyRank rank) {
    final promote = rank.next;
    return copyWith(
      cards: [
        for (final c in cards)
          if (c.rank == rank)
            c.copyWith(state: JourneyCardState.defeated)
          else if (promote != null && c.rank == promote)
            c.copyWith(state: JourneyCardState.available)
          else
            c,
      ],
    );
  }

  JourneyWorldDef copyWith({
    JourneyWorld? world,
    bool? unlocked,
    List<JourneyCardDef>? cards,
  }) {
    return JourneyWorldDef(
      world: world ?? this.world,
      unlocked: unlocked ?? this.unlocked,
      cards: cards ?? this.cards,
    );
  }
}

/// Result of applying a defeat: updated worlds plus the card that should flip.
class JourneyDefeatResult {
  const JourneyDefeatResult({
    required this.worlds,
    this.revealedCard,
    this.unlockedWorld,
  });

  final List<JourneyWorldDef> worlds;
  final JourneyCardDef? revealedCard;
  final JourneyWorld? unlockedWorld;
}

/// Hardcoded interactive snapshot for layout + theme picking.
class JourneyDisplaySnapshot {
  const JourneyDisplaySnapshot({required this.worlds});

  final List<JourneyWorldDef> worlds;

  JourneyWorldDef worldOf(JourneyWorld world) {
    return worlds.firstWhere((entry) => entry.world == world);
  }

  /// Defeat [rank] in [world]; Ace also unlocks the next world + its Jack.
  JourneyDefeatResult withDefeat(JourneyWorld world, JourneyRank rank) {
    var nextWorlds = [
      for (final w in worlds)
        if (w.world == world) w.withDefeat(rank) else w,
    ];

    JourneyCardDef? revealed;
    JourneyWorld? unlockedWorld;

    if (rank == JourneyRank.ace) {
      final idx = JourneyWorld.values.indexOf(world);
      if (idx >= 0 && idx + 1 < JourneyWorld.values.length) {
        unlockedWorld = JourneyWorld.values[idx + 1];
        nextWorlds = [
          for (final w in nextWorlds)
            if (w.world != unlockedWorld)
              w
            else
              w.copyWith(
                unlocked: true,
                cards: [
                  for (final c in w.cards)
                    if (c.rank == JourneyRank.jack)
                      c.copyWith(state: JourneyCardState.available)
                    else
                      c,
                ],
              ),
        ];
        revealed = nextWorlds
            .firstWhere((w) => w.world == unlockedWorld)
            .cardOf(JourneyRank.jack);
      }
    } else {
      revealed = nextWorlds
          .firstWhere((w) => w.world == world)
          .cardOf(rank.next!);
    }

    return JourneyDefeatResult(
      worlds: nextWorlds,
      revealedCard: revealed,
      unlockedWorld: unlockedWorld,
    );
  }
}

const journeyBoardSnapshot = JourneyDisplaySnapshot(
  worlds: [
    JourneyWorldDef(
      world: JourneyWorld.diamonds,
      unlocked: true,
      cards: [
        JourneyCardDef(
          world: JourneyWorld.diamonds,
          rank: JourneyRank.jack,
          state: JourneyCardState.available,
          preferredGame: 'Casino',
          blurb: 'A restless courtier. Prove yourself at the table.',
        ),
        JourneyCardDef(
          world: JourneyWorld.diamonds,
          rank: JourneyRank.queen,
          state: JourneyCardState.levelLocked,
          requiredLevel: 10,
          preferredGame: 'Casino',
          blurb: 'Polished ambition wearing a crown of facets.',
        ),
        JourneyCardDef(
          world: JourneyWorld.diamonds,
          rank: JourneyRank.king,
          state: JourneyCardState.levelLocked,
          requiredLevel: 13,
          preferredGame: 'Casino',
          blurb: 'The court tests travelers by tradition.',
        ),
        JourneyCardDef(
          world: JourneyWorld.diamonds,
          rank: JourneyRank.ace,
          state: JourneyCardState.mysteryLocked,
          blurb: 'Mastery of Ambition.',
        ),
      ],
    ),
    JourneyWorldDef(
      world: JourneyWorld.clubs,
      unlocked: false,
      cards: [
        JourneyCardDef(
          world: JourneyWorld.clubs,
          rank: JourneyRank.jack,
          state: JourneyCardState.mysteryLocked,
        ),
        JourneyCardDef(
          world: JourneyWorld.clubs,
          rank: JourneyRank.queen,
          state: JourneyCardState.mysteryLocked,
        ),
        JourneyCardDef(
          world: JourneyWorld.clubs,
          rank: JourneyRank.king,
          state: JourneyCardState.mysteryLocked,
        ),
        JourneyCardDef(
          world: JourneyWorld.clubs,
          rank: JourneyRank.ace,
          state: JourneyCardState.mysteryLocked,
        ),
      ],
    ),
    JourneyWorldDef(
      world: JourneyWorld.hearts,
      unlocked: false,
      cards: [
        JourneyCardDef(
          world: JourneyWorld.hearts,
          rank: JourneyRank.jack,
          state: JourneyCardState.mysteryLocked,
        ),
        JourneyCardDef(
          world: JourneyWorld.hearts,
          rank: JourneyRank.queen,
          state: JourneyCardState.mysteryLocked,
        ),
        JourneyCardDef(
          world: JourneyWorld.hearts,
          rank: JourneyRank.king,
          state: JourneyCardState.mysteryLocked,
        ),
        JourneyCardDef(
          world: JourneyWorld.hearts,
          rank: JourneyRank.ace,
          state: JourneyCardState.mysteryLocked,
        ),
      ],
    ),
    JourneyWorldDef(
      world: JourneyWorld.spades,
      unlocked: false,
      cards: [
        JourneyCardDef(
          world: JourneyWorld.spades,
          rank: JourneyRank.jack,
          state: JourneyCardState.mysteryLocked,
        ),
        JourneyCardDef(
          world: JourneyWorld.spades,
          rank: JourneyRank.queen,
          state: JourneyCardState.mysteryLocked,
        ),
        JourneyCardDef(
          world: JourneyWorld.spades,
          rank: JourneyRank.king,
          state: JourneyCardState.mysteryLocked,
        ),
        JourneyCardDef(
          world: JourneyWorld.spades,
          rank: JourneyRank.ace,
          state: JourneyCardState.mysteryLocked,
        ),
      ],
    ),
  ],
);

String journeyAceAsset(JourneyWorld world) =>
    'assets/images/journey/${world.name}_ace.png';
