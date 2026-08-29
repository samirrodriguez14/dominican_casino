class GameReaction {
  static const columns = 4;
  static const options = [
    '👍',
    '💪',
    '👏',
    '❤️',
    '😢',
    '😭',
    '😡',
    '💔',
    '😊',
    '😜',
    '😂',
    '😎',
    '🤔',
    '😮',
    '🤯',
    '🤦🏻‍♂️',
    '💀',
    '🎉',
    '🔥',
    '💯',
  ];

  final String id;
  final String emoji;
  final String fromPid;
  final DateTime sentAt;

  const GameReaction({
    required this.id,
    required this.emoji,
    required this.fromPid,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'emoji': emoji,
    'fromPid': fromPid,
    'clientAt': sentAt.millisecondsSinceEpoch,
  };

  factory GameReaction.fromMap(Map<String, dynamic> m) {
    final clientAt = m['clientAt'];
    return GameReaction(
      id: (m['id'] as String?) ?? '',
      emoji: (m['emoji'] as String?) ?? '',
      fromPid: (m['fromPid'] as String?) ?? '',
      sentAt: clientAt is int
          ? DateTime.fromMillisecondsSinceEpoch(clientAt)
          : DateTime.now(),
    );
  }
}
