/// Visual seat slots for BS, clockwise from the local player at bottom.
///
/// [oppIds] must be turn order after the local player (i.e. [GeneralGameViewModel.oppIds]):
/// the next seat to act is always index 0.
///
/// Clockwise: leftBottom → leftTop → top → rightTop → rightBottom.
class BsSeatLayout {
  const BsSeatLayout({
    this.leftTop,
    this.leftBottom,
    this.top,
    this.rightTop,
    this.rightBottom,
  });

  final String? leftTop;
  final String? leftBottom;
  final String? top;
  final String? rightTop;
  final String? rightBottom;

  /// Open-seat placeholder when the lobby still shows empty chairs.
  static const openSeat = '';

  factory BsSeatLayout.fromOppIds(
    List<String> oppIds, {
    bool showOpenSeats = false,
  }) {
    String? gap() => showOpenSeats ? openSeat : null;
    final n = oppIds.length;

    switch (n) {
      case 0:
        return BsSeatLayout(
          leftTop: gap(),
          top: gap(),
          rightTop: gap(),
        );
      case 1:
        // Single rival sits across the table.
        return BsSeatLayout(
          top: oppIds[0],
          leftTop: gap(),
          rightTop: gap(),
        );
      case 2:
        return BsSeatLayout(
          leftTop: oppIds[0],
          top: oppIds[1],
          rightTop: gap(),
        );
      case 3:
        // Same left / top / right ring as Tres y Dos & Rummy.
        return BsSeatLayout(
          leftTop: oppIds[0],
          top: oppIds[1],
          rightTop: oppIds[2],
        );
      case 4:
        return BsSeatLayout(
          leftBottom: oppIds[0],
          leftTop: oppIds[1],
          top: oppIds[2],
          rightTop: oppIds[3],
        );
      default:
        // 5 opponents (6 players).
        return BsSeatLayout(
          leftBottom: oppIds[0],
          leftTop: oppIds[1],
          top: oppIds[2],
          rightTop: oppIds[3],
          rightBottom: oppIds[4],
        );
    }
  }

  bool get hasLeft => leftTop != null || leftBottom != null;
  bool get hasRight => rightTop != null || rightBottom != null;
}
