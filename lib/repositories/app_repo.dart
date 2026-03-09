import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/services/firebase_auth_service.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/casino_theme.dart';
import 'package:dominican_casino/style/felt_walnut_theme.dart';
import 'package:dominican_casino/style/midnight_theme.dart';
import 'package:dominican_casino/style/wooden_table_theme.dart';
import 'package:dominican_casino/ui/app_shell/settings/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum AppStatus {
  notReady,
  authReady,
  appReady,
  loggedIn,
  loggedOut,
  inGame,
  appError,
}

class AppRepo extends ChangeNotifier {
  Theme _appTheme = Theme.feltWaltnut;
  Theme get appTheme => _appTheme;
  AppTheme get selectedTheme => themeFromEnum(_appTheme);

  AppStatus appStatus = AppStatus.notReady;
  Player? player;
  AuthSession? authSession;
  final List<GameState> games = [];
  final FirestoreService fs;
  final FirebaseAuthService auth;
  final Uuid _uuid = const Uuid();
  AppRepo({required this.fs, required this.auth});

  Future<void> loadApp() async {
    developer.log("AppRepo: Loading Auth");
    authSession = await auth.getCurrentSession();
    if (authSession == null) {
      developer.log("AppRepo: Error Loading Auth.. Send Home");
      // appStatus = AppStatus.appReady;
      // notifyListeners();
      return;
    }
    appStatus = AppStatus.loggedIn;
    developer.log("AppRepo: Loading player Remote");
    player = await _loadPlayerRemote();
    developer.log("AppRepo: Loading theme");
    appTheme = await _loadTheme();
    developer.log("AppRepo: player ${player?.id}");
    if (player != null) appStatus = AppStatus.appReady;
    notifyListeners();
  }

  ///AUTH HANDLERS
  ///------------
  Future<bool> login() async {
    authSession = await auth.login();
    player = await fs.getPlayer(authSession!.uid!);
    await _loadPlayerRemote();
    return authSession != null;
  }

  void logout() async {
    await auth.logout();
  }

  //GAMES HANDLERS
  Future<void> deleteGame(String gameId) async {
    fs.deleteGame(gameId);
  }

  Future<void> createGame() async {
    await fs.createGame();
  }

  ///Player HANDLERS
  ///------------
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

  //LoadPlayer
  //if not found create new
  //return new User

  //LoadPlayerLocal from local

  Future<Player?> _loadPlayerRemote() async {
    //Tries to find a player Id locally..
    try {
      if (authSession?.uid != null) {
        final Player? p = await fs.getPlayer(authSession!.uid!);
        if (p != null) return p;

        final id = _uuid.v4().substring(0, 8);

        player = Player(id: authSession!.uid!, name: "player_$id");
        final ok = await fs.createPlayer(authSession!.uid!, player!);
        if (!ok) return null;
        developer.log("Created Player");
        return player;
      }
    } catch (e) {
      developer.log("AppRepo.loadPlayer Error: $e");
      appStatus = AppStatus.appError;
    }
    return null;
  }

  // Future<Player?> _loadPlayerLocal() async {
  //   //Tries to find a player Id locally..
  //   final SharedPreferences sp = await SharedPreferences.getInstance();
  //   try {
  //     final p = sp.getString('player_id');
  //     if (p != null) {
  //       player = Player.fromDto(jsonDecode(p));
  //       return player;
  //     }
  //     final id = _uuid.v4().substring(0, 8);
  //     player = Player(id: id, name: "player_$id");

  //     await sp.setString("player_id", jsonEncode(player!.toJson()));
  //     developer.log("AppRepo: Player loaded: ${sp.getString('player_id')}");

  //     return player;
  //   } catch (e) {
  //     developer.log("AppRepo.loadPlayer Error: $e");

  //     appStatus = AppStatus.appError;
  //   }
  //   return null;
  // }

  ///THEME HANDLERS
  ///------------
  set appTheme(Theme value) {
    if (_appTheme == value) return;
    _appTheme = value;
    _saveThemeLocally(value);
    notifyListeners();
  }

  Future<Theme> _loadTheme() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final theme = sp.getString('theme');
    developer.log("AppTheme: $theme");

    if (theme == null) {
      return Theme.feltWaltnut;
    }
    developer.log(jsonEncode(theme));
    final atheme = _themeFromString(jsonEncode(theme));
    return atheme;
  }

  Theme _themeFromString(String themeName) {
    switch (themeName) {
      case ("casino"):
        return Theme.casino;
      case ('feltWaltnut'):
        return Theme.feltWaltnut;
      case ('midnight'):
        return Theme.midnight;
      case ("walnut"):
        return Theme.walnut;
      default:
        return Theme.casino;
    }
  }

  Future<void> _saveThemeLocally(Theme value) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    try {
      await sp.setString("theme", value.name);
      notifyListeners();
    } catch (e) {
      developer.log("AppRepo.loadPlayer Error: $e");
    }
  }

  static AppTheme themeFromEnum(Theme theme) {
    switch (theme) {
      case Theme.feltWaltnut:
        return FeltWalnutTheme();
      case Theme.walnut:
        return WalnutTheme();
      case Theme.casino:
        return CasinoTheme();
      case Theme.midnight:
        return MidnightNeonTheme();
    }
  }
}
