import 'package:dominican_casino/style/journey_worlds.dart';

/// Public ranking snapshot stored at `publicProfiles/{uid}`.
class PublicProfile {
  const PublicProfile({
    required this.uid,
    this.name,
    this.avatarId,
    this.wins = 0,
    this.league,
    this.leagueExitRanks = const {},
  });

  final String uid;
  final String? name;
  final String? avatarId;
  final int wins;

  /// Highest unlocked suit league (`diamonds`…`spades`), or null if locked.
  final JourneyWorld? league;

  /// Rank when the player left each prior league (`world.name` → 1-based rank).
  final Map<String, int> leagueExitRanks;

  int? exitRankFor(JourneyWorld world) => leagueExitRanks[world.name];

  Map<String, dynamic> toJson() => {
    'name': ?name,
    'avatarId': ?avatarId,
    'wins': wins,
    if (league != null) 'league': league!.name,
    if (leagueExitRanks.isNotEmpty) 'leagueExitRanks': leagueExitRanks,
  };

  factory PublicProfile.fromDoc(String id, Map<String, dynamic> data) {
    final leagueName = data['league'] as String?;
    JourneyWorld? league;
    if (leagueName != null) {
      for (final w in JourneyWorld.values) {
        if (w.name == leagueName) {
          league = w;
          break;
        }
      }
    }
    final exitRaw = data['leagueExitRanks'];
    final exits = <String, int>{};
    if (exitRaw is Map) {
      for (final e in exitRaw.entries) {
        final key = e.key.toString();
        final value = e.value;
        if (key.isEmpty || value is! num) continue;
        exits[key] = value.toInt();
      }
    }
    return PublicProfile(
      uid: id,
      name: data['name'] as String?,
      avatarId: data['avatarId'] as String?,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      league: league,
      leagueExitRanks: exits,
    );
  }
}

/// How a suit page relates to the player's current league membership.
enum LeaguePageStatus {
  /// Entered earlier; show exit rank only (no live tops).
  past,

  /// Current highest entered kingdom; live top-5 + friends.
  current,

  /// Not entered yet; blurred / locked.
  locked,
}

LeaguePageStatus leaguePageStatus({
  required JourneyWorld world,
  required JourneyWorld? currentLeague,
}) {
  if (currentLeague == null) return LeaguePageStatus.locked;
  if (world.index < currentLeague.index) return LeaguePageStatus.past;
  if (world.index == currentLeague.index) return LeaguePageStatus.current;
  return LeaguePageStatus.locked;
}

/// Highest kingdom the player has entered (in league for that journey).
JourneyWorld? highestUnlockedLeague({
  required Set<JourneyWorld> enteredWorlds,
}) {
  JourneyWorld? best;
  for (final world in JourneyWorld.values) {
    if (!enteredWorlds.contains(world)) continue;
    best = world;
  }
  return best;
}

/// Next suit league to unlock (Diamonds if none entered), or null at Spades.
JourneyWorld? nextLeagueToUnlock({
  required Set<JourneyWorld> enteredWorlds,
}) {
  for (final world in JourneyWorld.values) {
    if (!enteredWorlds.contains(world)) return world;
  }
  return null;
}

/// Sort key for league tier (higher = better). Null / unknown → -1.
int leagueTierIndex(JourneyWorld? league) {
  if (league == null) return -1;
  return league.index;
}

/// Sort friends: Spades → Hearts → Clubs → Diamonds → none, then wins desc.
int compareFriendsByLeagueThenWins(PublicProfile a, PublicProfile b) {
  final tierCmp = leagueTierIndex(b.league).compareTo(leagueTierIndex(a.league));
  if (tierCmp != 0) return tierCmp;
  return b.wins.compareTo(a.wins);
}

/// Rank among peers: 1 + count of players with strictly more wins.
int leagueRankFromHigherWinCount(int playersWithMoreWins) =>
    playersWithMoreWins + 1;
