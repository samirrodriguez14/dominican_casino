import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/journey_worlds.dart';

/// Jack + Queen + King + Ace across all four kingdoms.
const journeyTrailStepCount = 16;

/// Global trail index for a world/rank (0…15).
int journeyTrailStepIndex(JourneyWorld world, JourneyRank rank) {
  final wi = JourneyWorld.values.indexOf(world).clamp(0, 3);
  final ri = JourneyRank.values.indexOf(rank).clamp(0, 3);
  return wi * 4 + ri;
}

/// Pointer to a Journey challenger (and optional live match id).
class JourneyChallengeRef {
  const JourneyChallengeRef({
    required this.world,
    required this.rank,
    this.gameId,
    this.ignoreOutcome = false,
    this.escortOnLoss = false,
    this.retryOnLoss = false,
    this.denyCampOnWin = false,
  });

  final JourneyWorld world;
  final JourneyRank rank;
  final String? gameId;
  /// When true, win/loss both complete the story beat (Clubs court / Hearts King).
  final bool ignoreOutcome;
  /// When true, only a loss advances the story (Hearts/Spades Jack → escort).
  final bool escortOnLoss;
  /// When true, a loss prompts Retry instead of the Diamonds loss taunt (Spades King).
  final bool retryOnLoss;
  /// When true, a win denies camp access (Spades Jack) instead of trail unlock.
  final bool denyCampOnWin;

  Map<String, dynamic> toJson() => {
    'world': world.name,
    'rank': rank.name,
    if (gameId != null && gameId!.isNotEmpty) 'gameId': gameId,
    if (ignoreOutcome) 'ignoreOutcome': true,
    if (escortOnLoss) 'escortOnLoss': true,
    if (retryOnLoss) 'retryOnLoss': true,
    if (denyCampOnWin) 'denyCampOnWin': true,
  };

  static JourneyChallengeRef? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final worldName = json['world'] as String?;
    final rankName = json['rank'] as String?;
    if (worldName == null || rankName == null) return null;
    JourneyWorld? world;
    JourneyRank? rank;
    for (final w in JourneyWorld.values) {
      if (w.name == worldName) world = w;
    }
    for (final r in JourneyRank.values) {
      if (r.name == rankName) rank = r;
    }
    if (world == null || rank == null) return null;
    final gameId = json['gameId'] as String?;
    return JourneyChallengeRef(
      world: world,
      rank: rank,
      gameId: (gameId != null && gameId.isNotEmpty) ? gameId : null,
      ignoreOutcome: json['ignoreOutcome'] == true,
      escortOnLoss: json['escortOnLoss'] == true,
      retryOnLoss: json['retryOnLoss'] == true,
      denyCampOnWin: json['denyCampOnWin'] == true,
    );
  }

  JourneyChallengeRef copyWith({
    JourneyWorld? world,
    JourneyRank? rank,
    String? gameId,
    bool? ignoreOutcome,
    bool? escortOnLoss,
    bool? retryOnLoss,
    bool? denyCampOnWin,
  }) {
    return JourneyChallengeRef(
      world: world ?? this.world,
      rank: rank ?? this.rank,
      gameId: gameId ?? this.gameId,
      ignoreOutcome: ignoreOutcome ?? this.ignoreOutcome,
      escortOnLoss: escortOnLoss ?? this.escortOnLoss,
      retryOnLoss: retryOnLoss ?? this.retryOnLoss,
      denyCampOnWin: denyCampOnWin ?? this.denyCampOnWin,
    );
  }
}

/// Theme / avatar unlocks earned from a Journey victory (shown after coins/XP).
class JourneyUnlockReward {
  const JourneyUnlockReward({
    required this.world,
    required this.rank,
    this.avatarId,
    this.themeId,
    this.showTrophy = false,
  });

  final JourneyWorld world;
  final JourneyRank rank;
  /// Newly unlocked Journey face avatar id (`journey_…`).
  final String? avatarId;
  /// Newly unlocked play theme (usually the next world after an Ace).
  final String? themeId;
  /// When true, also show the Ace trophy card art (Ace victories).
  final bool showTrophy;

  bool get hasContent =>
      (avatarId != null && avatarId!.isNotEmpty) ||
      (themeId != null && themeId!.isNotEmpty) ||
      showTrophy;

  Map<String, dynamic> toJson() => {
    'world': world.name,
    'rank': rank.name,
    if (avatarId != null) 'avatarId': avatarId,
    if (themeId != null) 'themeId': themeId,
    if (showTrophy) 'showTrophy': true,
  };

  static JourneyUnlockReward? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final worldName = json['world'] as String?;
    final rankName = json['rank'] as String?;
    if (worldName == null || rankName == null) return null;
    JourneyWorld? world;
    JourneyRank? rank;
    for (final w in JourneyWorld.values) {
      if (w.name == worldName) world = w;
    }
    for (final r in JourneyRank.values) {
      if (r.name == rankName) rank = r;
    }
    if (world == null || rank == null) return null;
    final reward = JourneyUnlockReward(
      world: world,
      rank: rank,
      avatarId: json['avatarId'] as String?,
      themeId: json['themeId'] as String?,
      showTrophy: json['showTrophy'] == true || rank == JourneyRank.ace,
    );
    return reward.hasContent ? reward : null;
  }
}

/// Persisted Journey board progress + pending match/taunt flags.
class JourneyProgress {
  JourneyProgress({
    Map<String, List<String>>? defeatedByWorld,
    Set<String>? enteredWorlds,
    this.pendingChallenge,
    this.pendingLossTaunt,
    this.pendingWinCelebration,
    this.pendingReplayPraise,
    this.pendingUnlockReward,
    this.diamondsEntered = false,
    this.diamondsJackUnlocked = false,
    this.diamondsJackIntroSeen = false,
    this.diamondsQueenIntroSeen = false,
    this.diamondsKingIntroSeen = false,
    this.diamondsAceEscapeSeen = false,
    this.clubsJackIntroSeen = false,
    this.clubsJackUnlocked = false,
    this.clubsCourtIntroSeen = false,
    this.clubsAceGiftSeen = false,
    this.pendingClubsAceOffer = false,
    this.clubsCourtMatchWon = false,
    this.heartsJackIntroSeen = false,
    this.heartsJackUnlocked = false,
    this.heartsQueenEscortSeen = false,
    this.heartsKingIntroSeen = false,
    this.heartsAceGiftSeen = false,
    this.pendingHeartsQueenEscort = false,
    this.pendingHeartsAceOffer = false,
    this.spadesJackIntroSeen = false,
    this.spadesJackUnlocked = false,
    this.spadesKingEscortSeen = false,
    this.spadesFinaleSeen = false,
    this.pendingSpadesJackCampDenied = false,
    this.pendingSpadesKingEscort = false,
    this.pendingSpadesKingRetry = false,
    this.pendingSpadesRuins = false,
  }) : defeatedByWorld = {
         for (final e in (defeatedByWorld ?? {}).entries)
           e.key: List<String>.from(e.value),
       },
       enteredWorlds = {...?enteredWorlds};

  factory JourneyProgress.empty() => JourneyProgress();

  factory JourneyProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JourneyProgress.empty();
    final raw = json['defeatedByWorld'];
    final defeated = <String, List<String>>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is! List) return;
        final ranks = <String>[
          for (final item in value)
            if (item is String && item.isNotEmpty) item,
        ];
        if (ranks.isNotEmpty) defeated[key.toString()] = ranks;
      });
    }
    final entered = <String>{};
    final rawEntered = json['enteredWorlds'];
    if (rawEntered is List) {
      for (final item in rawEntered) {
        if (item is String && item.isNotEmpty) entered.add(item);
      }
    }
    final progress = JourneyProgress(
      defeatedByWorld: defeated,
      enteredWorlds: entered,
      pendingChallenge: JourneyChallengeRef.fromJson(
        json['pendingChallenge'] is Map
            ? Map<String, dynamic>.from(json['pendingChallenge'] as Map)
            : null,
      ),
      pendingLossTaunt: JourneyChallengeRef.fromJson(
        json['pendingLossTaunt'] is Map
            ? Map<String, dynamic>.from(json['pendingLossTaunt'] as Map)
            : null,
      ),
      pendingWinCelebration: JourneyChallengeRef.fromJson(
        json['pendingWinCelebration'] is Map
            ? Map<String, dynamic>.from(json['pendingWinCelebration'] as Map)
            : null,
      ),
      pendingReplayPraise: JourneyChallengeRef.fromJson(
        json['pendingReplayPraise'] is Map
            ? Map<String, dynamic>.from(json['pendingReplayPraise'] as Map)
            : null,
      ),
      pendingUnlockReward: JourneyUnlockReward.fromJson(
        json['pendingUnlockReward'] is Map
            ? Map<String, dynamic>.from(json['pendingUnlockReward'] as Map)
            : null,
      ),
      diamondsEntered: json['diamondsEntered'] == true,
      diamondsJackUnlocked: json['diamondsJackUnlocked'] == true,
      diamondsJackIntroSeen: json['diamondsJackIntroSeen'] == true,
      diamondsQueenIntroSeen: json['diamondsQueenIntroSeen'] == true,
      diamondsKingIntroSeen: json['diamondsKingIntroSeen'] == true,
      diamondsAceEscapeSeen: json['diamondsAceEscapeSeen'] == true,
      clubsJackIntroSeen: json['clubsJackIntroSeen'] == true,
      clubsJackUnlocked: json['clubsJackUnlocked'] == true,
      clubsCourtIntroSeen: json['clubsCourtIntroSeen'] == true,
      clubsAceGiftSeen: json['clubsAceGiftSeen'] == true,
      pendingClubsAceOffer: json['pendingClubsAceOffer'] == true,
      clubsCourtMatchWon: json['clubsCourtMatchWon'] == true,
      heartsJackIntroSeen: json['heartsJackIntroSeen'] == true,
      heartsJackUnlocked: json['heartsJackUnlocked'] == true,
      heartsQueenEscortSeen: json['heartsQueenEscortSeen'] == true,
      heartsKingIntroSeen: json['heartsKingIntroSeen'] == true,
      heartsAceGiftSeen: json['heartsAceGiftSeen'] == true,
      pendingHeartsQueenEscort: json['pendingHeartsQueenEscort'] == true,
      pendingHeartsAceOffer: json['pendingHeartsAceOffer'] == true,
      spadesJackIntroSeen: json['spadesJackIntroSeen'] == true,
      spadesJackUnlocked: json['spadesJackUnlocked'] == true,
      spadesKingEscortSeen: json['spadesKingEscortSeen'] == true,
      spadesFinaleSeen: json['spadesFinaleSeen'] == true,
      pendingSpadesJackCampDenied: json['pendingSpadesJackCampDenied'] == true,
      pendingSpadesKingEscort: json['pendingSpadesKingEscort'] == true,
      pendingSpadesKingRetry: json['pendingSpadesKingRetry'] == true,
      pendingSpadesRuins: json['pendingSpadesRuins'] == true,
    );
    // Migrate older saves that already beat Diamonds content.
    if (progress.isDefeated(JourneyWorld.diamonds, JourneyRank.jack) ||
        progress.isDefeated(JourneyWorld.diamonds, JourneyRank.ace)) {
      progress.diamondsEntered = true;
      progress.diamondsJackUnlocked = true;
      progress.diamondsJackIntroSeen = true;
    }
    if (progress.isDefeated(JourneyWorld.diamonds, JourneyRank.queen) ||
        progress.isDefeated(JourneyWorld.diamonds, JourneyRank.king) ||
        progress.isDefeated(JourneyWorld.diamonds, JourneyRank.ace)) {
      progress.diamondsQueenIntroSeen = true;
    }
    if (progress.isDefeated(JourneyWorld.diamonds, JourneyRank.king) ||
        progress.isDefeated(JourneyWorld.diamonds, JourneyRank.ace)) {
      progress.diamondsKingIntroSeen = true;
    }
    if (progress.isDefeated(JourneyWorld.diamonds, JourneyRank.ace)) {
      progress.diamondsAceEscapeSeen = true;
    }
    if (progress.isDefeated(JourneyWorld.clubs, JourneyRank.jack)) {
      progress.clubsJackIntroSeen = true;
      progress.clubsJackUnlocked = true;
    }
    if (progress.isDefeated(JourneyWorld.clubs, JourneyRank.ace)) {
      progress.clubsCourtIntroSeen = true;
      progress.clubsJackUnlocked = true;
      progress.clubsJackIntroSeen = true;
      // Older saves already past Clubs Ace — skip gift dialogue hold.
      if (json['clubsAceGiftSeen'] == null) {
        progress.clubsAceGiftSeen = true;
      }
    }
    if (progress.isDefeated(JourneyWorld.hearts, JourneyRank.jack)) {
      progress.heartsJackIntroSeen = true;
      progress.heartsJackUnlocked = true;
    }
    if (progress.isDefeated(JourneyWorld.hearts, JourneyRank.queen) ||
        progress.isDefeated(JourneyWorld.hearts, JourneyRank.king) ||
        progress.isDefeated(JourneyWorld.hearts, JourneyRank.ace)) {
      progress.heartsQueenEscortSeen = true;
    }
    if (progress.isDefeated(JourneyWorld.hearts, JourneyRank.king) ||
        progress.isDefeated(JourneyWorld.hearts, JourneyRank.ace)) {
      progress.heartsKingIntroSeen = true;
    }
    if (progress.isDefeated(JourneyWorld.hearts, JourneyRank.ace)) {
      if (json['heartsAceGiftSeen'] == null) {
        progress.heartsAceGiftSeen = true;
      }
    }
    if (progress.isDefeated(JourneyWorld.spades, JourneyRank.jack)) {
      progress.spadesJackIntroSeen = true;
      progress.spadesJackUnlocked = true;
    }
    if (progress.isDefeated(JourneyWorld.spades, JourneyRank.king) ||
        progress.isDefeated(JourneyWorld.spades, JourneyRank.ace)) {
      progress.spadesKingEscortSeen = true;
    }
    if (progress.isDefeated(JourneyWorld.spades, JourneyRank.ace)) {
      if (json['spadesFinaleSeen'] == null) {
        progress.spadesFinaleSeen = true;
      }
    }
    if (progress.diamondsEntered) {
      progress.enteredWorlds.add(JourneyWorld.diamonds.name);
    }
    // Already past the Jack unlock — don't replay the intro conversation.
    if (progress.diamondsJackUnlocked) {
      progress.diamondsJackIntroSeen = true;
    }
    // Any fight in a world counts as having entered that kingdom.
    for (final world in JourneyWorld.values) {
      if (progress.defeatedRanksFor(world).isNotEmpty) {
        progress.enteredWorlds.add(world.name);
      }
    }
    return progress;
  }

  final Map<String, List<String>> defeatedByWorld;
  /// Kingdoms the player has entered (theme unlock + board access for Diamonds).
  final Set<String> enteredWorlds;
  JourneyChallengeRef? pendingChallenge;
  JourneyChallengeRef? pendingLossTaunt;
  /// Defeated challenger awaiting instruction unlock + next-card reveal.
  JourneyChallengeRef? pendingWinCelebration;
  /// Replay win: praise dialog only (no journey unlock / instruction).
  JourneyChallengeRef? pendingReplayPraise;
  /// Avatar / theme unlocks to show after coins & XP.
  JourneyUnlockReward? pendingUnlockReward;
  /// Player confirmed Enter Diamonds kingdom (theme + world unlocked).
  bool diamondsEntered;
  /// Prove-yourself CTA revealed the Diamonds Jack face-up.
  bool diamondsJackUnlocked;
  /// Jack intro conversation after profile tutorial has been shown.
  bool diamondsJackIntroSeen;
  /// Queen intro conversation after defeating Diamonds Jack.
  bool diamondsQueenIntroSeen;
  /// King intro conversation after defeating Diamonds Queen.
  bool diamondsKingIntroSeen;
  /// Escape dialogue after claiming the Diamonds Ace.
  bool diamondsAceEscapeSeen;
  /// Clubs Jack bushes intro after entering Clubs.
  bool clubsJackIntroSeen;
  /// Clubs Jack stays mystery-hidden until the bushes Challenge unlocks him.
  bool clubsJackUnlocked;
  /// Court conversation after beating Clubs Jack (before King table match).
  bool clubsCourtIntroSeen;
  /// Post-match Ace gift dialogue finished (gates Hearts road letter).
  bool clubsAceGiftSeen;
  /// Clubs court table finished — King offers Ace (before Claim).
  bool pendingClubsAceOffer;
  /// Whether the player won the Clubs court table (flavor line only).
  bool clubsCourtMatchWon;
  bool heartsJackIntroSeen;
  bool heartsJackUnlocked;
  bool heartsQueenEscortSeen;
  bool heartsKingIntroSeen;
  bool heartsAceGiftSeen;
  bool pendingHeartsQueenEscort;
  bool pendingHeartsAceOffer;
  bool spadesJackIntroSeen;
  bool spadesJackUnlocked;
  bool spadesKingEscortSeen;
  bool spadesFinaleSeen;
  bool pendingSpadesJackCampDenied;
  bool pendingSpadesKingEscort;
  bool pendingSpadesKingRetry;
  bool pendingSpadesRuins;

  bool hasEntered(JourneyWorld world) {
    if (enteredWorlds.contains(world.name)) return true;
    if (world == JourneyWorld.diamonds && diamondsEntered) return true;
    return defeatedRanksFor(world).isNotEmpty;
  }

  void markEntered(JourneyWorld world) {
    enteredWorlds.add(world.name);
    if (world == JourneyWorld.diamonds) diamondsEntered = true;
  }

  /// Play-locked theme may unlock after the prior Ace (Diamonds: anytime)
  /// and only once [playerLevel] meets that world's required level.
  bool canUnlockThemeFor(JourneyWorld world, {required int playerLevel}) {
    if (playerLevel < world.requiredLevel) return false;
    if (world == JourneyWorld.diamonds) return true;
    final idx = JourneyWorld.values.indexOf(world);
    if (idx <= 0) return false;
    return isDefeated(JourneyWorld.values[idx - 1], JourneyRank.ace);
  }

  List<JourneyRank> defeatedRanksFor(JourneyWorld world) {
    final raw = defeatedByWorld[world.name] ?? const <String>[];
    final out = <JourneyRank>[];
    for (final name in raw) {
      for (final rank in JourneyRank.values) {
        if (rank.name == name) {
          out.add(rank);
          break;
        }
      }
    }
    return out;
  }

  bool isDefeated(JourneyWorld world, JourneyRank rank) {
    return defeatedRanksFor(world).contains(rank);
  }

  /// Worlds whose Ace has been claimed (avatar suit accessories).
  Set<JourneyWorld> get defeatedAceWorlds => {
        for (final world in JourneyWorld.values)
          if (isDefeated(world, JourneyRank.ace)) world,
      };

  /// Trail steps completed (Jack–Ace across four kingdoms), 0…16.
  int get trailStepsCompleted {
    var n = 0;
    for (final world in JourneyWorld.values) {
      n += defeatedRanksFor(world).length;
    }
    return n.clamp(0, journeyTrailStepCount);
  }

  double get trailProgress => trailStepsCompleted / journeyTrailStepCount;

  /// Append [rank] for [world] if not already recorded (order preserved).
  void recordDefeat(JourneyWorld world, JourneyRank rank) {
    final list = defeatedByWorld.putIfAbsent(world.name, () => <String>[]);
    if (!list.contains(rank.name)) list.add(rank.name);
    enteredWorlds.add(world.name);
  }

  /// Remove [rank] and any later ranks in that world (progression must stay ordered).
  void clearDefeat(JourneyWorld world, JourneyRank rank) {
    final list = defeatedByWorld[world.name];
    if (list == null || list.isEmpty) return;
    final order = JourneyRank.values;
    final idx = order.indexOf(rank);
    if (idx < 0) return;
    list.removeWhere((name) {
      final rIdx = order.indexWhere((r) => r.name == name);
      return rIdx < 0 || rIdx >= idx;
    });
    if (list.isEmpty) defeatedByWorld.remove(world.name);
  }

  Map<String, dynamic> toJson() => {
    'defeatedByWorld': {
      for (final e in defeatedByWorld.entries)
        if (e.value.isNotEmpty) e.key: List<String>.from(e.value),
    },
    if (pendingChallenge != null) 'pendingChallenge': pendingChallenge!.toJson(),
    if (pendingLossTaunt != null) 'pendingLossTaunt': pendingLossTaunt!.toJson(),
    if (pendingWinCelebration != null)
      'pendingWinCelebration': pendingWinCelebration!.toJson(),
    if (pendingReplayPraise != null)
      'pendingReplayPraise': pendingReplayPraise!.toJson(),
    if (pendingUnlockReward != null)
      'pendingUnlockReward': pendingUnlockReward!.toJson(),
    'diamondsEntered': diamondsEntered,
    'diamondsJackUnlocked': diamondsJackUnlocked,
    'diamondsJackIntroSeen': diamondsJackIntroSeen,
    'diamondsQueenIntroSeen': diamondsQueenIntroSeen,
    'diamondsKingIntroSeen': diamondsKingIntroSeen,
    'diamondsAceEscapeSeen': diamondsAceEscapeSeen,
    'clubsJackIntroSeen': clubsJackIntroSeen,
    'clubsJackUnlocked': clubsJackUnlocked,
    'clubsCourtIntroSeen': clubsCourtIntroSeen,
    'clubsAceGiftSeen': clubsAceGiftSeen,
    'pendingClubsAceOffer': pendingClubsAceOffer,
    'clubsCourtMatchWon': clubsCourtMatchWon,
    'heartsJackIntroSeen': heartsJackIntroSeen,
    'heartsJackUnlocked': heartsJackUnlocked,
    'heartsQueenEscortSeen': heartsQueenEscortSeen,
    'heartsKingIntroSeen': heartsKingIntroSeen,
    'heartsAceGiftSeen': heartsAceGiftSeen,
    'pendingHeartsQueenEscort': pendingHeartsQueenEscort,
    'pendingHeartsAceOffer': pendingHeartsAceOffer,
    'spadesJackIntroSeen': spadesJackIntroSeen,
    'spadesJackUnlocked': spadesJackUnlocked,
    'spadesKingEscortSeen': spadesKingEscortSeen,
    'spadesFinaleSeen': spadesFinaleSeen,
    'pendingSpadesJackCampDenied': pendingSpadesJackCampDenied,
    'pendingSpadesKingEscort': pendingSpadesKingEscort,
    'pendingSpadesKingRetry': pendingSpadesKingRetry,
    'pendingSpadesRuins': pendingSpadesRuins,
    if (enteredWorlds.isNotEmpty) 'enteredWorlds': enteredWorlds.toList(),
  };
}

/// Rebuild the board from the static snapshot + stored defeats + level.
///
/// When a pending win celebration exists (and [deferPendingWin] is true), the
/// next challenger after that defeat stays locked until the unlock CTA runs.
JourneyDisplaySnapshot hydrateJourneyBoard({
  required JourneyProgress progress,
  required int playerLevel,
  bool deferPendingWin = true,
}) {
  var snap = journeyBoardSnapshot;
  for (final world in JourneyWorld.values) {
    final defeated = progress.defeatedRanksFor(world);
    for (final rank in defeated) {
      final result = snap.withDefeat(world, rank, playerLevel: playerLevel);
      snap = JourneyDisplaySnapshot(worlds: result.worlds);
    }
  }
  snap = snap.withLevelApplied(playerLevel);
  snap = snap.withDiamondsGates(
    entered: progress.diamondsEntered,
    jackUnlocked: progress.diamondsJackUnlocked,
    playerLevel: playerLevel,
  );
  snap = snap.withClubsGates(
    jackUnlocked: progress.clubsJackUnlocked,
    aceClaimed: progress.isDefeated(JourneyWorld.clubs, JourneyRank.ace),
    courtIntroSeen: progress.clubsCourtIntroSeen,
    playerLevel: playerLevel,
  );
  snap = snap.withHeartsGates(
    jackUnlocked: progress.heartsJackUnlocked,
    aceClaimed: progress.isDefeated(JourneyWorld.hearts, JourneyRank.ace),
    playerLevel: playerLevel,
  );
  snap = snap.withSpadesGates(
    jackUnlocked: progress.spadesJackUnlocked,
    aceClaimed: progress.isDefeated(JourneyWorld.spades, JourneyRank.ace),
    kingAvailable: progress.spadesKingEscortSeen ||
        progress.pendingSpadesKingRetry ||
        progress.isDefeated(JourneyWorld.spades, JourneyRank.king),
    playerLevel: playerLevel,
  );
  final defer =
      deferPendingWin ? progress.pendingWinCelebration : null;
  if (defer != null) {
    snap = snap.withDeferredNext(defer);
  }
  snap = snap.withWorldLevelGates(
    progress: progress,
    playerLevel: playerLevel,
  );
  return snap;
}

extension on JourneyDisplaySnapshot {
  /// Seal or open kingdom piles from level + prior-Ace story gates.
  JourneyDisplaySnapshot withWorldLevelGates({
    required JourneyProgress progress,
    required int playerLevel,
  }) {
    return JourneyDisplaySnapshot(
      worlds: [
        for (final w in worlds)
          _worldWithLevelGate(w, progress: progress, playerLevel: playerLevel),
      ],
    );
  }

  JourneyWorldDef _worldWithLevelGate(
    JourneyWorldDef w, {
    required JourneyProgress progress,
    required int playerLevel,
  }) {
    final levelOk = playerLevel >= w.world.requiredLevel;
    if (w.world == JourneyWorld.diamonds) {
      // Entered state is owned by withDiamondsGates; only enforce level here.
      if (!levelOk && w.unlocked) {
        return w.copyWith(unlocked: false);
      }
      return w;
    }
    final idx = JourneyWorld.values.indexOf(w.world);
    final priorAce = idx > 0 &&
        progress.isDefeated(JourneyWorld.values[idx - 1], JourneyRank.ace);
    final shouldUnlock = priorAce && levelOk;
    if (shouldUnlock == w.unlocked) return w;
    if (!shouldUnlock) {
      return w.copyWith(unlocked: false);
    }
    return w.copyWith(
      unlocked: true,
      cards: [
        for (final c in w.cards)
          if (c.rank == JourneyRank.jack &&
              c.state != JourneyCardState.defeated)
            c.copyWith(
              state: playerLevel >= (c.requiredLevel ?? 1)
                  ? JourneyCardState.available
                  : JourneyCardState.levelLocked,
            )
          else
            c,
      ],
    );
  }

  /// Apply first-kingdom tutorial gates before the Jack is playable.
  JourneyDisplaySnapshot withDiamondsGates({
    required bool entered,
    required bool jackUnlocked,
    int playerLevel = 1,
  }) {
    return JourneyDisplaySnapshot(
      worlds: [
        for (final w in worlds)
          if (w.world != JourneyWorld.diamonds)
            w
          else if (!entered)
            w.copyWith(
              unlocked: false,
              cards: [
                for (final c in w.cards)
                  if (c.rank == JourneyRank.jack)
                    c.copyWith(state: JourneyCardState.levelLocked)
                  else if (c.state == JourneyCardState.available)
                    c.copyWith(state: JourneyCardState.levelLocked)
                  else
                    c,
              ],
            )
          else if (!jackUnlocked)
            w.copyWith(
              unlocked: true,
              cards: [
                for (final c in w.cards)
                  if (c.rank == JourneyRank.jack &&
                      c.state != JourneyCardState.defeated)
                    c.copyWith(state: JourneyCardState.levelLocked)
                  else
                    c,
              ],
            )
          else
            // Snapshot starts locked; re-apply level once both gates clear.
            w.copyWith(unlocked: true).withLevelApplied(playerLevel),
      ],
    );
  }

  /// Clubs Jack stays hidden until Challenge; Queen stays locked until Ace.
  /// King unlocks after the court intro so the table can be re-challenged.
  JourneyDisplaySnapshot withClubsGates({
    required bool jackUnlocked,
    required bool aceClaimed,
    bool courtIntroSeen = false,
    int playerLevel = 1,
  }) {
    return JourneyDisplaySnapshot(
      worlds: [
        for (final w in worlds)
          if (w.world != JourneyWorld.clubs)
            w
          else if (!w.unlocked)
            w
          else if (!jackUnlocked)
            w.copyWith(
              unlocked: true,
              cards: [
                for (final c in w.cards)
                  if (c.state != JourneyCardState.defeated)
                    c.copyWith(state: JourneyCardState.mysteryLocked)
                  else
                    c,
              ],
            )
          else if (!aceClaimed)
            w.copyWith(
              unlocked: true,
              cards: [
                for (final c in w.cards)
                  if (c.rank == JourneyRank.jack)
                    c.state == JourneyCardState.defeated
                        ? c
                        : c.copyWith(
                            state: playerLevel >= (c.requiredLevel ?? 1)
                                ? JourneyCardState.available
                                : JourneyCardState.levelLocked,
                          )
                  else if (c.rank == JourneyRank.king &&
                      courtIntroSeen &&
                      c.state != JourneyCardState.defeated)
                    c.copyWith(
                      state: playerLevel >= (c.requiredLevel ?? 1)
                          ? JourneyCardState.available
                          : JourneyCardState.levelLocked,
                    )
                  else if (c.state != JourneyCardState.defeated)
                    c.copyWith(state: JourneyCardState.mysteryLocked)
                  else
                    c,
              ],
            )
          else
            w.copyWith(unlocked: true).withLevelApplied(playerLevel),
      ],
    );
  }

  /// Hearts Jack stays hidden until Challenge; Ace stays mystery until gift claim.
  JourneyDisplaySnapshot withHeartsGates({
    required bool jackUnlocked,
    required bool aceClaimed,
    int playerLevel = 1,
  }) {
    return JourneyDisplaySnapshot(
      worlds: [
        for (final w in worlds)
          if (w.world != JourneyWorld.hearts)
            w
          else if (!w.unlocked)
            w
          else if (!jackUnlocked)
            w.copyWith(
              unlocked: true,
              cards: [
                for (final c in w.cards)
                  if (c.state != JourneyCardState.defeated)
                    c.copyWith(state: JourneyCardState.mysteryLocked)
                  else
                    c,
              ],
            )
          else if (!aceClaimed)
            () {
              final leveled =
                  w.copyWith(unlocked: true).withLevelApplied(playerLevel);
              return leveled.copyWith(
                cards: [
                  for (final c in leveled.cards)
                    if (c.rank == JourneyRank.ace &&
                        c.state != JourneyCardState.defeated)
                      c.copyWith(state: JourneyCardState.mysteryLocked)
                    else
                      c,
                ],
              );
            }()
          else
            w.copyWith(unlocked: true).withLevelApplied(playerLevel),
      ],
    );
  }

  /// Spades Jack stays hidden until Challenge; Ace mystery until claim.
  /// King stays available once unlocked (escort / retry / defeat).
  JourneyDisplaySnapshot withSpadesGates({
    required bool jackUnlocked,
    required bool aceClaimed,
    bool kingAvailable = false,
    int playerLevel = 1,
  }) {
    return JourneyDisplaySnapshot(
      worlds: [
        for (final w in worlds)
          if (w.world != JourneyWorld.spades)
            w
          else if (!w.unlocked)
            w
          else if (!jackUnlocked)
            w.copyWith(
              unlocked: true,
              cards: [
                for (final c in w.cards)
                  if (c.state != JourneyCardState.defeated)
                    c.copyWith(state: JourneyCardState.mysteryLocked)
                  else
                    c,
              ],
            )
          else if (!aceClaimed)
            () {
              final leveled =
                  w.copyWith(unlocked: true).withLevelApplied(playerLevel);
              return leveled.copyWith(
                cards: [
                  for (final c in leveled.cards)
                    if (c.rank == JourneyRank.ace &&
                        c.state != JourneyCardState.defeated)
                      c.copyWith(state: JourneyCardState.mysteryLocked)
                    else if (c.rank == JourneyRank.king &&
                        c.state != JourneyCardState.defeated)
                      kingAvailable
                          ? c.copyWith(
                              state: playerLevel >= (c.requiredLevel ?? 1)
                                  ? JourneyCardState.available
                                  : JourneyCardState.levelLocked,
                            )
                          : c.copyWith(state: JourneyCardState.mysteryLocked)
                    else
                      c,
                ],
              );
            }()
          else
            w.copyWith(unlocked: true).withLevelApplied(playerLevel),
      ],
    );
  }

  JourneyDisplaySnapshot withDeferredNext(JourneyChallengeRef defeated) {
    if (defeated.rank == JourneyRank.ace) {
      final idx = JourneyWorld.values.indexOf(defeated.world);
      if (idx < 0 || idx + 1 >= JourneyWorld.values.length) return this;
      final nextWorld = JourneyWorld.values[idx + 1];
      return JourneyDisplaySnapshot(
        worlds: [
          for (final w in worlds)
            if (w.world != nextWorld)
              w
            else
              w.copyWith(
                cards: [
                  for (final c in w.cards)
                    if (c.rank == JourneyRank.jack)
                      c.copyWith(state: JourneyCardState.levelLocked)
                    else
                      c,
                ],
              ),
        ],
      );
    }
    final next = defeated.rank.next;
    if (next == null) return this;
    // Story-only ranks (e.g. Spades Queen) are not on the pile — nothing to defer.
    if (worldOf(defeated.world).cardOf(next) == null) return this;
    return JourneyDisplaySnapshot(
      worlds: [
        for (final w in worlds)
          if (w.world != defeated.world)
            w
          else
            w.copyWith(
              cards: [
                for (final c in w.cards)
                  if (c.rank == next)
                    c.copyWith(
                      state: next == JourneyRank.ace
                          ? JourneyCardState.mysteryLocked
                          : JourneyCardState.levelLocked,
                    )
                  else
                    c,
              ],
            ),
      ],
    );
  }
}

/// Next card that should unlock after [defeated] (from a fully promoted board).
JourneyCardDef? journeyNextAfterDefeat({
  required JourneyProgress progress,
  required int playerLevel,
  required JourneyChallengeRef defeated,
}) {
  final full = hydrateJourneyBoard(
    progress: progress,
    playerLevel: playerLevel,
    deferPendingWin: false,
  );
  if (defeated.rank == JourneyRank.ace) {
    final idx = JourneyWorld.values.indexOf(defeated.world);
    if (idx < 0 || idx + 1 >= JourneyWorld.values.length) return null;
    return full.worldOf(JourneyWorld.values[idx + 1]).cardOf(JourneyRank.jack);
  }
  final next = defeated.rank.next;
  if (next == null) return null;
  return full.worldOf(defeated.world).cardOf(next);
}
