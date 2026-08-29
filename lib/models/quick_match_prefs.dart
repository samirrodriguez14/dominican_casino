import 'dart:convert';

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';

/// Persisted Quick Play filters. Empty [modes] means any playable mode.
class QuickMatchPrefs {
  const QuickMatchPrefs({
    this.modes = const [],
    this.maxEntryCost = WalletConfig.entryCost,
    this.maxPlayers = 6,
  });

  /// Preferred game modes. Empty = any mode in [gameModeCarouselModes].
  final List<GameMode> modes;

  /// Join only rooms with [GameState.entryCost] <= this value.
  final int maxEntryCost;

  /// Join only rooms whose target table size is <= this (2–6).
  final int maxPlayers;

  static const QuickMatchPrefs defaults = QuickMatchPrefs();

  static const int minMaxPlayers = 2;
  static const int absoluteMaxPlayers = 6;

  /// True when every playable mode is allowed (empty list or all selected).
  bool get anyMode =>
      modes.isEmpty || modes.length >= gameModeCarouselModes.length;

  List<GameMode> get effectiveModes =>
      anyMode ? List<GameMode>.from(gameModeCarouselModes) : List.from(modes);

  /// Modes explicitly chosen when not [anyMode] (for summary).
  List<GameMode> get selectedModes =>
      anyMode ? const [] : List<GameMode>.from(modes);

  QuickMatchPrefs copyWith({
    List<GameMode>? modes,
    int? maxEntryCost,
    int? maxPlayers,
  }) {
    return QuickMatchPrefs(
      modes: modes ?? this.modes,
      maxEntryCost: maxEntryCost ?? this.maxEntryCost,
      maxPlayers: maxPlayers ?? this.maxPlayers,
    );
  }

  Map<String, dynamic> toJson() => {
    'modes': modes.map(gameModeTo).toList(),
    'maxEntryCost': maxEntryCost,
    'maxPlayers': maxPlayers,
  };

  factory QuickMatchPrefs.fromJson(Map<String, dynamic>? raw) {
    if (raw == null) return defaults;
    final modesRaw = raw['modes'];
    final modes = <GameMode>[];
    if (modesRaw is List) {
      for (final e in modesRaw) {
        final mode = gameModeFrom(e?.toString());
        if (gameModeCarouselModes.contains(mode) && !modes.contains(mode)) {
          modes.add(mode);
        }
      }
    }
    final max = (raw['maxEntryCost'] as num?)?.toInt() ?? WalletConfig.entryCost;
    final allowed = WalletConfig.stakesFor(allowNoBet: true);
    final maxEntryCost = allowed.contains(max) ? max : WalletConfig.entryCost;

    // Prefer maxPlayers; migrate legacy exact playerCount / null → 6.
    int maxPlayers = absoluteMaxPlayers;
    final maxPlayersRaw = raw['maxPlayers'];
    if (maxPlayersRaw is num) {
      maxPlayers = maxPlayersRaw.toInt().clamp(minMaxPlayers, absoluteMaxPlayers);
    } else {
      final legacy = raw['playerCount'];
      if (legacy is num) {
        maxPlayers = legacy.toInt().clamp(minMaxPlayers, absoluteMaxPlayers);
      }
    }

    final normalizedModes =
        modes.length >= gameModeCarouselModes.length ? const <GameMode>[] : modes;

    return QuickMatchPrefs(
      modes: normalizedModes,
      maxEntryCost: maxEntryCost,
      maxPlayers: maxPlayers,
    );
  }

  static QuickMatchPrefs? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return QuickMatchPrefs.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  String encode() => jsonEncode(toJson());
}
