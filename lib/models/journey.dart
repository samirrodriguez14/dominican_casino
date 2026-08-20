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

/// Hardcoded interactive snapshot for layout + theme picking.
class JourneyDisplaySnapshot {
  const JourneyDisplaySnapshot({required this.worlds});

  final List<JourneyWorldDef> worlds;

  JourneyWorldDef worldOf(JourneyWorld world) {
    return worlds.firstWhere((entry) => entry.world == world);
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
