import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dominican_casino/local_player/local_player.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
    if (player != null) {
      player!.token = await getDeviceToken();
    }
    developer.log("AppRepo: player ${player?.id}");
    if (player != null) appStatus = AppStatus.appReady;
  }

  Future<String> createNewGame(
    GameMode mode,
    String pid,
    GameRepo gameRepo,
    bool local,
  ) async {
    String gid = _uuid.v4().substring(0, 8);
    player?.token = await getDeviceToken();
    GameState gameState = GameState.create(gid, pid, mode);
    if (local) {
      final localPlayer = LocalPlayer(gameRepo: gameRepo, mode:mode);
      gameState.playersInfo[localPlayer.pid] = {
        "id": localPlayer.pid,
        "name": localPlayer.name,
        "token": "",
      };
    }
    gid = await fs.newCreateGame(gameState);
    return gid;
  }

  Future<String?> getDeviceToken() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // use full permission while testing
    );
    developer.log('Auth status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      developer.log(
        'Notification permission not granted: ${settings.authorizationStatus}',
      );
      return null;
    }

    String? apnsToken;
    apnsToken = await messaging.getAPNSToken();

    if (apnsToken == null) {
      developer.log('APNS token not ready yet');
      return null;
    }

    final fcmToken = await messaging.getToken();
    // developer.log('APNS token: $apnsToken');
    developer.log('FCM token: $fcmToken');
    return fcmToken;
  }

  Future<void> deleteGame(String gameId) async {
    fs.deleteGame(gameId);
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
      player = Player(id: id, name: "p_$id");

      await sp.setString("player_id", jsonEncode(player!.toJson()));
      developer.log("AppRepo: Player loaded: ${sp.getString('player_id')}");

      return player;
    } catch (e) {
      developer.log("AppRepo.loadPlayer Error: $e");

      appStatus = AppStatus.appError;
    }
    return null;
  }
}
