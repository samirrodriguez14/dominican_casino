import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/local_player/local_player.dart';
import 'package:dominican_casino/models/game_info.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum AppStatus { notReady, appReady, inGame, appError }

class AppRepo extends ChangeNotifier {
  Theme _appTheme = Theme.feltWaltnut;
  Theme get appTheme => _appTheme;
  AppTheme get selectedTheme => themeFromEnum(_appTheme);
  List<GameInfo> gamesInfo = [];
  AppStatus appStatus = AppStatus.notReady;
  Player? player;
  final List<GameState> games = [];
  final FirestoreService fs;
  final Uuid _uuid = const Uuid();
  Locale _locale = const Locale('es');
  Locale get locale => _locale;
  bool notificationsEnabled = false;

  AppRepo({required this.fs});

  set appTheme(Theme value) {
    if (_appTheme == value) return;
    _appTheme = value;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('locale', locale.languageCode);
    notifyListeners();
  }

  Future<void>? _loadFuture;

  /// Idempotent — safe to call from main and HomeScreen.
  Future<void> loadApp() {
    return _loadFuture ??= _loadAppInternal();
  }

  Future<void> _loadAppInternal() async {
    developer.log("AppRepo: Loading app");
    try {
      await _ensureAnonymousAuth();
      await _loadLocale();
      player = await _loadPlayer();
      gamesInfo = await loadGames();
      if (player != null) appStatus = AppStatus.appReady;
    } catch (e, st) {
      developer.log("AppRepo.loadApp Error: $e", error: e, stackTrace: st);
      // Last-resort local player so the UI is never stuck on "loading app".
      player ??= await _fallbackLocalPlayer();
      if (player != null) appStatus = AppStatus.appReady;
      try {
        gamesInfo = await loadGames();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _ensureAnonymousAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      developer.log("AppRepo: auth uid ${auth.currentUser!.uid}");
      return;
    }
    try {
      await auth.signInAnonymously().timeout(const Duration(seconds: 12));
      developer.log("AppRepo: auth uid ${auth.currentUser?.uid}");
    } on FirebaseAuthException catch (e) {
      // Common when Anonymous sign-in is off in Firebase Console.
      developer.log(
        "AppRepo: Anonymous Auth failed (${e.code}). "
        "Enable Authentication → Sign-in method → Anonymous. "
        "Continuing with local player id.",
      );
    } catch (e) {
      developer.log("AppRepo: Anonymous Auth error: $e");
    }
  }

  Future<Player> _fallbackLocalPlayer() async {
    final sp = await SharedPreferences.getInstance();
    final p = sp.getString('player_id');
    if (p != null) {
      final existing = Player.fromDto(jsonDecode(p));
      return existing.copyWith(token: null);
    }
    final id = _uuid.v4().substring(0, 8);
    final created = Player(id: id, name: "p_$id");
    await sp.setString('player_id', jsonEncode(created.toJson()));
    return created;
  }

  Future<void> _loadLocale() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString('locale');
    if (code != null) {
      _locale = Locale(code);
      return;
    }
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    _locale = device.languageCode == 'es'
        ? const Locale('es')
        : const Locale('en');
  }

  Future<String> createNewGame(
    GameMode mode,
    String pid,
    GameRepo gameRepo,
    bool local,
  ) async {
    String gid = _uuid.v4().substring(0, 8);
    GameState gameState = GameState.create(gid, pid, mode);
    if (local) {
      final localPlayer = LocalPlayer(gameRepo: gameRepo, mode: mode);
      localPlayer.pid = _uuid.v4().substring(0, 8);
      gameState.playersInfo[localPlayer.pid] = {
        "id": localPlayer.pid,
        "name": localPlayer.name,
      };
    }
    gid = await fs.newCreateGame(gameState);
    return gid;
  }

  /// Request notification permission after an in-app rationale, then store
  /// the FCM token under users/{uid} — never on game documents.
  Future<bool> enableNotifications() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      notificationsEnabled = false;
      return false;
    }

    // APNS must be ready on iOS before getToken.
    final apns = await messaging.getAPNSToken();
    if (apns == null) {
      developer.log('APNS token not ready yet');
      return false;
    }

    final fcmToken = await messaging.getToken();
    if (fcmToken == null || player == null) return false;

    player = player!.copyWith(token: fcmToken);
    await _persistPlayerLocal();
    await fs.saveUserToken(player!.id, fcmToken, player!.name);
    notificationsEnabled = true;
    notifyListeners();
    return true;
  }

  static Future<List<GameInfo>> loadGames() async {
    final jsonString = await rootBundle.loadString('assets/config/games.json');
    final jsonData = jsonDecode(jsonString);
    return (jsonData['games'] as List)
        .map((e) => GameInfo.fromJson(e))
        .toList();
  }

  Future<void> deleteGame(String gameId) async {
    fs.deleteGame(gameId);
  }

  Future<bool> updatePlayer(String name) async {
    try {
      if (player == null) {
        await _ensureAnonymousAuth();
        final uid = FirebaseAuth.instance.currentUser!.uid;
        player = Player(id: uid, name: name);
      } else {
        player = player!.copyWith(name: name);
      }
      await _persistPlayerLocal();
      if (player!.token != null) {
        await fs.saveUserToken(player!.id, player!.token!, player!.name);
      }
      notifyListeners();
      return true;
    } catch (e) {
      developer.log("AppRepo.updatePlayer Error: $e");
      return false;
    }
  }

  Future<void> deleteLocalAccount() async {
    final uid = player?.id ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      } catch (_) {}
    }
    final sp = await SharedPreferences.getInstance();
    await sp.remove('player_id');
    player = null;
    appStatus = AppStatus.notReady;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _loadFuture = null;
    await loadApp();
  }

  Future<void> _persistPlayerLocal() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('player_id', jsonEncode(player!.toJson()));
  }

  Future<Player?> _loadPlayer() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        // Auth unavailable — keep app usable with a local id.
        return await _fallbackLocalPlayer();
      }

      final p = sp.getString('player_id');
      if (p != null) {
        final existing = Player.fromDto(jsonDecode(p));
        // Migrate old 8-char ids onto the Auth uid.
        if (existing.id != uid) {
          player = existing.copyWith(id: uid, token: null);
          await _persistPlayerLocal();
          return player;
        }
        // Drop any cached FCM token from local profile for safety.
        player = existing.copyWith(token: null);
        return player;
      }

      player = Player(id: uid, name: "p_${uid.substring(0, 6)}");
      await _persistPlayerLocal();
      return player;
    } catch (e) {
      developer.log("AppRepo.loadPlayer Error: $e");
      appStatus = AppStatus.appError;
    }
    return await _fallbackLocalPlayer();
  }
}
