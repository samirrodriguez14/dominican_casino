import 'package:barajando/models/game_state.dart';
import 'package:barajando/models/player_match_stats.dart';
import 'package:barajando/models/tutorial_game_modes.dart';

class Player {
  static const String defaultAvatarId = 'palm';

  String id;
  bool completedTutorial;
  bool completedJourneyTutorial;
  bool completedProfileTutorial;
  Set<GameMode> completedGameTutorials;
  String? name;
  String? token;
  String? avatarId;
  int xp;
  PlayerMatchStats matchStats;
  Player({
    required this.id,
    this.name,
    this.token,
    this.avatarId = defaultAvatarId,
    this.completedTutorial = false,
    this.completedJourneyTutorial = false,
    this.completedProfileTutorial = false,
    Set<GameMode>? completedGameTutorials,
    this.xp = 0,
    this.matchStats = PlayerMatchStats.empty,
  }) : completedGameTutorials = completedGameTutorials ?? {};

  factory Player.fromDto(Map<String, dynamic> playerDto) {
    final legacyDone = playerDto['completedTutorial'] == true;
    var tutorials = completedGameTutorialsFromJson(
      playerDto['completedGameTutorials'],
    );
    if (legacyDone && tutorials.isEmpty) {
      tutorials = {GameMode.casino};
    }
    return Player(
      id: playerDto['id'],
      name: playerDto['name'] ?? '',
      token: playerDto['token'],
      avatarId: playerDto['avatarId'] as String? ?? defaultAvatarId,
      completedTutorial: legacyDone || tutorials.isNotEmpty,
      completedJourneyTutorial:
          playerDto['completedJourneyTutorial'] ?? false,
      completedProfileTutorial:
          playerDto['completedProfileTutorial'] ?? false,
      completedGameTutorials: tutorials,
      xp: (playerDto['xp'] as num?)?.toInt() ?? 0,
      matchStats: PlayerMatchStats.fromJson(playerDto['matchStats']),
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'token': token,
    'avatarId': avatarId,
    'completedTutorial': completedTutorial,
    'completedJourneyTutorial': completedJourneyTutorial,
    'completedProfileTutorial': completedProfileTutorial,
    'completedGameTutorials': completedGameTutorialsToJson(
      completedGameTutorials,
    ),
    'xp': xp,
    'matchStats': matchStats.toJson(),
  };

  /// Seat snapshot stored on a game document (no auth/token fields).
  /// Omit nulls — Firestore rejects them on `set()`.
  /// Prefer [AppRepo.buildGameSeat] so avatar art and Journey accessories sync.
  Map<String, dynamic> toGameSeat() => {
    'id': id,
    'name': ?name,
    'avatarId': ?avatarId,
  };

  Player copyWith({
    String? id,
    bool? completedTutorial,
    bool? completedJourneyTutorial,
    bool? completedProfileTutorial,
    Set<GameMode>? completedGameTutorials,
    String? name,
    String? token,
    String? avatarId,
    int? xp,
    PlayerMatchStats? matchStats,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      token: token ?? this.token,
      avatarId: avatarId ?? this.avatarId,
      completedTutorial: completedTutorial ?? this.completedTutorial,
      completedJourneyTutorial:
          completedJourneyTutorial ?? this.completedJourneyTutorial,
      completedProfileTutorial:
          completedProfileTutorial ?? this.completedProfileTutorial,
      completedGameTutorials:
          completedGameTutorials ?? this.completedGameTutorials,
      xp: xp ?? this.xp,
      matchStats: matchStats ?? this.matchStats,
    );
  }

  /// True until the player picks a display name (generated ids look like `p_a1b2c3d4`).
  bool get needsAccountSetup {
    final n = name?.trim();
    if (n == null || n.isEmpty) return true;
    return n.startsWith('p_') && n.length <= 12;
  }
}
