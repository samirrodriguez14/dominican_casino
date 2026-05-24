class InstructionsData {
  final String title;
  final List<InstructionSection> sections;

  InstructionsData({
    required this.title,
    required this.sections,
  });

  factory InstructionsData.fromJson(Map<String, dynamic> json) {
    return InstructionsData(
      title: json['title'],
      sections: (json['sections'] as List)
          .map((s) => InstructionSection.fromJson(s))
          .toList(),
    );
  }
}

class InstructionSection {
  final String title;
  final List<String> body;
  final List<InstructionSpecialCard> specialCards;

  InstructionSection({
    required this.title,
    required this.body,
    required this.specialCards,
  });

  factory InstructionSection.fromJson(Map<String, dynamic> json) {
    return InstructionSection(
      title: json['title'],
      body: List<String>.from(json['body'] ?? []),
      specialCards: (json['specialCards'] as List? ?? [])
          .map((c) => InstructionSpecialCard.fromJson(c))
          .toList(),
    );
  }
}

class InstructionSpecialCard {
  final String rank;
  final String suit;
  final String label;
  final String points;

  InstructionSpecialCard({
    required this.rank,
    required this.suit,
    required this.label,
    required this.points,
  });

  factory InstructionSpecialCard.fromJson(Map<String, dynamic> json) {
    return InstructionSpecialCard(
      rank: json['rank'],
      suit: json['suit'],
      label: json['label'],
      points: json['points'],
    );
  }
}