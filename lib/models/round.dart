enum RoundStatus { dealing, playing, completed, readyToDeal }

RoundStatus roundStatusFrom(String? s) {
  switch (s) {
    case 'completed':
      return RoundStatus.completed;
    case 'dealing':
      return RoundStatus.dealing;
    case 'playing':
      return RoundStatus.playing;
    case 'readyToDeal':
      return RoundStatus.readyToDeal;
    default:
      return RoundStatus.readyToDeal;
  }
}

String roundStatusTo(RoundStatus s) {
  switch (s) {
    case RoundStatus.completed:
      return 'completed';
    case RoundStatus.dealing:
      return 'dealing';
    case RoundStatus.playing:
      return 'playing';
    case RoundStatus.readyToDeal:
      return 'readyToDeal';
  }
}

class Round {
  int id; // index
  RoundStatus roundStatus;
  Map<String, dynamic> roundScores;
  Round({
    required this.id,
    required this.roundStatus,
    required this.roundScores,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roundStatus': roundStatusTo(roundStatus),
      'roundScores': roundScores,
    };
  }

  static Round fromJson(Map<String, dynamic> m) {
    return Round(
      id: (m['id'] as int?) ?? 1,
      roundStatus: roundStatusFrom(m['roundStatus'] as String?),
      roundScores: Map<String, dynamic>.from(m['roundScores'] ?? {}),
    );
  }
}
