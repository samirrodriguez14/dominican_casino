import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dominican_casino/models/daily_challenge.dart';
import 'package:dominican_casino/models/game_info.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/local_bot_roster.dart';
import 'package:dominican_casino/models/player.dart';
import 'package:dominican_casino/models/theme_pack.dart';
import 'package:dominican_casino/models/wallet.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/services/firebase_options.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:dominican_casino/services/notifications_service.dart';
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

enum DeleteAccountResult { success, canceled, failed }

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

enum DailyRewardClaimResult { claimed, alreadyClaimed, needsGoogle }

enum DailyChallengeClaimResult {
  claimed,
  alreadyClaimed,
  incomplete,
  needsGoogle,
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
  CardBackMark _cardBackMark = CardBackMark.logo;
  CardBackMark get cardBackMark => _cardBackMark;
  String _cardBackTintId = 'sage';
  String get cardBackTintId => _cardBackTintId;
  Set<Theme> _ownedPacks = {...defaultOwnedPacks};
  Set<Theme> get ownedPacks => Set.unmodifiable(_ownedPacks);
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
  Set<DailyChallengeId> _pendingHomeDailyChallengeEnergy = {};
  Set<DailyChallengeId> get pendingHomeDailyChallengeEnergy =>
      Set.unmodifiable(_pendingHomeDailyChallengeEnergy);
  int get pendingHomeDailyChallengeEnergyAmount {
    var sum = 0;
    for (final id in _pendingHomeDailyChallengeEnergy) {
      final def = dailyChallengeById(id);
      if (def == null) continue;
      sum += def.reward;
    }
    return sum;
  }
  DateTime? _lastDailyClaimAt;
  DateTime? get lastDailyClaimAt => _lastDailyClaimAt;
  DailyChallengeState _dailyChallenges = DailyChallengeState.empty('');
  DailyChallengeState get dailyChallengesState => _dailyChallenges;
  StreamSubscription<String>? _fcmTokenSub;
  String? _savedFcmToken;
  String? _activeGameId;
  Future<void> _activeGameWrite = Future.value();
  Timer? _energyTestTimer;
  Timer? _dailyRewardTimer;
  Duration? _dailyRewardLastRemaining;

  static const _themeKey = 'appTheme';
  static const _cardBackKey = 'cardBack';
  static const _cardBackMarkKey = 'cardBackMark';
  static const _cardBackTintKey = 'cardBackTint';
  static const _ownedPacksKey = 'ownedPacks';

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

  bool ownsPack(Theme id) {
    final pack = themePack(id);
    if (pack.unlock == ThemeUnlockKind.free) return true;
    return _ownedPacks.contains(id);
  }

  bool ownsCardBack(CardBack back) {
    final pack = themePackForCardBack(back);
    if (pack == null) return false;
    return ownsPack(pack.id);
  }

  set appTheme(Theme value) {
    if (_appTheme == value) return;
    if (!ownsPack(value)) return;
    final previousDefault = defaultCardBackFor(_appTheme);
    _appTheme = value;
    AppStyle.theme = selectedTheme;
    if (_cardBack == previousDefault) {
      final next = defaultCardBackFor(value);
      if (ownsCardBack(next)) {
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
    if (!ownsCardBack(value)) return;
    _cardBack = value;
    AppStyle.cardBack = value;
    notifyListeners();
    _persistCardBack();
  }

  set cardBackMark(CardBackMark value) {
    if (_cardBackMark == value) return;
    _cardBackMark = value;
    AppStyle.cardBackMark = value;
    notifyListeners();
    _persistCardFace();
  }

  set cardBackTintId(String value) {
    final next = coerceTintForTheme(value, _appTheme);
    if (_cardBackTintId == next) return;
    _cardBackTintId = next;
    AppStyle.cardBackTintId = next;
    notifyListeners();
    _persistCardFace();
  }

  Future<void> equipPack(Theme id, {String? avatarId}) async {
    if (!ownsPack(id)) return;
    final pack = themePack(id);
    _appTheme = id;
    AppStyle.theme = selectedTheme;
    _cardBack = pack.cardBack;
    AppStyle.cardBack = pack.cardBack;
    _cardBackTintId = coerceTintForTheme(_cardBackTintId, id);
    AppStyle.cardBackTintId = _cardBackTintId;
    final current = avatarId ?? player?.avatarId;
    final resolved = (current != null && pack.avatarIds.contains(current))
        ? current
        : pack.avatarIds.first;
    final avatarChanged = player != null && player!.avatarId != resolved;
    if (avatarChanged) {
      player = player!.copyWith(avatarId: resolved);
    }
    notifyListeners();
    if (avatarChanged) unawaited(_persistPlayerLocal());
    unawaited(_persistLooks());
  }

  Future<bool> buyThemePack(Theme id) async {
    final pack = themePack(id);
    if (!pack.isCoinLocked) return false;
    if (ownsPack(id)) {
      await equipPack(id);
      return true;
    }
    final cost = pack.coinCost ?? 0;
    if (cost <= 0) return false;
    if (!await trySpendCoins(cost)) return false;
    _ownedPacks.add(id);
    await _persistOwnedPacks();
    await equipPack(id);
    return true;
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('locale', locale.languageCode);
    unawaited(_persistPlayerRemote());
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
      await _persistLooksRemote();
      _ensureEnergyTicker();
      _ensureDailyRewardTicker();
      gamesInfo = await loadGames();
      await NotificationsService.instance.configure();
      _listenForFcmTokenRefresh();
      await refreshNotificationStatus();
      unawaited(_persistActiveGameId());
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
        _ensureDailyRewardTicker();
      } catch (_) {}
      try {
        await NotificationsService.instance.configure();
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

  void _ensureDailyRewardTicker() {
    // Keep the store daily card countdown fresh while the user is watching
    // (no push notifications).
    _dailyRewardTimer ??= Timer.periodic(const Duration(seconds: 20), (_) {
      _tickDailyRewardCooldown();
    });
    _tickDailyRewardCooldown();
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

  void _tickDailyRewardCooldown() {
    if (_walletPersistPaused) return;
    final remaining = dailyRewardCooldownRemaining;
    final prev = _dailyRewardLastRemaining;
    if (remaining == null) {
      _dailyRewardTimer?.cancel();
      _dailyRewardTimer = null;
      _dailyRewardLastRemaining = null;
      return;
    }
    if (prev != null && prev.inSeconds == remaining.inSeconds) return;
    _dailyRewardLastRemaining = remaining;
    notifyListeners();
  }

  Future<void> _loadWallet({bool preferRemote = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? player?.id;
    if (uid == null) {
      _wallet = Wallet.starter();
      _walletUid = null;
      _lastDailyClaimAt = null;
      _dailyChallenges = DailyChallengeState.empty(_localDayKey());
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

      final local = preferRemote ? null : await _loadWalletPrefs(uid);
      Wallet loaded;
      if (Wallet.hasWalletFields(remote)) {
        loaded = Wallet.fromJson(remote!);
        // Prefer a non-starter local cache if cloud looks freshly reset.
        if (!preferRemote &&
            local != null &&
            loaded.coins == WalletConfig.startingCoins &&
            loaded.energy == WalletConfig.startingEnergy &&
            (local.coins != loaded.coins || local.energy != loaded.energy)) {
          loaded = local;
        }
      } else {
        loaded = preferRemote ? Wallet.starter() : (local ?? Wallet.starter());
      }
      _wallet = loaded.applyRegen();
      _walletUid = uid;
      _lastDailyClaimAt = _laterTime(
        Wallet.tryParseWalletTime(remote?['lastDailyClaimAt']),
        preferRemote ? null : await _loadDailyClaimPrefs(uid),
      );
      await _loadDailyChallenges(
        uid,
        remote: remote,
        preferRemote: preferRemote,
      );
    } finally {
      _walletPersistPaused = false;
    }

    if (remoteOk) {
      await _persistWallet();
    }
    await _loadHomeCoinClaim(uid);
    await _loadHomeDailyChallengeEnergyClaim(uid);
    await _cacheDailyClaimLocal(uid);
    await _cacheDailyChallengesLocal(uid);
  }

  String _dailyClaimPrefsKey(String uid) => 'daily_claim_$uid';

  Future<DateTime?> _loadDailyClaimPrefs(String uid) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getInt(_dailyClaimPrefsKey(uid));
      if (raw == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(raw);
    } catch (e) {
      developer.log('AppRepo.loadDailyClaim: $e');
      return null;
    }
  }

  Future<void> _cacheDailyClaimLocal(String uid) async {
    final at = _lastDailyClaimAt;
    if (at == null) return;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_dailyClaimPrefsKey(uid), at.millisecondsSinceEpoch);
    } catch (e) {
      developer.log('AppRepo.cacheDailyClaim: $e');
    }
  }

  Future<void> _persistDailyClaim() async {
    final uid = _walletUid;
    final at = _lastDailyClaimAt;
    if (uid == null || at == null) return;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_dailyClaimPrefsKey(uid), at.millisecondsSinceEpoch);
    } catch (e) {
      developer.log('AppRepo.persistDailyClaim local: $e');
    }
    try {
      await fs.saveLastDailyClaimAt(uid: uid, at: at);
    } catch (e) {
      developer.log('AppRepo.saveLastDailyClaimAt: $e');
    }
  }

  static DateTime? _laterTime(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  static bool _dailyRewardCooldownActive(
    DateTime? last,
    DateTime now,
  ) {
    if (last == null) return false;
    final a = last.toLocal();
    final b = now.toLocal();
    final end = a.add(WalletConfig.dailyLoginRewardCooldown);
    return b.isBefore(end);
  }

  static Duration? _dailyRewardCooldownRemaining(
    DateTime? last,
    DateTime now,
  ) {
    if (!_dailyRewardCooldownActive(last, now)) return null;
    final a = last!.toLocal();
    final b = now.toLocal();
    final end = a.add(WalletConfig.dailyLoginRewardCooldown);
    return end.difference(b);
  }

  bool get isDailyRewardAvailable =>
      isGoogleLinked && !_dailyRewardCooldownActive(_lastDailyClaimAt, DateTime.now());

  bool get hasClaimedDailyRewardToday =>
      isGoogleLinked && _dailyRewardCooldownActive(_lastDailyClaimAt, DateTime.now());

  Duration? get dailyRewardCooldownRemaining {
    if (!isGoogleLinked) return null;
    return _dailyRewardCooldownRemaining(
      _lastDailyClaimAt,
      DateTime.now(),
    );
  }

  Future<DailyRewardClaimResult> claimDailyReward() async {
    if (!isGoogleLinked) return DailyRewardClaimResult.needsGoogle;
    if (_dailyRewardCooldownActive(_lastDailyClaimAt, DateTime.now())) {
      return DailyRewardClaimResult.alreadyClaimed;
    }
    _lastDailyClaimAt = DateTime.now();
    _ensureDailyRewardTicker();
    notifyListeners();
    await grantCoins(WalletConfig.dailyLoginRewardCoins);
    await _persistDailyClaim();
    return DailyRewardClaimResult.claimed;
  }

  Future<void> debugRewindDailyClaim() async {
    if (!kDebugMode) return;
    final last = _lastDailyClaimAt ?? DateTime.now();
    _lastDailyClaimAt = last.toLocal().subtract(const Duration(days: 1));
    await _persistDailyClaim();
    _dailyChallenges = DailyChallengeState.empty(_localDayKey());
    await _persistDailyChallenges();
    notifyListeners();
  }

  String _localDayKey([DateTime? now]) {
    final at = (now ?? DateTime.now()).toLocal();
    final m = at.month.toString().padLeft(2, '0');
    final d = at.day.toString().padLeft(2, '0');
    return '${at.year}-$m-$d';
  }

  String _dailyChallengesPrefsKey(String uid) => 'daily_challenges_$uid';

  void _rollDailyChallengesIfNeeded() {
    final today = _localDayKey();
    if (_dailyChallenges.dayKey == today) return;
    _dailyChallenges = DailyChallengeState.empty(today);
  }

  DailyChallengeState _mergeDailyChallenges(
    DailyChallengeState a,
    DailyChallengeState b,
    String today,
  ) {
    a = a.forDay(today);
    b = b.forDay(today);
    final counts = Map<String, int>.from(a.counts);
    b.counts.forEach((key, value) {
      final cur = counts[key] ?? 0;
      if (value > cur) counts[key] = value;
    });
    return DailyChallengeState(
      dayKey: today,
      counts: counts,
      claimed: {...a.claimed, ...b.claimed},
      credited: {...a.credited, ...b.credited},
    );
  }

  Future<void> _loadDailyChallenges(
    String uid, {
    Map<String, dynamic>? remote,
    required bool preferRemote,
  }) async {
    final today = _localDayKey();
    Map<String, dynamic>? remoteMap;
    final rawRemote = remote?['dailyChallenges'];
    if (rawRemote is Map) {
      remoteMap = Map<String, dynamic>.from(rawRemote);
    }
    final remoteState = DailyChallengeState.fromJson(remoteMap, today);
    DailyChallengeState localState = DailyChallengeState.empty(today);
    if (!preferRemote) {
      localState = await _loadDailyChallengesPrefs(uid, today);
    }
    _dailyChallenges = _mergeDailyChallenges(remoteState, localState, today);
  }

  Future<DailyChallengeState> _loadDailyChallengesPrefs(
    String uid,
    String today,
  ) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_dailyChallengesPrefsKey(uid));
      if (raw == null || raw.isEmpty) {
        return DailyChallengeState.empty(today);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return DailyChallengeState.empty(today);
      return DailyChallengeState.fromJson(
        Map<String, dynamic>.from(decoded),
        today,
      );
    } catch (e) {
      developer.log('AppRepo.loadDailyChallenges: $e');
      return DailyChallengeState.empty(today);
    }
  }

  Future<void> _cacheDailyChallengesLocal(String uid) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(
        _dailyChallengesPrefsKey(uid),
        jsonEncode(_dailyChallenges.toJson()),
      );
    } catch (e) {
      developer.log('AppRepo.cacheDailyChallenges: $e');
    }
  }

  Future<void> _persistDailyChallenges() async {
    final uid = _walletUid;
    if (uid == null) return;
    await _cacheDailyChallengesLocal(uid);
    try {
      await fs.saveDailyChallenges(uid: uid, data: _dailyChallenges.toJson());
    } catch (e) {
      developer.log('AppRepo.saveDailyChallenges: $e');
    }
  }

  int dailyChallengeProgress(DailyChallengeId id) {
    return _dailyChallenges.forDay(_localDayKey()).countFor(id);
  }

  bool isDailyChallengeClaimed(DailyChallengeId id) {
    return _dailyChallenges.forDay(_localDayKey()).isClaimed(id);
  }

  bool canClaimDailyChallenge(DailyChallengeDef def) {
    if (!isGoogleLinked) return false;
    return _dailyChallenges.forDay(_localDayKey()).canClaim(def);
  }

  Future<DailyChallengeClaimResult> claimDailyChallenge(
    DailyChallengeId id,
  ) async {
    if (!isGoogleLinked) return DailyChallengeClaimResult.needsGoogle;
    _rollDailyChallengesIfNeeded();
    final def = dailyChallengeById(id);
    if (def == null) return DailyChallengeClaimResult.incomplete;
    if (_dailyChallenges.isClaimed(id)) {
      return DailyChallengeClaimResult.alreadyClaimed;
    }
    if (!_dailyChallenges.isComplete(def)) {
      return DailyChallengeClaimResult.incomplete;
    }
    _dailyChallenges.claimed.add(id.name);
    notifyListeners();
    if (def.rewardKind == DailyChallengeRewardKind.energy) {
      await grantEnergy(def.reward);
    } else {
      await grantCoins(def.reward);
    }
    await _persistDailyChallenges();
    return DailyChallengeClaimResult.claimed;
  }

  Future<void> noteDailyChallengeProgress({
    required DailyChallengeGameSnap prev,
    required GameState next,
    required String pid,
  }) async {
    if (pid.isEmpty || prev.id != next.id) return;
    _rollDailyChallengesIfNeeded();
    var changed = false;

    if (next.gameMode == GameMode.tresydos) {
      final oldScore = prev.score;
      final newScore = (next.scores[pid] as num?)?.toInt() ?? 0;
      if (newScore > oldScore) {
        for (var score = oldScore + 1; score <= newScore; score++) {
          final eventId = 'tyd:${next.id}:$score';
          if (_dailyChallenges.credited.contains(eventId)) continue;
          _dailyChallenges.credited.add(eventId);
          final cur =
              _dailyChallenges.counts[DailyChallengeId.tydRounds.name] ?? 0;
          _dailyChallenges.counts[DailyChallengeId.tydRounds.name] = cur + 1;
          changed = true;
        }
      }
    }

    final winner = next.winnerId;
    if (next.gameMode == GameMode.casino &&
        next.gameStatus == GameStatus.gameOver &&
        prev.status != GameStatus.gameOver &&
        winner != null &&
        winner.isNotEmpty &&
        winner == pid) {
      final eventId = 'casino:${next.id}';
      if (!_dailyChallenges.credited.contains(eventId)) {
        _dailyChallenges.credited.add(eventId);
        final cur =
            _dailyChallenges.counts[DailyChallengeId.casinoClassic.name] ?? 0;
        _dailyChallenges.counts[DailyChallengeId.casinoClassic.name] = cur + 1;
        changed = true;
      }
    }

    if (!changed) return;
    notifyListeners();
    await _persistDailyChallenges();
  }

  Future<void> debugTweakDailyChallenge(DailyChallengeId id) async {
    if (!kDebugMode) return;
    _rollDailyChallengesIfNeeded();
    final def = dailyChallengeById(id);
    if (def == null) return;
    if (_dailyChallenges.isClaimed(id)) {
      _dailyChallenges.claimed.remove(id.name);
      _dailyChallenges.counts[id.name] = 0;
    } else {
      _dailyChallenges.counts[id.name] = def.goal;
    }
    await _persistDailyChallenges();
    notifyListeners();
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

  String _homeDailyChallengeEnergyPrefsKey(String uid) =>
      'home_daily_challenge_energy_$uid';

  Future<void> _loadHomeDailyChallengeEnergyClaim(String uid) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_homeDailyChallengeEnergyPrefsKey(uid));
      if (raw == null) {
        _pendingHomeDailyChallengeEnergy = {};
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _pendingHomeDailyChallengeEnergy = {};
        return;
      }
      final ids = decoded
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final parsed = <DailyChallengeId>{};
      for (final s in ids) {
        try {
          final id = DailyChallengeId.values.firstWhere((v) => v.name == s);
          // Drop invalid ids (defensive for stored old data).
          if (dailyChallengeById(id) != null) parsed.add(id);
        } catch (_) {}
      }
      _pendingHomeDailyChallengeEnergy = parsed;
    } catch (e) {
      developer.log('AppRepo.loadHomeDailyChallengeEnergyClaim: $e');
      _pendingHomeDailyChallengeEnergy = {};
    }
  }

  Future<void> _persistHomeDailyChallengeEnergyClaim() async {
    final uid = _walletUid;
    if (uid == null) return;
    final sp = await SharedPreferences.getInstance();
    final key = _homeDailyChallengeEnergyPrefsKey(uid);
    if (_pendingHomeDailyChallengeEnergy.isEmpty) {
      await sp.remove(key);
    } else {
      final ids = _pendingHomeDailyChallengeEnergy.map((e) => e.name).toList();
      await sp.setString(key, jsonEncode(ids));
    }
  }

  /// Queue completed daily-challenge energy so it can be claimed with a
  /// "celebrate on home" overlay (no manual Store tap).
  ///
  /// Does not grant until [completeHomeDailyChallengeEnergyClaims].
  Future<void> queueHomeDailyChallengeEnergyClaims(GameState game) async {
    if (game.gameStatus != GameStatus.gameOver) return;
    if (_walletUid == null) return;

    var changed = false;
    for (final def in dailyChallenges) {
      if (_pendingHomeDailyChallengeEnergy.contains(def.id)) continue;
      if (!canClaimDailyChallenge(def)) continue;
      _pendingHomeDailyChallengeEnergy.add(def.id);
      changed = true;
    }
    if (!changed) return;
    await _persistHomeDailyChallengeEnergyClaim();
    notifyListeners();
  }

  /// Grants energy for any queued daily challenges, then clears the queue.
  Future<void> completeHomeDailyChallengeEnergyClaims() async {
    if (_pendingHomeDailyChallengeEnergy.isEmpty) return;

    final pending = _pendingHomeDailyChallengeEnergy.toList(growable: false);
    _pendingHomeDailyChallengeEnergy = {};
    await _persistHomeDailyChallengeEnergyClaim();
    notifyListeners();

    for (final id in pending) {
      await claimDailyChallenge(id);
    }
  }

  /// Stash match winnings to celebrate on home. Does not grant until
  /// [completeHomeCoinClaim]. Zero-amount games just mark payout applied.
  Future<void> queueHomeCoinClaim(GameState game, String me) async {
    if (game.gameStatus != GameStatus.gameOver) return;
    if (game.isPayoutClaimedBy(me)) return;
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
      if (!game.isPayoutClaimedBy(uid)) {
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

  bool canAffordEnergy([GameMode? mode]) {
    final cost = WalletConfig.energyCostFor(mode?.name ?? '');
    return _wallet.energy >= cost;
  }

  bool canAffordStake(int entry) => _wallet.coins >= entry;

  bool get canAffordFriendGame => canAffordStake(WalletConfig.entryCost);

  bool canAffordPuliloEnergy([GameMode? mode]) => canAffordEnergy(mode);

  /// Tables cost energy plus the chosen coin stake.
  bool canAffordPulilo([GameMode? mode, int entry = WalletConfig.entryCost]) {
    return canAffordEnergy(mode) && canAffordStake(entry);
  }

  Future<bool> refundEntryIfNeeded(GameState game) async {
    final uid = _currentUid;
    if (uid == null) return false;
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
    if (game.isPayoutClaimedBy(me)) return;
    if (me.isEmpty) return;
    final amount = game.coinsToClaim(me);
    game.markPayoutClaimedBy(me);
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
    if (notificationsEnabled) {
      unawaited(_syncFcmToken());
    }
    notifyListeners();
  }

  /// Record the match currently on screen, or `null` when the user is
  /// elsewhere / the app is backgrounded. Cloud Functions skip turn
  /// pushes when this matches `games/{gid}`.
  void setActiveGameId(String? gid) {
    if (_activeGameId == gid) return;
    _activeGameId = gid;
    unawaited(_persistActiveGameId());
  }

  Future<void> _persistActiveGameId() {
    _activeGameWrite = _activeGameWrite.catchError((_) {}).then((_) async {
      final gid = _activeGameId;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || player?.id != uid) return;
      try {
        await fs.saveActiveGameId(uid, gid);
      } catch (e) {
        developer.log('AppRepo.saveActiveGameId: $e');
      }
    });
    return _activeGameWrite;
  }

  void _listenForFcmTokenRefresh() {
    _fcmTokenSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(_saveFcmToken(token));
    });
  }

  /// Fetch the current FCM token and write it to users/{uid}.fcmToken.
  Future<void> _syncFcmToken() async {
    if (!notificationsEnabled) return;
    try {
      final messaging = FirebaseMessaging.instance;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        String? apns;
        for (var i = 0; i < 8; i++) {
          apns = await messaging.getAPNSToken();
          if (apns != null) break;
          await Future.delayed(const Duration(milliseconds: 250));
        }
        if (apns == null) {
          developer.log('APNS token not ready yet');
          return;
        }
      }
      final token = await messaging.getToken();
      if (token == null) return;
      await _saveFcmToken(token);
    } catch (e) {
      developer.log('AppRepo._syncFcmToken: $e');
    }
  }

  Future<void> _saveFcmToken(String token) async {
    final current = player;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (current == null || uid == null || current.id != uid) return;
    if (_savedFcmToken == token && current.token == token) return;
    player = current.copyWith(token: token);
    await _persistPlayerLocal();
    try {
      await fs.saveUserToken(uid, token, player!.name);
      _savedFcmToken = token;
      developer.log(
        'FCM token saved for $uid …${token.substring(token.length - 6)}',
        name: 'notifications',
      );
    } catch (e) {
      developer.log('AppRepo.saveUserToken: $e');
    }
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
      await fs.rebindLocalPlayer(fromPid: current.id, toPid: uid);
      player = current.copyWith(id: uid);
      await _persistPlayer();
      await _loadWallet();
      if (notificationsEnabled) {
        _savedFcmToken = null;
        unawaited(_syncFcmToken());
      }
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
      var replaceLocal = false;
      if (current != null && current.isAnonymous) {
        try {
          cred = await current.linkWithPopup(provider);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            cred = await FirebaseAuth.instance.signInWithPopup(provider);
            replaceLocal = true;
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
        replaceLocal = current == null || current.uid != cred.user?.uid;
      }
      return await _afterGoogleUser(
        cred.user,
        cred.user?.displayName,
        replaceLocal: replaceLocal,
      );
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
          return await _afterGoogleUser(
            cred.user,
            googleName,
            replaceLocal: false,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            final cred = await FirebaseAuth.instance.signInWithCredential(
              e.credential ?? credential,
            );
            return await _afterGoogleUser(
              cred.user,
              googleName,
              replaceLocal: true,
            );
          }
          if (e.code == 'provider-already-linked') {
            return await _afterGoogleUser(
              current,
              googleName,
              replaceLocal: false,
            );
          }
          rethrow;
        }
      }
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      return await _afterGoogleUser(
        cred.user,
        googleName,
        replaceLocal: true,
      );
    } on FirebaseAuthException catch (e) {
      if (_isGoogleCanceled(e.code)) {
        return const GoogleAuthResult.canceled();
      }
      rethrow;
    }
  }

  Future<GoogleAuthResult> _afterGoogleUser(
    User? user,
    String? googleName, {
    required bool replaceLocal,
  }) async {
    if (user == null) return const GoogleAuthResult.failed('unknown');
    final suggested = _displayNameFromGoogle(user, googleName);
    final previousUid = player?.id ?? _walletUid;

    Map<String, dynamic>? remote;
    try {
      remote = await fs.loadUserProfile(user.uid);
    } catch (e) {
      developer.log('AppRepo.loadUserProfile: $e');
    }

    if (replaceLocal && _hasCloudProgress(remote)) {
      if (previousUid != null && previousUid != user.uid) {
        await _clearUidLocalCache(previousUid);
      }
      try {
        await fs.clearDeviceGames();
      } catch (e) {
        developer.log('AppRepo.clearDeviceGames: $e');
      }
      _applyLooksFromRemote(remote, replace: true);
      player = _mergePlayer(
        user.uid,
        local: null,
        remote: remote,
        suggestedName: suggested,
      );
      await _persistLooksLocal();
      await _persistPlayerLocal();
      await _loadWallet(preferRemote: true);
      if (notificationsEnabled) {
        _savedFcmToken = null;
        unawaited(_syncFcmToken());
      }
      notifyListeners();
      return GoogleAuthResult.success(suggested ?? player?.name);
    }

    if (player != null && previousUid != null && previousUid != user.uid) {
      await fs.rebindLocalPlayer(fromPid: previousUid, toPid: user.uid);
      player = player!.copyWith(id: user.uid);
      _walletUid = user.uid;
      await _persistWallet();
      await _clearUidLocalCache(previousUid);
    } else if (player == null || player!.id != user.uid) {
      player = await _playerFromRemoteOrLocal(user.uid, suggested);
    }

    if (player!.needsAccountSetup && suggested != null) {
      player = player!.copyWith(name: suggested);
    }

    await _persistPlayer();
    await _persistLooks();
    if (_walletUid != user.uid) {
      _walletUid = user.uid;
      await _persistWallet();
    } else {
      await _loadWallet();
    }
    if (notificationsEnabled) {
      _savedFcmToken = null;
      unawaited(_syncFcmToken());
    }
    notifyListeners();
    return GoogleAuthResult.success(suggested ?? player?.name);
  }

  bool _hasCloudProgress(Map<String, dynamic>? remote) {
    if (remote == null || remote.isEmpty) return false;
    final name = (remote['name'] ?? remote['displayName']) as String?;
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty &&
        !(trimmed.startsWith('p_') && trimmed.length <= 12)) {
      return true;
    }
    if (remote['completedTutorial'] == true) return true;
    final avatar = remote['avatarId'] as String?;
    if (avatar != null &&
        avatar.isNotEmpty &&
        avatar != Player.defaultAvatarId) {
      return true;
    }
    if (Wallet.hasWalletFields(remote)) {
      final wallet = Wallet.fromJson(remote);
      if (wallet.coins != WalletConfig.startingCoins ||
          wallet.energy != WalletConfig.startingEnergy) {
        return true;
      }
    }
    final extra = _packsFromNames(remote['ownedPacks']);
    extra.removeAll(defaultOwnedPacks);
    for (final pack in themePackCatalog) {
      if (pack.unlock == ThemeUnlockKind.free) extra.remove(pack.id);
    }
    return extra.isNotEmpty;
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
    _ownedPacks = {...defaultOwnedPacks};
    final savedPacks = sp.getStringList(_ownedPacksKey);
    if (savedPacks != null) {
      for (final name in savedPacks) {
        for (final value in Theme.values) {
          if (value.name == name) {
            _ownedPacks.add(value);
            break;
          }
        }
      }
    }
    for (final pack in themePackCatalog) {
      if (pack.unlock == ThemeUnlockKind.free) {
        _ownedPacks.add(pack.id);
      }
    }

    final name = switch (sp.getString(_themeKey)) {
      'feltWaltnut' => 'sage',
      final value => value,
    };
    var loadedTheme = false;
    if (name != null) {
      for (final value in Theme.values) {
        if (value.name == name && ownsPack(value)) {
          _appTheme = value;
          loadedTheme = true;
          break;
        }
      }
    }
    if (!loadedTheme) {
      _appTheme = Theme.sage;
    }
    AppStyle.theme = selectedTheme;

    final backName = switch (sp.getString(_cardBackKey)) {
      'brass' => 'clay',
      'ink' => 'tide',
      'walnut' => 'sage',
      final name => name,
    };
    var loadedBack = false;
    if (backName != null) {
      for (final value in CardBack.values) {
        if (value.name == backName && ownsCardBack(value)) {
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

    var mark = CardBackMark.logo;
    final markName = sp.getString(_cardBackMarkKey) ?? sp.getString('cardFaceMark');
    if (markName != null) {
      for (final value in CardBackMark.values) {
        if (value.name == markName) {
          mark = value;
          break;
        }
      }
    } else {
      final legacy = sp.getString('cardFaceStyle');
      if (legacy == 'show') mark = CardBackMark.logo;
      if (legacy == 'classic' || legacy == 'plain') mark = CardBackMark.none;
    }
    _cardBackMark = mark;
    AppStyle.cardBackMark = mark;

    final tintName =
        sp.getString(_cardBackTintKey) ?? sp.getString('cardFaceTint');
    _cardBackTintId = coerceTintForTheme(
      tintName ?? themePack(_appTheme).defaultTintId,
      _appTheme,
    );
    AppStyle.cardBackTintId = _cardBackTintId;
  }

  Future<void> _persistTheme() => _persistLooks();

  Future<void> _persistCardBack() => _persistLooks();

  Future<void> _persistCardFace() => _persistLooks();

  Future<void> _persistOwnedPacks() => _persistLooks();

  Future<void> _persistLooks() async {
    await _persistLooksLocal();
    await _persistLooksRemote();
  }

  Future<void> _persistLooksLocal() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_themeKey, _appTheme.name);
    await sp.setString(_cardBackKey, _cardBack.name);
    await sp.setString(_cardBackMarkKey, _cardBackMark.name);
    await sp.setString(_cardBackTintKey, _cardBackTintId);
    await sp.setStringList(
      _ownedPacksKey,
      _ownedPacks.map((pack) => pack.name).toList(),
    );
  }

  Future<void> _persistLooksRemote() async {
    await _persistPlayerRemote();
  }

  void _syncLooksToAppStyle() {
    AppStyle.theme = selectedTheme;
    AppStyle.cardBack = _cardBack;
    AppStyle.cardBackMark = _cardBackMark;
    AppStyle.cardBackTintId = _cardBackTintId;
  }

  Set<Theme> _packsFromNames(Iterable<dynamic>? names) {
    final out = <Theme>{};
    if (names == null) return out;
    for (final name in names) {
      if (name is! String) continue;
      for (final value in Theme.values) {
        if (value.name == name) {
          out.add(value);
          break;
        }
      }
    }
    return out;
  }

  Theme? _themeByName(String? name) {
    final resolved = switch (name) {
      'feltWaltnut' => 'sage',
      final value => value,
    };
    if (resolved == null) return null;
    for (final value in Theme.values) {
      if (value.name == resolved) return value;
    }
    return null;
  }

  CardBack? _cardBackByName(String? name) {
    final resolved = switch (name) {
      'brass' => 'clay',
      'ink' => 'tide',
      'walnut' => 'sage',
      final value => value,
    };
    if (resolved == null) return null;
    for (final value in CardBack.values) {
      if (value.name == resolved) return value;
    }
    return null;
  }

  void _resetLooksInMemory() {
    _ownedPacks = {
      ...defaultOwnedPacks,
      for (final pack in themePackCatalog)
        if (pack.unlock == ThemeUnlockKind.free) pack.id,
    };
    _appTheme = Theme.sage;
    _cardBack = defaultCardBackFor(_appTheme);
    _cardBackMark = CardBackMark.logo;
    _cardBackTintId = themePack(_appTheme).defaultTintId;
    _syncLooksToAppStyle();
  }

  void _applyLooksFromRemote(
    Map<String, dynamic>? remote, {
    required bool replace,
  }) {
    if (replace) _resetLooksInMemory();
    if (remote == null) {
      _syncLooksToAppStyle();
      return;
    }
    _ownedPacks.addAll(_packsFromNames(remote['ownedPacks']));
    for (final pack in themePackCatalog) {
      if (pack.unlock == ThemeUnlockKind.free) {
        _ownedPacks.add(pack.id);
      }
    }
    final remoteTheme = _themeByName(remote['appTheme'] as String?);
    if (replace || !ownsPack(_appTheme)) {
      if (remoteTheme != null && ownsPack(remoteTheme)) {
        _appTheme = remoteTheme;
      } else if (!ownsPack(_appTheme)) {
        _appTheme = Theme.sage;
      }
    }
    final remoteBack = _cardBackByName(remote['cardBack'] as String?);
    if (replace || !ownsCardBack(_cardBack)) {
      if (remoteBack != null && ownsCardBack(remoteBack)) {
        _cardBack = remoteBack;
      } else if (!ownsCardBack(_cardBack)) {
        _cardBack = defaultCardBackFor(_appTheme);
      }
    }
    if (replace) {
      final markName = remote['cardBackMark'] as String?;
      if (markName != null) {
        for (final value in CardBackMark.values) {
          if (value.name == markName) {
            _cardBackMark = value;
            break;
          }
        }
      }
      final tintName = remote['cardBackTint'] as String?;
      _cardBackTintId = coerceTintForTheme(
        tintName ?? themePack(_appTheme).defaultTintId,
        _appTheme,
      );
    } else {
      _cardBackTintId = coerceTintForTheme(_cardBackTintId, _appTheme);
    }
    _syncLooksToAppStyle();
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

  Future<String> createNewGame(
    GameMode mode,
    String pid,
    bool local, {
    int playerCount = 2,
    int entryCost = WalletConfig.entryCost,
    int turnDurationSeconds = WalletConfig.defaultSpeedTurnSeconds,
  }) async {
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
    final energyCost = WalletConfig.energyCostFor(mode.name);
    final allowNoBet =
        mode == GameMode.casino ||
        mode == GameMode.casinoSpeed ||
        mode == GameMode.tresydos;
    final stake = WalletConfig.isAllowedStake(
          entryCost,
          allowNoBet: allowNoBet,
        )
        ? entryCost
        : WalletConfig.entryCost;
    if (_wallet.energy < energyCost) {
      throw const InsufficientFundsException(energy: true);
    }
    if (_wallet.coins < stake) {
      throw const InsufficientFundsException(energy: false);
    }

    String gid = _uuid.v4().substring(0, 8);
    GameState gameState = GameState.create(gid, pid, mode);
    gameState.entryCost = stake;
    gameState.entryPaidBy = [pid];
    if (mode == GameMode.casinoSpeed) {
      gameState.turnDurationSeconds =
          WalletConfig.isAllowedSpeedTurn(turnDurationSeconds)
          ? turnDurationSeconds
          : WalletConfig.defaultSpeedTurnSeconds;
    }
    final host = player;
    if (host != null) {
      gameState.playersInfo[pid] = host.toGameSeat();
    } else {
      gameState.playersInfo[pid] = {'id': pid};
    }
    if (local) {
      final botCount =
          (mode == GameMode.tresydos ? playerCount.clamp(2, 4) : 2) - 1;
      final profiles = LocalBotRoster.pick(
        botCount,
        avoidAvatarId: host?.avatarId,
      );
      final botPids = <String>[];
      gameState.isLocalBot = true;
      for (final profile in profiles) {
        final botPid = _uuid.v4().substring(0, 8);
        botPids.add(botPid);
        gameState.playersInfo[botPid] = {
          'id': botPid,
          'name': profile.name,
          'avatarId': profile.avatarId,
        };
      }
      gameState.botPlayerIds = botPids;
      gameState.botPlayerId = botPids.isEmpty ? null : botPids.first;
      if (botPids.isNotEmpty) {
        gameState.gameStatus = GameStatus.readyToStart;
      }
    }
    debugPrint(
      'createNewGame uid=$pid controller=${gameState.controllerId} '
      'auth=${FirebaseAuth.instance.currentUser?.uid} local=$local',
    );
    gid = await fs.newCreateGame(gameState);
    var spentEnergy = false;
    var spentCoins = false;
    try {
      spentEnergy = await trySpendEnergy(energyCost);
      if (!spentEnergy) {
        throw const InsufficientFundsException(energy: true);
      }
      spentCoins = await trySpendCoins(stake);
      if (!spentCoins) {
        throw const InsufficientFundsException(energy: false);
      }
    } catch (e) {
      if (spentEnergy) await grantEnergy(energyCost);
      if (spentCoins) await grantCoins(stake);
      try {
        await fs.deleteGame(gid);
      } catch (_) {}
      rethrow;
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

    notificationsEnabled = true;
    await NotificationsService.instance.configure();
    await _syncFcmToken();
    notifyListeners();
    return true;
  }

  /// Debug: mark energy-full as due so onEnergyFull can send on its next
  /// minute tick. Does not use a callable (v2 IAM blocks those here).
  Future<bool> testEnergyFullNotification() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('testEnergyFull failed: no FirebaseAuth user');
      return false;
    }
    _walletPersistPaused = true;
    _energyTestTimer?.cancel();
    try {
      await fs.armEnergyFullNotification(uid);
      debugPrint(
        'testEnergyFull: armed energyFullAt. '
        'Keep this screen (or lock the phone). Banner within ~1 min.',
      );
      _energyTestTimer = Timer(const Duration(minutes: 2), () {
        _walletPersistPaused = false;
        unawaited(_persistWallet());
        debugPrint('testEnergyFull: restored wallet persist');
      });
      return true;
    } catch (e) {
      _walletPersistPaused = false;
      debugPrint('testEnergyFull failed: $e');
      return false;
    }
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
        unawaited(_saveFcmToken(player!.token!));
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

  /// Sign out of Google and wipe this device. Cloud profile stays.
  Future<void> logOut() async {
    await _endAuthSession(keepCloud: true);
  }

  /// Wipe this device's cached profile and sign out.
  /// Guest cloud docs are deleted. Google cloud data stays for next sign-in.
  Future<void> deleteLocalAccount() async {
    await _endAuthSession(keepCloud: false, deleteAuthUser: false);
  }

  /// Permanently delete the signed-in account and all of its cloud data.
  Future<DeleteAccountResult> deleteAccount() async {
    try {
      await _endAuthSession(
        keepCloud: false,
        deleteAuthUser: isGoogleLinked,
      );
      return DeleteAccountResult.success;
    } on StateError catch (e) {
      if (e.message == 'delete-canceled') {
        return DeleteAccountResult.canceled;
      }
      developer.log('AppRepo.deleteAccount: $e', error: e);
      return DeleteAccountResult.failed;
    } catch (e, st) {
      developer.log('AppRepo.deleteAccount: $e', error: e, stackTrace: st);
      return DeleteAccountResult.failed;
    }
  }

  /// Flush or delete cloud data, then drop the local session.
  /// Never write a starter wallet while the previous user is still signed in.
  Future<void> _endAuthSession({
    required bool keepCloud,
    bool deleteAuthUser = false,
  }) async {
    final uid = player?.id ?? FirebaseAuth.instance.currentUser?.uid;
    final walletUid = _walletUid ?? uid;
    final walletToFlush = _wallet;

    _walletPersistPaused = true;
    _energyTimer?.cancel();
    _energyTimer = null;
    _dailyRewardTimer?.cancel();
    _dailyRewardTimer = null;

    if (keepCloud && walletUid != null) {
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
    } else if (!keepCloud && uid != null) {
      try {
        await fs.deleteUserProfile(uid);
      } catch (e) {
        developer.log('AppRepo.deleteUserProfile: $e');
      }
    }

    if (deleteAuthUser) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') rethrow;
        final reauthed = await _reauthenticateGoogle();
        if (!reauthed) {
          _walletPersistPaused = false;
          _ensureEnergyTicker();
          throw StateError('delete-canceled');
        }
        await FirebaseAuth.instance.currentUser?.delete();
      }
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }

    await _clearLocalSession();
    _loadFuture = null;
    _walletPersistPaused = false;
    await loadApp();
  }

  Future<bool> _reauthenticateGoogle() async {
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) return false;
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        await current.reauthenticateWithPopup(provider);
        return true;
      }
      await _ensureGoogleSignIn();
      final account = await _googleAccountForReauth();
      if (account == null) return false;
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) return false;
      await current.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      developer.log('AppRepo.reauthenticateGoogle GoogleSignIn: $e');
      return false;
    } on FirebaseAuthException catch (e) {
      if (_isGoogleCanceled(e.code)) return false;
      developer.log('AppRepo.reauthenticateGoogle Auth: ${e.code}', error: e);
      return false;
    } catch (e, st) {
      developer.log(
        'AppRepo.reauthenticateGoogle: $e',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<GoogleSignInAccount?> _googleAccountForReauth() async {
    try {
      final pending = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (pending != null) {
        final existing = await pending;
        final token = existing?.authentication.idToken;
        if (existing != null && token != null && token.isNotEmpty) {
          return existing;
        }
      }
    } catch (e) {
      developer.log('AppRepo.reauthenticateGoogle lightweight: $e');
    }
    try {
      return await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) rethrow;
      developer.log('AppRepo.reauthenticateGoogle authenticate: $e');
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      return GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
    }
  }

  Future<void> _clearUidLocalCache(String uid) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_walletPrefsKey(uid));
    await sp.remove(_homeCoinClaimPrefsKey(uid));
    await sp.remove(_homeDailyChallengeEnergyPrefsKey(uid));
    await sp.remove(_dailyClaimPrefsKey(uid));
    await sp.remove(_dailyChallengesPrefsKey(uid));
  }

  Future<void> _clearLocalSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('player_id');
    await sp.remove(_themeKey);
    await sp.remove(_cardBackKey);
    await sp.remove(_cardBackMarkKey);
    await sp.remove(_cardBackTintKey);
    await sp.remove(_ownedPacksKey);
    await sp.remove('cardFaceMark');
    await sp.remove('cardFaceTint');
    await sp.remove('cardFaceStyle');
    for (final key in sp.getKeys().toList()) {
      if (key.startsWith('wallet_') ||
          key.startsWith('home_coin_claim_') ||
          key.startsWith('daily_claim_') ||
          key.startsWith('daily_challenges_')) {
        await sp.remove(key);
      }
    }
    try {
      await fs.clearDeviceGames();
    } catch (e) {
      developer.log('AppRepo.clearDeviceGames: $e');
    }
    player = null;
    _wallet = Wallet.starter();
    _walletUid = null;
    _pendingHomeCoinClaim = null;
    _pendingHomeDailyChallengeEnergy = {};
    _lastDailyClaimAt = null;
    _dailyChallenges = DailyChallengeState.empty(_localDayKey());
    _resetLooksInMemory();
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
        ownedPacks: _ownedPacks.map((pack) => pack.name).toList(),
        appTheme: _appTheme.name,
        cardBack: _cardBack.name,
        cardBackMark: _cardBackMark.name,
        cardBackTint: _cardBackTintId,
        locale: _locale.languageCode,
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

      Player? local;
      if (cached != null && cached.id == uid) {
        local = cached;
      } else if (cached != null && cached.id != uid) {
        await fs.rebindLocalPlayer(fromPid: cached.id, toPid: uid);
        local = cached.copyWith(id: uid);
      }

      player = _mergePlayer(uid, local: local, remote: remote);
      _applyLooksFromRemote(remote, replace: false);
      await _persistLooksLocal();
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
