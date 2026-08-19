/// Shared overlap fan layout for player and opponent hands.
///
/// Keeps cards inside [maxWidth] while allowing a visual [visualScale]
/// (celebration / turn highlight) by tightening gap and, if needed,
/// shrinking card width.
class HandFanLayout {
  const HandFanLayout({
    required this.cardWidth,
    required this.gap,
  });

  final double cardWidth;
  final double gap;

  double get cardHeight => cardWidth * 1.4;

  double totalWidth(int count) {
    if (count <= 0) return 0;
    if (count == 1) return cardWidth;
    return cardWidth + (count - 1) * gap;
  }

  /// Scale applied on cards during celebration (matches AnimatedScale in UI).
  static const double celebrationScale = 1.08;

  /// Scale applied when a seat is on turn but not yet celebrating.
  static const double turnHighlightScale = 1.02;

  static double visualScale({
    required bool celebrating,
    bool highlightTurn = false,
  }) {
    if (celebrating) return celebrationScale;
    if (highlightTurn) return turnHighlightScale;
    return 1.0;
  }

  static HandFanLayout fit({
    required int count,
    required double maxWidth,
    required double preferredCardWidth,
    double minGap = 12.0,
    double maxGap = 56.0,
    double minCardWidth = 48.0,
    double visualScale = 1.0,
  }) {
    if (count <= 0) {
      return HandFanLayout(cardWidth: preferredCardWidth, gap: 0);
    }
    if (count == 1) {
      final w = preferredCardWidth * visualScale <= maxWidth
          ? preferredCardWidth
          : (maxWidth / visualScale).clamp(minCardWidth, preferredCardWidth);
      return HandFanLayout(cardWidth: w, gap: 0);
    }

    var cardW = preferredCardWidth;
    var gap = (maxWidth - cardW * visualScale) / (count - 1);

    if (gap >= minGap) {
      return HandFanLayout(
        cardWidth: cardW,
        gap: gap.clamp(minGap, maxGap),
      );
    }

    gap = minGap;
    cardW = ((maxWidth - (count - 1) * gap) / visualScale)
        .clamp(minCardWidth, preferredCardWidth);
    gap = ((maxWidth - cardW * visualScale) / (count - 1)).clamp(minGap, maxGap);

    return HandFanLayout(cardWidth: cardW, gap: gap);
  }
}
