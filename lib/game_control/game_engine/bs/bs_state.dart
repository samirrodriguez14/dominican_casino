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

  /// How long others have to Call BS after claim cards have landed.
  static const Duration challengeWindow = Duration(seconds: 5);

  /// Bots Call BS this long after the challenge window opens (cards landed).
  static const Duration botCallDelay = Duration(milliseconds: 2500);

  /// Brief beat after "BS!" before flipping the claim cards.
  static const Duration afterCallBeforeReveal = Duration(milliseconds: 700);

  /// Claim cards stay face-up before the Honest/Bluffing banner.
  static const Duration revealCardsHold = Duration(milliseconds: 1400);

  /// Banner stays up before the pile gathers and collects to a hand.
  static const Duration verdictBannerHold = Duration(milliseconds: 2000);

  /// Claim cards flip face-down and tuck back into the center pile.
  static const Duration gatherPileHold = Duration(milliseconds: 480);

  /// Beat after pile lands, before the next turn is emphasized.
  static const Duration afterCollectDelay = Duration(milliseconds: 900);

  /// Extra think time before a bot plays on their turn.
  static const Duration botPlayDelay = Duration(milliseconds: 1600);

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
