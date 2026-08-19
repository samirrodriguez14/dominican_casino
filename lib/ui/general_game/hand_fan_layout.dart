/// Shared overlap fan layout for player and opponent hands.
///
/// Keeps cards inside [maxWidth] while allowing a visual [visualScale]
/// (celebration / turn highlight) by tightening the step between cards and,
/// when allowed, shrinking card width.
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

  /// Scaled visual width of the whole fan (used for screen-fit math).
  double visualFootprint(int count, {double visualScale = 1.0}) {
    if (count <= 0) return 0;
    if (count == 1) return cardWidth * visualScale;
    return cardWidth * visualScale + (count - 1) * gap;
  }

  /// Nearest fan index for a drag point in the hand stack's local coords.
  int indexAtLocalX(double localX, int count) {
    if (count <= 1) return 0;
    final half = cardWidth / 2;
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < count; i++) {
      final center = i * gap + half;
      final dist = (localX - center).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
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

  /// Step between card left edges so a scaled fan fits in [maxWidth].
  static double gapToFit({
    required int count,
    required double maxWidth,
    required double cardWidth,
    double visualScale = 1.0,
  }) {
    if (count <= 1) return 0;
    return (maxWidth - cardWidth * visualScale) / (count - 1);
  }

  /// Default horizontal inset so scaled fans stay inside narrow screens.
  static const double defaultWidthMargin = 0.96;

  /// Every pair of cards beyond the first pulls spacing in a little more.
  static double progressiveTightenScale(
    int count, {
    double perPair = 0.055,
  }) {
    if (count <= 2) return 1.0;
    final pairs = (count - 1) ~/ 2;
    return (1.0 - pairs * perPair).clamp(0.62, 1.0);
  }

  /// Tighter fan defaults for the top opponent row (small card backs).
  static const double opponentTopMaxGap = 16.0;
  static const double opponentTopCelebratingMaxGap = 20.0;
  static const double opponentTopTightenPerPair = 0.085;
  static const double opponentTopWidthMargin = 0.93;

  static HandFanLayout fitOpponentTop({
    required int count,
    required double maxWidth,
    required double cardWidth,
    double visualScale = 1.0,
    bool celebrating = false,
  }) {
    return fit(
      count: count,
      maxWidth: maxWidth,
      preferredCardWidth: cardWidth,
      maxGap: celebrating ? opponentTopCelebratingMaxGap : opponentTopMaxGap,
      visualScale: visualScale,
      lockCardSize: true,
      progressiveTighten: true,
      tightenPerPair: opponentTopTightenPerPair,
      widthMargin: opponentTopWidthMargin,
    );
  }

  static HandFanLayout fit({
    required int count,
    required double maxWidth,
    required double preferredCardWidth,
    double minGap = 12.0,
    double maxGap = 56.0,
    double minCardWidth = 48.0,
    double visualScale = 1.0,
    bool lockCardSize = false,
    bool progressiveTighten = false,
    double widthMargin = defaultWidthMargin,
    double tightenPerPair = 0.055,
  }) {
    if (count <= 0) {
      return HandFanLayout(cardWidth: preferredCardWidth, gap: 0);
    }
    if (count == 1) {
      if (lockCardSize || preferredCardWidth * visualScale <= maxWidth) {
        return HandFanLayout(cardWidth: preferredCardWidth, gap: 0);
      }
      final w = (maxWidth / visualScale)
          .clamp(minCardWidth, preferredCardWidth);
      return HandFanLayout(cardWidth: w, gap: 0);
    }

    if (lockCardSize) {
      final cardW = preferredCardWidth;
      final budget = maxWidth * widthMargin;
      var gap = gapToFit(
        count: count,
        maxWidth: budget,
        cardWidth: cardW,
        visualScale: visualScale,
      );
      if (progressiveTighten) {
        gap *= progressiveTightenScale(count, perPair: tightenPerPair);
      }
      if (gap > maxGap) gap = maxGap;
      return HandFanLayout(cardWidth: cardW, gap: gap);
    }

    final budget = progressiveTighten ? maxWidth * widthMargin : maxWidth;
    var cardW = preferredCardWidth;
    var gap = gapToFit(
      count: count,
      maxWidth: budget,
      cardWidth: cardW,
      visualScale: visualScale,
    );
    if (progressiveTighten) {
      gap *= progressiveTightenScale(count, perPair: tightenPerPair);
    }

    if (gap >= minGap) {
      return HandFanLayout(
        cardWidth: cardW,
        gap: gap.clamp(minGap, maxGap),
      );
    }

    gap = minGap;
    cardW = ((maxWidth - (count - 1) * gap) / visualScale)
        .clamp(minCardWidth, preferredCardWidth);
    gap = gapToFit(
      count: count,
      maxWidth: maxWidth,
      cardWidth: cardW,
      visualScale: visualScale,
    ).clamp(minGap, maxGap);

    return HandFanLayout(cardWidth: cardW, gap: gap);
  }
}
