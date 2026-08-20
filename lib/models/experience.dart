/// Tunable XP economy and derived level progress.
class ExperienceConfig {
  /// XP awarded for finishing a match as the winner.
  static const int winXp = 25;

  /// XP awarded for finishing a match without winning.
  static const int lossXp = 10;

  /// XP required to advance from [level] to the next.
  static int xpToAdvance(int level) {
    if (level < 1) level = 1;
    return 40 + 20 * (level - 1);
  }

  static int xpForMatch({required bool won}) => won ? winXp : lossXp;
}

/// Snapshot of level progress derived from lifetime [totalXp].
class ExperienceProgress {
  const ExperienceProgress({
    required this.totalXp,
    required this.level,
    required this.xpInLevel,
    required this.xpToNext,
  });

  factory ExperienceProgress.fromTotal(int totalXp) {
    var remaining = totalXp < 0 ? 0 : totalXp;
    var level = 1;
    while (true) {
      final need = ExperienceConfig.xpToAdvance(level);
      if (remaining < need) {
        return ExperienceProgress(
          totalXp: totalXp < 0 ? 0 : totalXp,
          level: level,
          xpInLevel: remaining,
          xpToNext: need,
        );
      }
      remaining -= need;
      level += 1;
    }
  }

  final int totalXp;
  final int level;
  final int xpInLevel;
  final int xpToNext;

  /// 0–1 fill for the avatar ring.
  double get progress => xpToNext <= 0 ? 1 : (xpInLevel / xpToNext).clamp(0.0, 1.0);
}
