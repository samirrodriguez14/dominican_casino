import 'package:youareup/models/game_state.dart';

/// Game modes that have an in-app guided tutorial.
const tutorialGameModes = <GameMode>{
  GameMode.casino,
  GameMode.casinoSpeed,
  GameMode.rummy,
  GameMode.tresydos,
  GameMode.bs,
};

bool isTutorialGameMode(GameMode mode) => tutorialGameModes.contains(mode);

Set<GameMode> completedGameTutorialsFromJson(dynamic raw) {
  if (raw is! List) return {};
  final out = <GameMode>{};
  for (final e in raw) {
    final mode = gameModeFrom(e?.toString());
    if (isTutorialGameMode(mode)) out.add(mode);
  }
  return out;
}

List<String> completedGameTutorialsToJson(Set<GameMode> modes) =>
    modes.map(gameModeTo).toList()..sort();
