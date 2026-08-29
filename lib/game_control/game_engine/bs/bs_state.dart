/// BS-specific match state (claim + challenge window).
enum BsPhase { turn, challenge, resolve }

class BsState {
  BsState({
    this.phase = BsPhase.turn,
    List<String>? pileCardIds,
    List<String>? lastPlayedCardIds,
    this.lastClaimPid,
    this.lastClaimCount = 0,
    this.lastClaimRank,
    this.challengeDeadline,
    this.challengerPid,
    this.wasBluffing,
  })  : pileCardIds = pileCardIds ?? [],
        lastPlayedCardIds = lastPlayedCardIds ?? [];

  BsPhase phase;
  List<String> pileCardIds;
  List<String> lastPlayedCardIds;
  String? lastClaimPid;
  int lastClaimCount;
  String? lastClaimRank;
  DateTime? challengeDeadline;
  String? challengerPid;
  bool? wasBluffing;

  static const Duration challengeWindow = Duration(seconds: 4);

  Map<String, dynamic> toJson() => {
        'phase': phase.name,
        'pileCardIds': pileCardIds,
        'lastPlayedCardIds': lastPlayedCardIds,
        'lastClaimPid': lastClaimPid,
        'lastClaimCount': lastClaimCount,
        'lastClaimRank': lastClaimRank,
        'challengeDeadline': challengeDeadline?.toUtc().toIso8601String(),
        'challengerPid': challengerPid,
        'wasBluffing': wasBluffing,
      };

  static BsState? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    final phaseName = m['phase'] as String?;
    final phase = BsPhase.values.firstWhere(
      (p) => p.name == phaseName,
      orElse: () => BsPhase.turn,
    );
    DateTime? deadline;
    final rawDeadline = m['challengeDeadline'];
    if (rawDeadline is String && rawDeadline.isNotEmpty) {
      deadline = DateTime.tryParse(rawDeadline)?.toUtc();
    }
    return BsState(
      phase: phase,
      pileCardIds: (m['pileCardIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastPlayedCardIds: (m['lastPlayedCardIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastClaimPid: m['lastClaimPid'] as String?,
      lastClaimCount: (m['lastClaimCount'] as num?)?.toInt() ?? 0,
      lastClaimRank: m['lastClaimRank'] as String?,
      challengeDeadline: deadline,
      challengerPid: m['challengerPid'] as String?,
      wasBluffing: m['wasBluffing'] as bool?,
    );
  }

  void clearClaim() {
    phase = BsPhase.turn;
    lastPlayedCardIds = [];
    lastClaimPid = null;
    lastClaimCount = 0;
    lastClaimRank = null;
    challengeDeadline = null;
    challengerPid = null;
    wasBluffing = null;
  }

  void resetRound() {
    clearClaim();
    pileCardIds = [];
  }
}
