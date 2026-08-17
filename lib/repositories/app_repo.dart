import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/game_info.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/models/wallet.dart';
import 'package:dominican_casino/services/firebase_options.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum AppStatus { notReady, appReady, inGame, appError }

enum GoogleAuthStatus { success, canceled, failed }

class GoogleAuthResult {
  const GoogleAuthResult.success(this.suggestedName)
    : status = GoogleAuthStatus.success,
      errorCode = null;
  const GoogleAuthResult.canceled()
    : status = GoogleAuthStatus.canceled,
      suggestedName = null,
      errorCode = null;
  const GoogleAuthResult.failed(this.errorCode)
    : status = GoogleAuthStatus.failed,
      suggestedName = null;

  final GoogleAuthStatus status;
  final String? suggestedName;
  final String? errorCode;
}

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
  bool _googleSignInReady = false;

  static const _walletKey = 'wallet';
  static const _themeKey = 'appTheme';

  bool get isGoogleLinked {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any(
      (info) => info.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
  }

  String? get googleEmail {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    for (final info in user.providerData) {
      if (info.providerId == GoogleAuthProvider.PROVIDER_ID) {
        final email = info.email?.trim();
        if (email != null && email.isNotEmpty) return email;
      }
    }
    final email = user.email?.trim();
    if (email == null || email.isEmpty) return null;
    return email;
  }

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
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
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

  Future<void> _ensureGoogleSignIn() async {
    if (_googleSignInReady || kIsWeb) return;
    await GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
    );
    _googleSignInReady = true;
  }

  /// Attach Google to the current anonymous uid, or sign in if that Google
  /// account already exists. Returns a display name to confirm.
  Future<GoogleAuthResult> linkGoogleAccount() async {
    try {
      await _ensureAnonymousAuth();
      final current = FirebaseAuth.instance.currentUser;
      if (current != null && _isGoogleLinked(current)) {
        return GoogleAuthResult.success(
          _displayNameFromGoogle(current) ?? player?.name,
        );
      }

      if (kIsWeb) {
        return await _linkGoogleWeb(current);
      }

      await _ensureGoogleSignIn();
      final GoogleSignInAccount account;
      try {
        account = await GoogleSignIn.instance.authenticate(
          scopeHint: const ['email', 'profile'],
        );
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          return const GoogleAuthResult.canceled();
        }
        developer.log('AppRepo.linkGoogleAccount GoogleSignIn: $e');
        return GoogleAuthResult.failed(e.code.name);
      }

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        return const GoogleAuthResult.failed('missing-id-token');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _linkOrSignIn(current, credential, account.displayName);
    } on FirebaseAuthException catch (e) {
      developer.log('AppRepo.linkGoogleAccount Auth: ${e.code}', error: e);
      if (_isGoogleCanceled(e.code)) {
        return const GoogleAuthResult.canceled();
      }
      return GoogleAuthResult.failed(e.code);
    } catch (e, st) {
      developer.log('AppRepo.linkGoogleAccount: $e', error: e, stackTrace: st);
      return const GoogleAuthResult.failed('unknown');
    }
  }

  Future<GoogleAuthResult> _linkGoogleWeb(User? current) async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');
    try {
      late final UserCredential cred;
      if (current != null && current.isAnonymous) {
        try {
          cred = await current.linkWithPopup(provider);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            cred = await FirebaseAuth.instance.signInWithPopup(provider);
          } else if (e.code == 'provider-already-linked') {
            return GoogleAuthResult.success(
              _displayNameFromGoogle(current) ?? player?.name,
            );
          } else {
            rethrow;
          }
        }
      } else {
        cred = await FirebaseAuth.instance.signInWithPopup(provider);
      }
      return await _afterGoogleUser(cred.user, cred.user?.displayName);
    } on FirebaseAuthException catch (e) {
      if (_isGoogleCanceled(e.code)) {
        return const GoogleAuthResult.canceled();
      }
      rethrow;
    }
  }

  Future<GoogleAuthResult> _linkOrSignIn(
    User? current,
    AuthCredential credential,
    String? googleName,
  ) async {
    try {
      if (current != null &&
          (current.isAnonymous || !_isGoogleLinked(current))) {
        try {
          final cred = await current.linkWithCredential(credential);
          return await _afterGoogleUser(cred.user, googleName);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            final cred = await FirebaseAuth.instance.signInWithCredential(
              e.credential ?? credential,
            );
            return await _afterGoogleUser(cred.user, googleName);
          }
          if (e.code == 'provider-already-linked') {
            return await _afterGoogleUser(current, googleName);
          }
          rethrow;
        }
      }
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      return await _afterGoogleUser(cred.user, googleName);
    } on FirebaseAuthException catch (e) {
      if (_isGoogleCanceled(e.code)) {
        return const GoogleAuthResult.canceled();
      }
      rethrow;
    }
  }

  Future<GoogleAuthResult> _afterGoogleUser(
    User? user,
    String? googleName,
  ) async {
    if (user == null) return const GoogleAuthResult.failed('unknown');
    final suggested = _displayNameFromGoogle(user, googleName);

    if (player == null || player!.id != user.uid) {
      player = await _playerFromRemoteOrLocal(user.uid, suggested);
    } else if (player!.needsAccountSetup && suggested != null) {
      player = player!.copyWith(name: suggested);
    }

    await _persistPlayer();
    notifyListeners();
    return GoogleAuthResult.success(suggested ?? player?.name);
  }

  Future<Player> _playerFromRemoteOrLocal(
    String uid,
    String? suggestedName,
  ) async {
    Map<String, dynamic>? remote;
    try {
      remote = await fs.loadUserProfile(uid);
    } catch (e) {
      developer.log('AppRepo.loadUserProfile: $e');
    }
    return _mergePlayer(
      uid,
      local: null,
      remote: remote,
      suggestedName: suggestedName,
    );
  }

  bool _isGoogleLinked(User user) {
    return user.providerData.any(
      (info) => info.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
  }

  bool _isGoogleCanceled(String code) {
    return code == 'canceled' ||
        code == 'web-context-canceled' ||
        code == 'popup-closed-by-user' ||
        code == 'cancelled-popup-request';
  }

  String? _displayNameFromGoogle(User user, [String? fallback]) {
    final raw = (user.displayName ?? fallback)?.trim();
    if (raw == null || raw.isEmpty) return null;
    final first = raw.split(RegExp(r'\s+')).first;
    if (first.isEmpty) return null;
    return first.length <= 10 ? first : first.substring(0, 10);
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
    await _persistPlayer();
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
      await _persistPlayer();
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

  Future<bool> updatePlayerAvatar(String avatarId) async {
    try {
      if (player == null) return false;
      player = player!.copyWith(avatarId: avatarId);
      await _persistPlayer();
      notifyListeners();
      return true;
    } catch (e) {
      developer.log("AppRepo.updatePlayerAvatar Error: $e");
      return false;
    }
  }

  /// Sign out of Google on this device. Cloud profile stays.
  Future<void> logOut() async {
    try {
      await _persistPlayerRemote();
    } catch (_) {}
    await _clearLocalPlayer();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    _loadFuture = null;
    await loadApp();
  }

  /// Wipe this device's cached profile. Guest accounts are fully reset.
  /// Google accounts stay signed in and reload name / avatar / tutorial
  /// from the cloud. Wallet is local-only, so it is cleared.
  Future<void> deleteLocalAccount() async {
    final linked = isGoogleLinked;
    final uid = player?.id ?? FirebaseAuth.instance.currentUser?.uid;
    if (!linked && uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      } catch (_) {}
    }
    await _clearLocalPlayer();
    await _resetWallet();
    if (!linked) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
    }
    _loadFuture = null;
    await loadApp();
  }

  Future<void> _clearLocalPlayer() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('player_id');
    player = null;
    appStatus = AppStatus.notReady;
  }

  Future<void> _resetWallet() async {
    _wallet = const Wallet();
    await _persistWallet();
  }

  Future<void> _persistPlayer() async {
    await _persistPlayerLocal();
    await _persistPlayerRemote();
  }

  Future<void> _persistPlayerLocal() async {
    if (player == null) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('player_id', jsonEncode(player!.toJson()));
  }

  Future<void> _persistPlayerRemote() async {
    final current = player;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (current == null || uid == null || current.id != uid) return;
    try {
      await fs.saveUserProfile(
        uid: uid,
        name: current.name,
        avatarId: current.avatarId,
        completedTutorial: current.completedTutorial,
      );
    } catch (e) {
      developer.log('AppRepo.saveUserProfile: $e');
    }
  }

  Player _mergePlayer(
    String uid, {
    Player? local,
    Map<String, dynamic>? remote,
    String? suggestedName,
  }) {
    Player? cloud;
    if (remote != null) {
      cloud = Player.fromDto({
        'id': uid,
        'name': remote['name'] ?? remote['displayName'] ?? '',
        'avatarId': remote['avatarId'],
        'completedTutorial': remote['completedTutorial'] ?? false,
      });
    }

    final cloudName = cloud != null && !cloud.needsAccountSetup
        ? cloud.name
        : null;
    final localName = local != null && !local.needsAccountSetup
        ? local.name
        : null;
    final name =
        cloudName ??
        localName ??
        suggestedName ??
        cloud?.name ??
        local?.name ??
        'p_${uid.substring(0, 6)}';

    return Player(
      id: uid,
      name: name,
      avatarId: cloud?.avatarId ?? local?.avatarId,
      completedTutorial:
          (cloud?.completedTutorial ?? false) ||
          (local?.completedTutorial ?? false),
      token: local?.token,
    );
  }

  Future<Player?> _loadPlayer() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return await _fallbackLocalPlayer();
      }

      Player? cached;
      final p = sp.getString('player_id');
      if (p != null) {
        cached = Player.fromDto(jsonDecode(p)).copyWith(token: null);
      }

      Map<String, dynamic>? remote;
      try {
        remote = await fs.loadUserProfile(uid);
      } catch (e) {
        developer.log('AppRepo.loadUserProfile: $e');
      }

      final local = cached != null && cached.id == uid
          ? cached
          : (remote == null && cached != null && !cached.needsAccountSetup
                ? cached.copyWith(id: uid)
                : null);

      player = _mergePlayer(uid, local: local, remote: remote);
      await _persistPlayer();
      return player;
    } catch (e) {
      developer.log("AppRepo.loadPlayer Error: $e");
      appStatus = AppStatus.appError;
    }
    return await _fallbackLocalPlayer();
  }
}
