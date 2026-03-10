import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/casino_theme.dart';
import 'package:dominican_casino/style/casino_theme_light.dart';
import 'package:dominican_casino/style/felt_walnut_theme.dart';
import 'package:dominican_casino/style/green_table_theme.dart';
import 'package:dominican_casino/style/midnight_theme.dart';
import 'package:dominican_casino/style/dominican_theme.dart';
import 'package:dominican_casino/ui/app_shell/settings/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum AppStatus { notReady, appReady, inGame, appError }

class AppRepo extends ChangeNotifier {

  Theme _appTheme = Theme.feltWaltnut;
  Theme get appTheme => _appTheme;
  AppTheme get selectedTheme => themeFromEnum(_appTheme);

  AppStatus appStatus = AppStatus.notReady;
  Player? player;
  final List<GameState> games = [];
  final FirestoreService fs;
  final Uuid _uuid = const Uuid();
  AppRepo({required this.fs});

  set appTheme(Theme value) {
    if (_appTheme == value) return;
    _appTheme = value;
    notifyListeners();
  }

  Future<void> loadApp() async {
    developer.log("AppRepo: Loading player");
    player = await _loadPlayer();
    developer.log("AppRepo: player ${player?.id}");
    if (player != null) appStatus = AppStatus.appReady;
  }

  Future<void> deleteGame(String gameId) async {
    fs.deleteGame(gameId);
  }

  Future<void> createGame() async {
    await fs.createGame();
  }

  Future<bool> updatePlayer(String name) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    try {
      final p = sp.getString('player_id');
      if (p == null) {
        developer.log("AppRepo.updatePlayer No player found locally");
        //Create new later
        final id = _uuid.v4().substring(0, 8);
        player = Player(id: id, name: name);
      }
      player!.name = name;
      await sp.setString("player_id", jsonEncode(player!.toJson()));
      developer.log("AppRepo: Player updated: ${sp.getString('player_id')}");
      notifyListeners();
      return true;
    } catch (e) {
      developer.log("AppRepo.loadPlayer Error: $e");
      return false;
    }
  }

  Future<Player?> _loadPlayer() async {
    //Tries to find a player Id locally..
    final SharedPreferences sp = await SharedPreferences.getInstance();
    try {
      final p = sp.getString('player_id');
      if (p != null) {
        player = Player.fromDto(jsonDecode(p));
        return player;
      }
      final id = _uuid.v4().substring(0, 8);
      player = Player(id: id, name: "player_$id");

      await sp.setString("player_id", jsonEncode(player!.toJson()));
      developer.log("AppRepo: Player loaded: ${sp.getString('player_id')}");

      return player;
    } catch (e) {
      developer.log("AppRepo.loadPlayer Error: $e");

      appStatus = AppStatus.appError;
    }
    return null;
  }

  static AppTheme themeFromEnum(Theme theme) {
    switch (theme) {
      case Theme.feltWaltnut:
        return FeltWalnutTheme();
      case Theme.dominican:
        return DominicanTheme();
      case Theme.casino:
        return CasinoTheme();
      case Theme.midnight:
        return MidnightNeonTheme();
      case Theme.casinoLight:
        return LightCasinoTheme();
      case Theme.greenTable:
        return GreenTableTheme();
    }
  }
}
