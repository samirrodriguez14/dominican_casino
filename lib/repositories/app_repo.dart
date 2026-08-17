import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/game_info.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/models/wallet.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
  AuthorizationStatus notificationStatus = AuthorizationStatus.notDetermined;
  Wallet _wallet = const Wallet();
  Wallet get wallet => _wallet;

  static const _walletKey = 'wallet';
  static const _themeKey = 'appTheme';

  AppRepo({required this.fs});

  set appTheme(Theme value) {
    if (_appTheme == value) return;
    _appTheme = value;
    AppStyle.theme = selectedTheme;
    notifyListeners();
    _persistTheme();
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
      await _loadTheme();
      await _loadWallet();
      player = await _loadPlayer();
      gamesInfo = await loadGames();
      await refreshNotificationStatus();
      if (player != null) appStatus = AppStatus.appReady;
    } catch (e, st) {
      developer.log("AppRepo.loadApp Error: $e", error: e, stackTrace: st);
      // Last-resort local player so the UI is never stuck on "loading app".
      player ??= await _fallbackLocalPlayer();
      if (player != null) appStatus = AppStatus.appReady;
      try {
        gamesInfo = await loadGames();
      } catch (_) {}
      try {
        await _loadWallet();
      } catch (_) {}
      try {
        await refreshNotificationStatus();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _loadWallet() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_walletKey);
    if (raw == null) {
      _wallet = const Wallet();
      await _persistWallet();
      return;
    }
    try {
      _wallet = Wallet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _wallet = const Wallet();
    }
  }

  Future<void> _persistWallet() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_walletKey, jsonEncode(_wallet.toJson()));
  }

  Future<void> setWallet(Wallet wallet) async {
    _wallet = wallet;
    await _persistWallet();
    notifyListeners();
  }

  /// Reads OS notification permission without prompting or opening Settings.
  Future<void> refreshNotificationStatus() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      notificationStatus = settings.authorizationStatus;
      notificationsEnabled =
          notificationStatus == AuthorizationStatus.authorized ||
          notificationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      developer.log('AppRepo.refreshNotificationStatus: $e');
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

  Future<void> _loadTheme() async {
    final sp = await SharedPreferences.getInstance();
    final name = sp.getString(_themeKey);
    if (name == null) return;
    for (final value in Theme.values) {
      if (value.name == name) {
        _appTheme = value;
        AppStyle.theme = selectedTheme;
        return;
      }
    }
  }

  Future<void> _persistTheme() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_themeKey, _appTheme.name);
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

  Future<String> createNewGame(GameMode mode, String pid, bool local) async {
    String gid = _uuid.v4().substring(0, 8);
    GameState gameState = GameState.create(gid, pid, mode);
    if (local) {
      final botPid = _uuid.v4().substring(0, 8);
      gameState.isLocalBot = true;
      gameState.botPlayerId = botPid;
      gameState.playersInfo[botPid] = {
        "id": botPid,
        "name": GameState.localBotName,
      };
    }
    gid = await fs.newCreateGame(gameState);
    return gid;
  }

  /// Request notification permission after an in-app rationale, then store
  /// the FCM token under users/{uid} — never on game documents.
  /// Does not open the system Settings app.
  Future<bool> enableNotifications() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    notificationStatus = settings.authorizationStatus;
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      notificationsEnabled = false;
      notifyListeners();
      return false;
    }

    // APNS must be ready on iOS before getToken.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final apns = await messaging.getAPNSToken();
      if (apns == null) {
        developer.log('APNS token not ready yet');
        notificationsEnabled = true;
        notifyListeners();
        return true;
      }
    }

    final fcmToken = await messaging.getToken();
    if (fcmToken == null || player == null) {
      notificationsEnabled = true;
      notifyListeners();
      return true;
    }

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

  Future<void> completeTutorial() async {
    if (player == null || player!.completedTutorial) return;
    player = player!.copyWith(completedTutorial: true);
    await _persistPlayerLocal();
    notifyListeners();
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
