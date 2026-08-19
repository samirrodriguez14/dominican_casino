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
  final String description;
  final List<String> body;
  final List<InstructionFact> facts;
  final List<InstructionSpecialCard> specialCards;
  final List<InstructionCardGroup> cardGroups;
  final bool showCardsFirst;

  InstructionSection({
    required this.title,
    required this.description,
    required this.body,
    required this.facts,
    required this.specialCards,
    required this.cardGroups,
    this.showCardsFirst = false,
  });

  factory InstructionSection.fromJson(Map<String, dynamic> json) {
    return InstructionSection(
      title: json['title'],
      description: (json['description'] as String?) ?? '',
      body: List<String>.from(json['body'] ?? []),
      facts: (json['facts'] as List? ?? [])
          .map((f) => InstructionFact.fromJson(f))
          .toList(),
      specialCards: (json['specialCards'] as List? ?? [])
          .map((c) => InstructionSpecialCard.fromJson(c))
          .toList(),
      cardGroups: (json['cardGroups'] as List? ?? [])
          .map((g) => InstructionCardGroup.fromJson(g))
          .toList(),
      showCardsFirst: json['showCardsFirst'] == true,
    );
  }
}

class InstructionFact {
  final String label;
  final String value;

  InstructionFact({
    required this.label,
    required this.value,
  });

  factory InstructionFact.fromJson(Map<String, dynamic> json) {
    return InstructionFact(
      label: json['label'] as String,
      value: json['value'] as String,
    );
  }
}

class InstructionCardGroup {
  final String label;
  final List<InstructionSpecialCard> cards;

  InstructionCardGroup({
    required this.label,
    required this.cards,
  });

  factory InstructionCardGroup.fromJson(Map<String, dynamic> json) {
    return InstructionCardGroup(
      label: (json['label'] as String?) ?? '',
      cards: (json['cards'] as List? ?? [])
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
      label: (json['label'] as String?) ?? '',
      points: (json['points'] as String?) ?? '',
    );
  }
}
