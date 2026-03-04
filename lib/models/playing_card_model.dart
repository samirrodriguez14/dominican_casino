class PlayingCardModel {
  final String suit;
  final String rank;

  PlayingCardModel({required this.suit, required this.rank});

  String get label => '$rank$suit';

  Map<String, dynamic> toMap() => {'suit': suit, 'rank': rank};

  static PlayingCardModel fromMap(Map<String, dynamic> m) =>
      PlayingCardModel(suit: m['suit'] as String, rank: m['rank'] as String);
  List<int> get possibleValues => isAce ? [1, 14] : [valueLow];
  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCardModel &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  bool get isAce => rank.toUpperCase() == 'A';

  int get valueLow => cardRankValue(rank, aceHigh: false); // A = 1
  int get valueHigh => cardRankValue(rank, aceHigh: true); // A = 14

  static int cardRankValue(String rank, {bool aceHigh = false}) {
    final r = rank.trim().toUpperCase();

    if (r == 'A') return aceHigh ? 14 : 1;
    if (r == 'J') return 11;
    if (r == 'Q') return 12;
    if (r == 'K') return 13;

    final n = int.tryParse(r);
    if (n == null) throw ArgumentError('Invalid rank: $rank');
    return n;
  }
}
