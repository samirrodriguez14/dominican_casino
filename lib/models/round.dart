
enum RoundStatus { dealing, playing, completed }

RoundStatus roundStatusFrom(String? s) {
  switch (s) {
    case 'completed':
      return RoundStatus.completed;
    case 'dealing':
      return RoundStatus.dealing;
    case 'playing':
    default:
      return RoundStatus.playing;
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
  }
}

class Round {
  int id; // index
  RoundStatus roundStatus;
  Map<String, bool> roundReady;
  Map<String, dynamic> roundScores;

  Round({
    required this.id,
    required this.roundStatus,
    required this.roundReady,
    required this.roundScores,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roundStatus': roundStatusTo(roundStatus),
      'roundReady': roundReady,
      'roundScores': roundScores,
    };
  }

  static Round fromJson(Map<String, dynamic> m) {
    final readyRaw = Map<String, dynamic>.from(m['roundReady'] ?? {});
    final ready = <String, bool>{};

    readyRaw.forEach((k, v) {
      ready[k] = v == true;
    });

    return Round(
      id: (m['id'] as int?) ?? 1,
      roundStatus: roundStatusFrom(m['roundStatus'] as String?),
      roundReady: ready,
      roundScores: Map<String, dynamic>.from(m['roundScores'] ?? {}),
    );
  }
}
