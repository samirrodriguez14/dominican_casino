import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/casino_coin_bonuses.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/casino_game_state_handler.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/local_player/casino_player.dart';
import 'package:dominican_casino/local_player/tresdos_player.dart';
import 'package:dominican_casino/local_player/rummy_player.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:flutter/cupertino.dart';

class PossibleSelection {
  CurrentCardSelection cardSelection;
  PlayAction playAction;
  int scoreValue;
  PossibleSelection({
    required this.playAction,
    required this.cardSelection,
    required this.scoreValue,
  });
  @override
  String toString() {
    return "scoreValue: $scoreValue, $playAction, $cardSelection";
  }
}

class LocalPlayer extends ChangeNotifier {
  static LocalPlayer? _active;

  String pid = "elabusador";
  final List<String> botPids;
  String name = GameState.localBotName;
  GameRepo gameRepo;
  GameMode mode;
  late GameEngine engine;
  bool _busy = false;
  bool _pending = false;
  bool _disposed = false;

  /// Recreate the on-device AI after a cold start, or drop it for a human match.
  static void ensureAttached(GameRepo gameRepo, GameState state) {
    final botIds = state.localBotPids;
    if (botIds.isEmpty) {
      _active?.dispose();
      _active = null;
      return;
    }
    if (_active != null &&
        identical(_active!.gameRepo, gameRepo) &&
        _sameBots(_active!.botPids, botIds)) {
      return;
    }
    _active?.dispose();
    _active = LocalPlayer(
      gameRepo: gameRepo,
      mode: state.gameMode,
      botPids: botIds,
    );
  }

  static bool _sameBots(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final other = b.toSet();
    return a.every(other.contains);
  }

  LocalPlayer({
    required this.gameRepo,
    required this.mode,
    List<String>? botPids,
    String? pid,
  }) : botPids = List<String>.from(
         botPids ?? (pid != null && pid.isNotEmpty ? [pid] : const []),
       ) {
    if (this.botPids.isNotEmpty) this.pid = this.botPids.first;
    if (pid != null && pid.isNotEmpty) this.pid = pid;
    final created = GameRegistry.createEngine(mode);
    if (created == null) {
      throw StateError('No engine for mode $mode');
    }
    engine = created;
    gameRepo.addListener(_onGameRepoChanged);
    developer.log(
      "LocalPlayer. pids: ${this.botPids}, Mode: $mode, Engine: $engine",
    );
  }

  bool _isOurBot(String? id) =>
      id != null && id.isNotEmpty && botPids.contains(id);

  @override
  void dispose() {
    _disposed = true;
    if (identical(_active, this)) _active = null;
    gameRepo.removeListener(_onGameRepoChanged);
    super.dispose();
  }

  Future<void> _persist(GameState state) async {
    await gameRepo.fs.updateGame(state);
  }

  Future<void> _onGameRepoChanged() async {
    if (_disposed) return;
    if (_busy) {
      _pending = true;
      return;
    }
    _busy = true;
    try {
      // Keep acting across phase changes (e.g. shuffle → readyToDeal → deal).
      do {
        _pending = false;
        await Future.delayed(const Duration(milliseconds: 350));
        if (_disposed) return;
        final latest = gameRepo.gameState;
        if (latest == null) break;

        final acted = await _tryAct(latest);
        if (acted) {
          // Another phase may need us (deal after shuffle, play after deal).
          _pending = true;
        }
      } while (_pending && !_disposed);
    } catch (e) {
      developer.log("LocalPlayer._onGameRepoChanged Error $e");
      if (!_disposed) notifyListeners();
    } finally {
      _busy = false;
      if (_pending && !_disposed) {
        _pending = false;
        _onGameRepoChanged();
      }
    }
  }

  /// Returns true if this bot wrote a new game state.
  Future<bool> _tryAct(GameState state) async {
    if (state.gameStatus != GameStatus.inProgress) return false;

    switch (state.round.roundStatus) {
      case RoundStatus.playing:
        if (_isOurBot(state.controllerId) &&
            GameRegistry.isCasinoFamily(state.gameMode) &&
            CasinoGameStateHandler.shouldDealSameRound(state)) {
          await Future.delayed(const Duration(milliseconds: 700));
          if (_disposed) return false;
          final current = gameRepo.gameState;
          if (current == null ||
              !_isOurBot(current.controllerId) ||
              !CasinoGameStateHandler.shouldDealSameRound(current)) {
            return false;
          }
          pid = current.controllerId;
          final next = engine.performInGameAction(
            current,
            InGameAction.dealSame,
            pid,
          );
          await _persist(next);
          return true;
        }

        if (!_isOurBot(state.currentTurnPlayerId)) return false;
        pid = state.currentTurnPlayerId!;

        final PossibleSelection bestAction;
        switch (state.gameMode) {
          case GameMode.tresydos:
            bestAction = await TresdosPlayer.tresdosBestAction(pid, state);
          case GameMode.rummy:
            bestAction = await RummyPlayer.rummyBestAction(pid, state);
          default:
            bestAction = await CasinoPlayer.casinoBestAction(pid, state);
        }

        await Future.delayed(const Duration(milliseconds: 900));
        if (_disposed) return false;
        final current = gameRepo.gameState;
        if (current == null || current.currentTurnPlayerId != pid) {
          return false;
        }

        final next = engine.performPlayAction(
          current,
          bestAction.cardSelection,
          bestAction.playAction,
        );
        CasinoCoinBonuses.accrueAfterPlay(next, bestAction.playAction);
        await _persist(next);
        return true;

      case RoundStatus.completed:
        if (!_isOurBot(state.controllerId)) return false;
        if (!state.round.nextAcknowledged) return false;
        await Future.delayed(const Duration(milliseconds: 900));
        if (_disposed) return false;
        final afterWait = gameRepo.gameState;
        if (afterWait == null ||
            afterWait.round.roundStatus != RoundStatus.completed ||
            !afterWait.round.nextAcknowledged ||
            !_isOurBot(afterWait.controllerId)) {
          return false;
        }
        pid = afterWait.controllerId;

        // Copy first — in-place shuffle would also clear the board's
        // GameState, and the gather-wash overlay would have nothing to fly.
        final next = engine.performInGameAction(
          GameState.fromMap(afterWait.toJson()),
          InGameAction.shuffle,
          pid,
        );
        gameRepo.gameState = next;
        gameRepo.notifyListeners();
        await _persist(next);
        return true;

      case RoundStatus.readyToDeal:
        if (!_isOurBot(state.controllerId)) return false;

        // Pause so the human can see the undealt table after shuffle motion.
        await Future.delayed(const Duration(milliseconds: 2500));
        if (_disposed) return false;
        final current = gameRepo.gameState;
        if (current == null ||
            current.round.roundStatus != RoundStatus.readyToDeal ||
            !_isOurBot(current.controllerId)) {
          return false;
        }
        pid = current.controllerId;

        final next = engine.performInGameAction(
          current,
          InGameAction.deal,
          pid,
        );
        await _persist(next);
        return true;
    }
  }
}
