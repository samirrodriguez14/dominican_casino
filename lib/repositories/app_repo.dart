import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dominican_casino/models/game_info.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/models/wallet.dart';
import 'package:dominican_casino/models/wallet_config.dart';
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

class InsufficientFundsException implements Exception {
  const InsufficientFundsException({required this.energy});

  final bool energy;
}

class HomeCoinClaim {
  const HomeCoinClaim({required this.gameId, required this.amount});

  final String gameId;
  final int amount;

  Map<String, dynamic> toJson() => {'gameId': gameId, 'amount': amount};

  static HomeCoinClaim? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final gameId = json['gameId'] as String?;
    final amount = (json['amount'] as num?)?.toInt();
    if (gameId == null || gameId.isEmpty || amount == null || amount <= 0) {
      return null;
    }
    return HomeCoinClaim(gameId: gameId, amount: amount);
  }
}

class AppRepo extends ChangeNotifier {
  Theme _appTheme = Theme.sage;
  Theme get appTheme => _appTheme;
  AppTheme get selectedTheme => themeFromEnum(_appTheme);
  CardBack _cardBack = CardBack.sage;
  CardBack get cardBack => _cardBack;
  List<GameInfo> gamesInfo = [];
  AppStatus appStatus = AppStatus.notReady;
  Player? player;
  final List<GameState> games = [];
  final FirestoreService fs;
  final Uuid _uuid = const Uuid();
  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  bool notificationsEnabled = false;
  AuthorizationStatus notificationStatus = AuthorizationStatus.notDetermined;
  Wallet _wallet = Wallet.starter();
  Wallet get wallet => _wallet;
  bool _googleSignInReady = false;
  String? _walletUid;
  bool _walletPersistPaused = false;
  Timer? _energyTimer;
  int? _shellTabRequest;
  int? get shellTabRequest => _shellTabRequest;
  HomeCoinClaim? _pendingHomeCoinClaim;
  HomeCoinClaim? get pendingHomeCoinClaim => _pendingHomeCoinClaim;

  static const _themeKey = 'appTheme';
  static const _cardBackKey = 'cardBack';

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
    final previousDefault = defaultCardBackFor(_appTheme);
    _appTheme = value;
    AppStyle.theme = selectedTheme;
    if (_cardBack == previousDefault) {
      final next = defaultCardBackFor(value);
      if (cardBackStyle(next).owned) {
        _cardBack = next;
        AppStyle.cardBack = next;
        _persistCardBack();
      }
    }
    notifyListeners();
    _persistTheme();
  }

  set cardBack(CardBack value) {
    if (_cardBack == value) return;
    final option = cardBackStyle(value);
    if (!option.owned) return;
    _cardBack = value;
    AppStyle.cardBack = value;
    notifyListeners();
    _persistCardBack();
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
      player = await _loadPlayer();
      await _loadWallet();
      _ensureEnergyTicker();
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
        _ensureEnergyTicker();
      } catch (_) {}
      try {
        await refreshNotificationStatus();
      } catch (_) {}
    }
    notifyListeners();
  }

  String _walletPrefsKey(String uid) => 'wallet_$uid';

  String? get _currentUid =>
      player?.id ?? FirebaseAuth.instance.currentUser?.uid;

  void requestShellTab(int index) {
    _shellTabRequest = index;
    notifyListeners();
  }

  int? takeShellTabRequest() {
    final v = _shellTabRequest;
    _shellTabRequest = null;
    return v;
  }

  void _ensureEnergyTicker() {
    _energyTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      tickEnergy();
    });
  }

  /// Apply pending regen. Notifies only when energy actually changes.
  void tickEnergy() {
    if (_walletPersistPaused) return;
    final next = _wallet.applyRegen();
    if (next.energy == _wallet.energy &&
        next.energyUpdatedAt == _wallet.energyUpdatedAt) {
      return;
    }
    _wallet = next;
    notifyListeners();
    unawaited(_persistWallet());
  }

  Duration get timeToNextEnergy => _wallet.timeToNextEnergy();

  Future<void> _loadWallet() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? player?.id;
    if (uid == null) {
      _wallet = Wallet.starter();
      _walletUid = null;
      return;
    }

    // Pause so the energy ticker cannot write the previous session's
    // in-memory wallet (often a starter guest balance) to this uid.
    _walletPersistPaused = true;
    var remoteOk = false;
    try {
      Map<String, dynamic>? remote;
      try {
        remote = await fs.loadUserProfile(uid);
        remoteOk = true;
      } catch (e) {
        developer.log('AppRepo.loadWallet remote: $e');
      }

      final local = await _loadWalletPrefs(uid);
      Wallet loaded;
      if (Wallet.hasWalletFields(remote)) {
        loaded = Wallet.fromJson(remote!);
        // Prefer a non-starter local cache if cloud looks freshly reset.
        if (local != null &&
            loaded.coins == WalletConfig.startingCoins &&
            loaded.energy == WalletConfig.startingEnergy &&
            (local.coins != loaded.coins || local.energy != loaded.energy)) {
          loaded = local;
        }
      } else {
        loaded = local ?? Wallet.starter();
      }
      _wallet = loaded.applyRegen();
      _walletUid = uid;
    } finally {
      _walletPersistPaused = false;
    }

    if (remoteOk) {
      await _persistWallet();
    }
    await _loadHomeCoinClaim(uid);
  }

  String _homeCoinClaimPrefsKey(String uid) => 'home_coin_claim_$uid';

  Future<void> _loadHomeCoinClaim(String uid) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_homeCoinClaimPrefsKey(uid));
      if (raw == null) {
        _pendingHomeCoinClaim = null;
        return;
      }
      _pendingHomeCoinClaim = HomeCoinClaim.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      developer.log('AppRepo.loadHomeCoinClaim: $e');
      _pendingHomeCoinClaim = null;
    }
  }

  Future<void> _persistHomeCoinClaim() async {
    final uid = _walletUid;
    if (uid == null) return;
    final sp = await SharedPreferences.getInstance();
    final key = _homeCoinClaimPrefsKey(uid);
    final pending = _pendingHomeCoinClaim;
    if (pending == null) {
      await sp.remove(key);
    } else {
      await sp.setString(key, jsonEncode(pending.toJson()));
    }
  }

  /// Stash match winnings to celebrate on home. Does not grant until
  /// [completeHomeCoinClaim]. Zero-amount games just mark payout applied.
  Future<void> queueHomeCoinClaim(GameState game, String me) async {
    if (game.gameStatus != GameStatus.gameOver) return;
    if (game.payoutApplied) return;
    if (me.isEmpty) return;
    final amount = game.coinsToClaim(me);
    if (amount <= 0) {
      await claimMatchCoins(game, me);
      return;
    }
    if (_pendingHomeCoinClaim?.gameId == game.id) return;
    _pendingHomeCoinClaim = HomeCoinClaim(gameId: game.id, amount: amount);
    await _persistHomeCoinClaim();
    notifyListeners();
  }

  Future<void> completeHomeCoinClaim() async {
    final pending = _pendingHomeCoinClaim;
    if (pending == null) return;
    final uid = _currentUid;
    GameState? game;
    try {
      game = await fs.loadGame(pending.gameId);
    } catch (e) {
      developer.log('AppRepo.completeHomeCoinClaim load: $e');
    }
    if (game != null && uid != null) {
      if (!game.payoutApplied) {
        await claimMatchCoins(game, uid);
      }
    } else {
      await grantCoins(pending.amount);
    }
    _pendingHomeCoinClaim = null;
    await _persistHomeCoinClaim();
    notifyListeners();
  }

  Future<Wallet?> _loadWalletPrefs(String uid) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_walletPrefsKey(uid));
    if (raw == null) return null;
    try {
      return Wallet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistWallet() async {
    if (_walletPersistPaused) return;
    final uid = _walletUid;
    if (uid == null) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_walletPrefsKey(uid), jsonEncode(_wallet.toJson()));
    try {
      await fs.saveWallet(uid: uid, wallet: _wallet);
    } catch (e) {
      developer.log('AppRepo.saveWallet: $e');
    }
  }

  Future<void> setWallet(Wallet wallet) async {
    _wallet = wallet.applyRegen();
    await _persistWallet();
    notifyListeners();
  }

  Future<bool> trySpendCoins(int amount) async {
    if (amount <= 0) return true;
    if (_wallet.coins < amount) return false;
    _wallet = _wallet.copyWith(coins: _wallet.coins - amount);
    await _persistWallet();
    notifyListeners();
    return true;
  }

  Future<bool> trySpendEnergy(int amount) async {
    if (amount <= 0) return true;
    if (_wallet.energy < amount) return false;
    final wasAtCap = _wallet.isAtOrAboveCap;
    final nextEnergy = _wallet.energy - amount;
    DateTime nextAt = _wallet.energyUpdatedAt;
    if (wasAtCap && nextEnergy < WalletConfig.energyCap) {
      nextAt = DateTime.now();
    }
    _wallet = _wallet.copyWith(energy: nextEnergy, energyUpdatedAt: nextAt);
    await _persistWallet();
    notifyListeners();
    return true;
  }

  Future<void> grantCoins(int amount) async {
    if (amount <= 0) return;
    _wallet = _wallet.copyWith(coins: _wallet.coins + amount);
    await _persistWallet();
    notifyListeners();
  }

  Future<void> grantEnergy(int amount) async {
    if (amount <= 0) return;
    _wallet = _wallet.copyWith(energy: _wallet.energy + amount);
    await _persistWallet();
    notifyListeners();
  }

  Future<bool> buyEnergyWithCoins({
    required int energy,
    required int coinCost,
  }) async {
    if (energy <= 0 || coinCost <= 0) return false;
    if (_wallet.coins < coinCost) return false;
    _wallet = _wallet.copyWith(
      coins: _wallet.coins - coinCost,
      energy: _wallet.energy + energy,
    );
    await _persistWallet();
    notifyListeners();
    return true;
  }

  bool get canAffordFriendGame => _wallet.coins >= WalletConfig.entryCost;

  bool canAffordPulilo([GameMode? mode]) {
    final cost = WalletConfig.puliloEnergyCostFor(mode?.name ?? '');
    return _wallet.energy >= cost;
  }

  Future<bool> refundEntryIfNeeded(GameState game) async {
    final uid = _currentUid;
    if (uid == null) return false;
    if (game.isLocalBot) return false;
    if (game.started) return false;
    if (game.gameStatus != GameStatus.waitingForPlayers &&
        game.gameStatus != GameStatus.readyToStart) {
      return false;
    }
    if (!game.entryPaidBy.contains(uid)) return false;
    game.entryPaidBy.remove(uid);
    await grantCoins(game.entryCost);
    return true;
  }

  /// Delete a match and refund this device's unpaid-start entry if needed.
  Future<void> deleteGame(String gameId) async {
    GameState? game;
    try {
      game = await fs.loadGame(gameId);
    } catch (e) {
      developer.log('AppRepo.deleteGame load: $e');
    }
    if (game != null) {
      await refundEntryIfNeeded(game);
    }
    await fs.deleteGame(gameId);
  }

  Future<void> claimMatchCoins(GameState game, String me) async {
    if (game.gameStatus != GameStatus.gameOver) return;
    if (game.payoutApplied) return;
    if (me.isEmpty) return;
    final amount = game.coinsToClaim(me);
    game.payoutApplied = true;
    if (amount > 0) await grantCoins(amount);
    try {
      await fs.updateGame(game);
    } catch (e) {
      developer.log('AppRepo.claimMatchCoins: $e');
    }
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
    User? user = auth.currentUser;
    if (user == null) {
      try {
        user = await auth.authStateChanges().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => auth.currentUser,
        );
      } catch (e) {
        developer.log("AppRepo: auth restore wait: $e");
        user = auth.currentUser;
      }
    }
    if (user != null) {
      developer.log("AppRepo: auth uid ${user.uid}");
      try {
        await user.getIdToken();
      } catch (e) {
        developer.log("AppRepo: getIdToken $e");
      }
      return;
    }
    try {
      final cred = await auth.signInAnonymously().timeout(
        const Duration(seconds: 12),
      );
      await cred.user?.getIdToken();
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

  /// Firebase uid for game docs and wallet. Signs in anonymously if needed
  /// and rebinds a stale local player id so Firestore rules can succeed.
  Future<String> ensurePlayableUid() async {
    await _ensureAnonymousAuth();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    try {
      await user.getIdToken();
    } catch (e) {
      developer.log('AppRepo.ensurePlayableUid token: $e');
    }
    final uid = user.uid;
    final current = player;
    if (current == null) {
      player = await _playerFromRemoteOrLocal(uid, null);
      await _persistPlayer();
      await _loadWallet();
      notifyListeners();
    } else if (current.id != uid) {
      player = current.copyWith(id: uid);
      await _persistPlayer();
      await _loadWallet();
      notifyListeners();
    } else if (_walletUid != uid) {
      await _loadWallet();
    }
    return uid;
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
    await _loadWallet();
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
    if (name != null) {
      for (final value in Theme.values) {
        if (value.name == name) {
          _appTheme = value;
          AppStyle.theme = selectedTheme;
          break;
        }
      }
    }

    final backName = sp.getString(_cardBackKey);
    var loadedBack = false;
    if (backName != null) {
      for (final value in CardBack.values) {
        if (value.name == backName && cardBackStyle(value).owned) {
          _cardBack = value;
          loadedBack = true;
          break;
        }
      }
    }
    if (!loadedBack) {
      _cardBack = defaultCardBackFor(_appTheme);
    }
    AppStyle.cardBack = _cardBack;
  }

  Future<void> _persistTheme() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_themeKey, _appTheme.name);
  }

  Future<void> _persistCardBack() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_cardBackKey, _cardBack.name);
  }

  Future<void> _loadLocale() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString('locale');
    if (code != null) {
      _locale = Locale(code);
      return;
    }
    _locale = const Locale('en');
  }

  Future<String> createNewGame(GameMode mode, String pid, bool local) async {
    final existingAuth = FirebaseAuth.instance.currentUser;
    if (local && existingAuth == null) {
      pid = player?.id ?? '';
      if (pid.isEmpty) {
        player = await _fallbackLocalPlayer();
        pid = player!.id;
      }
    } else {
      try {
        pid = await ensurePlayableUid();
      } catch (e) {
        debugPrint('createNewGame auth: $e');
        if (!local) rethrow;
        pid = player?.id ?? '';
        if (pid.isEmpty) {
          player = await _fallbackLocalPlayer();
          pid = player!.id;
        }
      }
    }
    final energyCost = WalletConfig.puliloEnergyCostFor(mode.name);
    if (local) {
      if (_wallet.energy < energyCost) {
        throw const InsufficientFundsException(energy: true);
      }
    } else if (_wallet.coins < WalletConfig.entryCost) {
      throw const InsufficientFundsException(energy: false);
    }

    String gid = _uuid.v4().substring(0, 8);
    GameState gameState = GameState.create(gid, pid, mode);
    gameState.entryCost = WalletConfig.entryCost;
    final host = player;
    if (host != null) {
      gameState.playersInfo[pid] = host.toGameSeat();
    } else {
      gameState.playersInfo[pid] = {'id': pid};
    }
    if (local) {
      final botPid = _uuid.v4().substring(0, 8);
      gameState.isLocalBot = true;
      gameState.botPlayerId = botPid;
      gameState.playersInfo[botPid] = {
        'id': botPid,
        'name': GameState.localBotName,
        'avatarId': GameState.localBotAvatarId,
      };
    } else {
      gameState.entryPaidBy = [pid];
    }
    debugPrint(
      'createNewGame uid=$pid controller=${gameState.controllerId} '
      'auth=${FirebaseAuth.instance.currentUser?.uid} local=$local',
    );
    gid = await fs.newCreateGame(gameState);
    final spent = local
        ? await trySpendEnergy(energyCost)
        : await trySpendCoins(WalletConfig.entryCost);
    if (!spent) {
      try {
        await fs.deleteGame(gid);
      } catch (_) {}
      throw InsufficientFundsException(energy: local);
    }
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

  Future<void> completeTutorial() async {
    if (player == null || player!.completedTutorial) return;
    player = player!.copyWith(completedTutorial: true);
    await _persistPlayer();
    notifyListeners();
  }

  Future<bool> updatePlayer(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    try {
      try {
        await ensurePlayableUid();
      } catch (e) {
        developer.log('AppRepo.updatePlayer auth: $e');
      }
      if (player == null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          player = Player(id: uid, name: trimmed);
        } else {
          final local = await _fallbackLocalPlayer();
          player = local.copyWith(name: trimmed);
        }
      } else {
        player = player!.copyWith(name: trimmed);
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

  /// Sign out of Google on this device. Cloud profile and wallet stay.
  Future<void> logOut() async {
    await _endAuthSession(wipeLocalWallet: false);
  }

  /// Wipe this device's cached profile and sign out.
  /// Guest cloud docs are deleted. Google cloud data stays for next sign-in.
  Future<void> deleteLocalAccount() async {
    await _endAuthSession(
      wipeLocalWallet: true,
      deleteGuestCloudProfile: !isGoogleLinked,
    );
  }

  /// Flush the live wallet to the cloud, then drop the local session.
  /// Never write a starter wallet while the previous user is still signed in.
  Future<void> _endAuthSession({
    required bool wipeLocalWallet,
    bool deleteGuestCloudProfile = false,
  }) async {
    final uid = player?.id ?? FirebaseAuth.instance.currentUser?.uid;
    final walletUid = _walletUid ?? uid;
    final walletToFlush = _wallet;

    _walletPersistPaused = true;
    _energyTimer?.cancel();
    _energyTimer = null;

    if (!deleteGuestCloudProfile && walletUid != null) {
      try {
        final sp = await SharedPreferences.getInstance();
        await sp.setString(
          _walletPrefsKey(walletUid),
          jsonEncode(walletToFlush.toJson()),
        );
        await fs.saveWallet(uid: walletUid, wallet: walletToFlush);
      } catch (e) {
        developer.log('AppRepo.flushWallet: $e');
      }
      try {
        await _persistPlayerRemote();
      } catch (_) {}
    } else if (deleteGuestCloudProfile && uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      } catch (_) {}
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }

    await _clearLocalSession(uid, wipeLocalWallet: wipeLocalWallet);
    _loadFuture = null;
    _walletPersistPaused = false;
    await loadApp();
  }

  Future<void> _clearLocalSession(
    String? uid, {
    bool wipeLocalWallet = true,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('player_id');
    if (wipeLocalWallet && uid != null) {
      await sp.remove(_walletPrefsKey(uid));
      await sp.remove(_homeCoinClaimPrefsKey(uid));
    }
    player = null;
    _wallet = Wallet.starter();
    _walletUid = null;
    _pendingHomeCoinClaim = null;
    appStatus = AppStatus.notReady;
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
      avatarId: cloud?.avatarId ?? local?.avatarId ?? Player.defaultAvatarId,
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      player = _mergePlayer(uid, local: null, remote: null);
      return player;
    }
    return await _fallbackLocalPlayer();
  }
}
