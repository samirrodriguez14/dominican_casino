/// Card fan layout inside a Rummy requirement dotted box.
class RummyBoxLayout {
  const RummyBoxLayout({required this.cardWidth, required this.gap});

  final double cardWidth;
  final double gap;

  double get cardHeight => cardWidth * 1.4;

  double totalWidthFor(int count) {
    if (count <= 0) return 0;
    if (count == 1) return cardWidth;
    return cardWidth + (count - 1) * gap;
  }

  /// Usable horizontal space inside the dotted border (padding excluded).
  static const double innerWidth = 156.0;

  /// Inset inside the dotted border.
  static const double borderPad = 6.0;

  /// Largest card width when the box holds few cards.
  static const double maxCardWidth = 58.0;

  static const double minCardWidth = 32.0;
  static const double minGap = 4.0;
  static const double maxGap = 16.0;

  static const double boxWidth = innerWidth + borderPad * 2;
  static const double boxHeight = maxCardWidth * 1.4 + borderPad * 2 + 6;
  static const double stripHeight = boxHeight;

  static RummyBoxLayout forCount(int count) {
    if (count <= 0) {
      return const RummyBoxLayout(cardWidth: maxCardWidth, gap: 0);
    }
    if (count == 1) {
      return const RummyBoxLayout(cardWidth: maxCardWidth, gap: 0);
    }

    var cardW = maxCardWidth;
    var gap = (innerWidth - cardW) / (count - 1);
    if (gap >= minGap) {
      return RummyBoxLayout(cardWidth: cardW, gap: gap.clamp(minGap, maxGap));
    }

    gap = minGap;
    cardW = innerWidth - (count - 1) * gap;
    if (cardW > maxCardWidth) {
      cardW = maxCardWidth;
      gap = ((innerWidth - cardW) / (count - 1)).clamp(minGap, maxGap);
    } else if (cardW < minCardWidth) {
      cardW = minCardWidth;
      gap = ((innerWidth - cardW) / (count - 1)).clamp(minGap, maxGap);
    }

    return RummyBoxLayout(cardWidth: cardW, gap: gap);
  }
}
