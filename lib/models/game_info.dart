class GameInfo {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final bool aiSupported;
  final bool enabled;
  final String themeColor;
  final List<String> rules;
  final PlayerInfo players;

  GameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.aiSupported,
    required this.enabled,
    required this.themeColor,
    required this.rules,
    required this.players,
  });

  factory GameInfo.fromJson(Map<String, dynamic> json) {
    return GameInfo(
      id: json["id"],
      title: json["title"],
      subtitle: json["subtitle"],
      description: json["description"],
      icon: json["icon"],
      aiSupported: json["aiSupported"],
      enabled: json["enabled"],
      themeColor: json["themeColor"],
      rules: List<String>.from(json["rules"]),
      players: PlayerInfo.fromJson(json["players"]),
    );
  }
}

class PlayerInfo {
  final int min;
  final int max;
  final String label;

  PlayerInfo({
    required this.min,
    required this.max,
    required this.label,
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      min: json["min"],
      max: json["max"],
      label: json["label"],
    );
  }
}