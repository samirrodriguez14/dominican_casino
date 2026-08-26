import 'package:dominican_casino/models/game_state.dart';
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

/// Preferred match mode for a royal rank (Ace has none).
GameMode? journeyGameForRank(JourneyRank rank) => switch (rank) {
  JourneyRank.jack => GameMode.tresydos,
  JourneyRank.queen => GameMode.rummy,
  JourneyRank.king => GameMode.casinoSpeed,
  JourneyRank.ace => null,
};

String journeyGameModeLabel(GameMode? mode) => switch (mode) {
  GameMode.tresydos => 'Tres y Dos',
  GameMode.rummy => 'Rummy',
  GameMode.casinoSpeed => 'Casino Speed',
  GameMode.casino => 'Casino',
  GameMode.robaito => 'Robaito',
  null => '',
};

class JourneyCardDef {
  const JourneyCardDef({
    required this.world,
    required this.rank,
    required this.state,
    this.requiredLevel,
    this.gameMode,
    this.blurb = '',
  });

  final JourneyWorld world;
  final JourneyRank rank;
  final JourneyCardState state;
  final int? requiredLevel;
  final GameMode? gameMode;
  final String blurb;

  String get assetPath =>
      'assets/images/journey/cards_challengers/${world.name}_${rank.name}.png';

  /// Cutout art for avatars / composed cards (transparent background).
  /// Keep in sync with [AvatarCatalog] journey asset paths.
  String get avatarAssetPath =>
      'assets/images/journey/avatars_transparent_challengers/${world.name}_${rank.name}.png';

  String get title => '${rank.label} of ${world.label}';

  String get gameLabel => journeyGameModeLabel(gameMode);

  bool get isSelectable =>
      state == JourneyCardState.available || state == JourneyCardState.defeated;

  bool get isChallenge =>
      rank != JourneyRank.ace && state == JourneyCardState.available;

  JourneyCardDef copyWith({
    JourneyWorld? world,
    JourneyRank? rank,
    JourneyCardState? state,
    int? requiredLevel,
    GameMode? gameMode,
    String? blurb,
  }) {
    return JourneyCardDef(
      world: world ?? this.world,
      rank: rank ?? this.rank,
      state: state ?? this.state,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      gameMode: gameMode ?? this.gameMode,
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

  /// Defeated Jack/Queen/King only — Aces become avatar accessories.
  List<JourneyCardDef> get defeatedRoyals => [
    for (final card in defeatedCards)
      if (card.rank != JourneyRank.ace) card,
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

  /// Mark [rank] defeated and promote the next card on this pile when level allows.
  ///
  /// No-op when [rank] is not on this pile (e.g. Spades Queen is story-only).
  /// Skips missing ranks when choosing who to promote next.
  JourneyWorldDef withDefeat(JourneyRank rank, {int playerLevel = 99}) {
    if (cardOf(rank) == null) return this;
    JourneyRank? promote;
    var past = false;
    for (final r in JourneyRank.values) {
      if (!past) {
        if (r == rank) past = true;
        continue;
      }
      if (cardOf(r) != null) {
        promote = r;
        break;
      }
    }
    return copyWith(
      cards: [
        for (final c in cards)
          if (c.rank == rank)
            c.copyWith(state: JourneyCardState.defeated)
          else if (promote != null &&
              c.rank == promote &&
              c.state != JourneyCardState.defeated)
            c.copyWith(
              state: _unlockedStateFor(c, playerLevel),
            )
          else
            c,
      ],
    );
  }

  /// Unlock the current frontier card when [playerLevel] meets [requiredLevel].
  JourneyWorldDef withLevelApplied(int playerLevel) {
    if (!unlocked) return this;
    JourneyRank? frontier;
    for (final rank in JourneyRank.values) {
      final c = cardOf(rank);
      if (c == null) continue;
      if (c.state == JourneyCardState.defeated) continue;
      if (c.state == JourneyCardState.mysteryLocked) break;
      frontier = rank;
      break;
    }
    if (frontier == null) return this;
    return copyWith(
      cards: [
        for (final c in cards)
          if (c.rank == frontier)
            c.copyWith(state: _unlockedStateFor(c, playerLevel))
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

JourneyCardState _unlockedStateFor(JourneyCardDef card, int playerLevel) {
  final need = card.requiredLevel ?? 1;
  if (playerLevel >= need) return JourneyCardState.available;
  return JourneyCardState.levelLocked;
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

  JourneyDisplaySnapshot withLevelApplied(int playerLevel) {
    return JourneyDisplaySnapshot(
      worlds: [
        for (final w in worlds) w.withLevelApplied(playerLevel),
      ],
    );
  }

  /// Defeat [rank] in [world]; Ace also unlocks the next world + its Jack.
  JourneyDefeatResult withDefeat(
    JourneyWorld world,
    JourneyRank rank, {
    int playerLevel = 99,
  }) {
    var nextWorlds = [
      for (final w in worlds)
        if (w.world == world)
          w.withDefeat(rank, playerLevel: playerLevel)
        else
          w,
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
                      c.copyWith(state: _unlockedStateFor(c, playerLevel))
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
      final worldDef = nextWorlds.firstWhere((w) => w.world == world);
      JourneyRank? revealRank;
      var past = false;
      for (final r in JourneyRank.values) {
        if (!past) {
          if (r == rank) past = true;
          continue;
        }
        if (worldDef.cardOf(r) != null) {
          revealRank = r;
          break;
        }
      }
      revealed =
          revealRank == null ? null : worldDef.cardOf(revealRank);
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
      unlocked: false,
      cards: [
        JourneyCardDef(
          world: JourneyWorld.diamonds,
          rank: JourneyRank.jack,
          state: JourneyCardState.levelLocked,
          requiredLevel: 1,
          gameMode: GameMode.tresydos,
          blurb:
              'Pricey mask, bigger wager — beat him to meet the King.',
        ),
        JourneyCardDef(
          world: JourneyWorld.diamonds,
          rank: JourneyRank.queen,
          state: JourneyCardState.levelLocked,
          requiredLevel: 1,
          gameMode: GameMode.rummy,
          blurb:
              'Only ever lost a wager to her husband — and she wants your mask.',
        ),
        JourneyCardDef(
          world: JourneyWorld.diamonds,
          rank: JourneyRank.king,
          state: JourneyCardState.levelLocked,
          requiredLevel: 1,
          gameMode: GameMode.casinoSpeed,
          blurb:
              'Wagers the Ace itself — and swears he will not lose.',
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
        _placeholderClubsJack,
        _placeholderClubsQueen,
        _placeholderClubsKing,
        _placeholderClubsAce,
      ],
    ),
    JourneyWorldDef(
      world: JourneyWorld.hearts,
      unlocked: false,
      cards: [
        _placeholderHeartsJack,
        _placeholderHeartsQueen,
        _placeholderHeartsKing,
        _placeholderHeartsAce,
      ],
    ),
    JourneyWorldDef(
      world: JourneyWorld.spades,
      unlocked: false,
      // Queen is story-only in Spades (ruins dialogue) — not a board challenger.
      cards: [
        _placeholderSpadesJack,
        _placeholderSpadesKing,
        _placeholderSpadesAce,
      ],
    ),
  ],
);

// Const board cards for locked worlds (explicit so the snapshot stays const).
const _placeholderClubsJack = JourneyCardDef(
  world: JourneyWorld.clubs,
  rank: JourneyRank.jack,
  state: JourneyCardState.mysteryLocked,
  requiredLevel: 1,
  gameMode: GameMode.tresydos,
);
const _placeholderClubsQueen = JourneyCardDef(
  world: JourneyWorld.clubs,
  rank: JourneyRank.queen,
  state: JourneyCardState.mysteryLocked,
  requiredLevel: 1,
  gameMode: GameMode.rummy,
);
const _placeholderClubsKing = JourneyCardDef(
  world: JourneyWorld.clubs,
  rank: JourneyRank.king,
  state: JourneyCardState.mysteryLocked,
  requiredLevel: 1,
  gameMode: GameMode.casinoSpeed,
);
const _placeholderClubsAce = JourneyCardDef(
  world: JourneyWorld.clubs,
  rank: JourneyRank.ace,
  state: JourneyCardState.mysteryLocked,
);
const _placeholderHeartsJack = JourneyCardDef(
  world: JourneyWorld.hearts,
  rank: JourneyRank.jack,
  state: JourneyCardState.mysteryLocked,
  requiredLevel: 1,
  gameMode: GameMode.tresydos,
);
const _placeholderHeartsQueen = JourneyCardDef(
  world: JourneyWorld.hearts,
  rank: JourneyRank.queen,
  state: JourneyCardState.mysteryLocked,
  requiredLevel: 1,
  gameMode: GameMode.rummy,
);
const _placeholderHeartsKing = JourneyCardDef(
  world: JourneyWorld.hearts,
  rank: JourneyRank.king,
  state: JourneyCardState.mysteryLocked,
  requiredLevel: 1,
  gameMode: GameMode.casinoSpeed,
);
const _placeholderHeartsAce = JourneyCardDef(
  world: JourneyWorld.hearts,
  rank: JourneyRank.ace,
  state: JourneyCardState.mysteryLocked,
);
const _placeholderSpadesJack = JourneyCardDef(
  world: JourneyWorld.spades,
  rank: JourneyRank.jack,
  state: JourneyCardState.mysteryLocked,
  requiredLevel: 1,
  gameMode: GameMode.tresydos,
);
const _placeholderSpadesKing = JourneyCardDef(
  world: JourneyWorld.spades,
  rank: JourneyRank.king,
  state: JourneyCardState.mysteryLocked,
  requiredLevel: 1,
  gameMode: GameMode.casinoSpeed,
);
const _placeholderSpadesAce = JourneyCardDef(
  world: JourneyWorld.spades,
  rank: JourneyRank.ace,
  state: JourneyCardState.mysteryLocked,
);

String journeyAceAsset(JourneyWorld world) =>
    'assets/images/journey/cards_challengers/${world.name}_ace.png';

String journeyAceAvatarAsset(JourneyWorld world) =>
    'assets/images/journey/avatars_transparent_challengers/${world.name}_ace.png';
