import 'package:dominican_casino/models/playing_card_model.dart';

enum RummyKind {
  set,
  run,
  color,
}

enum RummyColor {
  red,
  black,
}

/// A single requirement atom for a Rummy contract.
///
/// Examples:
/// - `set(2)` => two cards of the same rank
/// - `run(4)` => four consecutive ranks (any suits), Ace low or high
/// - `runOf(4, red)` => consecutive ranks, all red suits
/// - `color(5, red)` => five cards of the same color (all red or all black)
class RummyRequirement {
  RummyRequirement({
    required this.kind,
    required this.count,
    this.color,
  }) : assert(count > 0) {
    if (kind == RummyKind.color && color == null) {
      throw ArgumentError('color must be provided for RummyKind.color');
    }
  }

  final RummyKind kind;
  final int count;

  /// Only valid when [kind] is [RummyKind.color].
  final RummyColor? color;

  static RummyRequirement set(int count) => RummyRequirement(
        kind: RummyKind.set,
        count: count,
      );

  static RummyRequirement run(int count) => RummyRequirement(
        kind: RummyKind.run,
        count: count,
      );

  /// Consecutive ranks where every card is red or black per [color].
  static RummyRequirement runOf(int count, RummyColor color) =>
      RummyRequirement(
        kind: RummyKind.run,
        count: count,
        color: color,
      );

  static RummyRequirement colorOf(int count, RummyColor color) =>
      RummyRequirement(
        kind: RummyKind.color,
        count: count,
        color: color,
      );

  String get label => switch (kind) {
        RummyKind.set => 'Set of $count',
        RummyKind.run => color == null
            ? 'Run of $count'
            : 'Run of $count (${color == RummyColor.red ? 'red' : 'black'})',
        RummyKind.color => '${color == RummyColor.red ? 'Red' : 'Black'} of $count',
      };

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'count': count,
        'color': color?.name,
      };

  static RummyRequirement fromJson(Map<String, dynamic> m) {
    final kindName = m['kind'] as String?;
    if (kindName == null) {
      throw ArgumentError('Missing kind in RummyRequirement JSON');
    }
    final kind = RummyKind.values.firstWhere((k) => k.name == kindName);
    final countRaw = m['count'] as num?;
    if (countRaw == null) {
      throw ArgumentError('Missing count in RummyRequirement JSON');
    }
    final count = countRaw.toInt();
    final colorRaw = m['color'] as String?;
    final color = colorRaw == null
        ? null
        : RummyColor.values.firstWhere((c) => c.name == colorRaw);
    return RummyRequirement(
      kind: kind,
      count: count,
      color: color,
    );
  }

  bool matches(List<PlayingCardModel> cards) {
    if (cards.length != count) return false;
    if (count == 1) return true; // v2+ flexibility; v1 uses >=2
    final seenIds = cards.map((c) => c.id).toSet();
    if (seenIds.length != cards.length) return false; // duplicates by id

    return switch (kind) {
      RummyKind.set => _matchesSet(cards),
      RummyKind.run => _matchesRun(cards),
      RummyKind.color => _matchesColor(cards),
    };
  }

  bool _matchesSet(List<PlayingCardModel> cards) {
    final rank = cards.first.rank;
    return cards.every((c) => c.rank == rank);
  }

  bool _matchesColor(List<PlayingCardModel> cards) {
    final expectedRed = color == RummyColor.red;
    return cards.every((c) => _isRedSuit(c.suit) == expectedRed);
  }

  bool _matchesRun(List<PlayingCardModel> cards) {
    if (color != null) {
      final expectedRed = color == RummyColor.red;
      if (!cards.every((c) => _isRedSuit(c.suit) == expectedRed)) {
        return false;
      }
    }

    final aceLow = cards.map((c) => _rankValue(c.rank, aceHigh: false)).toList()
      ..sort();
    if (_isConsecutive(aceLow)) return true;

    final aceHigh = cards.map((c) => _rankValue(c.rank, aceHigh: true)).toList()
      ..sort();
    return _isConsecutive(aceHigh);
  }

  bool _isConsecutive(List<int> sortedValues) {
    // A-2-3 works in aceLow mode; Q-K-A works in aceHigh mode.
    // Wraparound like K-A-2 won't be consecutive in either mode.
    for (var i = 1; i < sortedValues.length; i++) {
      if (sortedValues[i] != sortedValues[i - 1] + 1) return false;
    }
    return true;
  }

  static bool _isRedSuit(String suit) {
    return suit == '♥' || suit == '♦';
  }

  static int _rankValue(String rank, {required bool aceHigh}) {
    // Mirrors PlayingCardModel.valueLow/valueHigh rules.
    final r = rank.trim().toUpperCase();
    if (r == 'A') return aceHigh ? 14 : 1;
    if (r == 'J') return 11;
    if (r == 'Q') return 12;
    if (r == 'K') return 13;
    final n = int.tryParse(r);
    if (n == null) {
      throw ArgumentError('Invalid rank: $rank');
    }
    return n;
  }
}

