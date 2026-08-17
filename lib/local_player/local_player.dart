import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/casino/handlers/casino_game_state_handler.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/local_player/casino_player.dart';
import 'package:dominican_casino/local_player/tresdos_player.dart';
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
  String name = GameState.localBotName;
  GameRepo gameRepo;
  GameMode mode;
  late GameEngine engine;
  bool _busy = false;
  bool _pending = false;
  bool _disposed = false;

  /// Recreate the on-device AI after a cold start, or drop it for a human match.
  static void ensureAttached(GameRepo gameRepo, GameState state) {
    final botId = state.localBotPid;
    if (botId == null || botId.isEmpty) {
      _active?.dispose();
      _active = null;
      return;
    }
    if (_active != null &&
        _active!.pid == botId &&
        identical(_active!.gameRepo, gameRepo)) {
      return;
    }
    _active?.dispose();
    _active = LocalPlayer(gameRepo: gameRepo, mode: state.gameMode, pid: botId);
  }

  LocalPlayer({required this.gameRepo, required this.mode, String? pid}) {
    if (pid != null) this.pid = pid;
    final created = GameRegistry.createEngine(mode);
    if (created == null) {
      throw StateError('No engine for mode $mode');
    }
    engine = created;
    gameRepo.addListener(_onGameRepoChanged);
    developer.log(
      "LocalPlayer. pid: ${this.pid}, Mode: $mode, Engine: $engine",
    );
  }

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
        if (state.controllerId == pid &&
            state.gameMode == GameMode.casino &&
            CasinoGameStateHandler.shouldDealSameRound(state)) {
          await Future.delayed(const Duration(milliseconds: 700));
          if (_disposed) return false;
          final current = gameRepo.gameState;
          if (current == null ||
              current.controllerId != pid ||
              !CasinoGameStateHandler.shouldDealSameRound(current)) {
            return false;
          }
          final next = engine.performInGameAction(
            current,
            InGameAction.dealSame,
            pid,
          );
          await _persist(next);
          return true;
        }

        if (state.currentTurnPlayerId != pid) return false;

        final PossibleSelection bestAction;
        switch (state.gameMode) {
          case GameMode.tresydos:
            bestAction = await TresdosPlayer.tresdosBestAction(pid, state);
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
        await _persist(next);
        return true;

      case RoundStatus.completed:
        if (state.controllerId != pid) return false;
        if (!state.round.nextAcknowledged) return false;

        final next = engine.performInGameAction(
          state,
          InGameAction.shuffle,
          pid,
        );
        await _persist(next);
        return true;

      case RoundStatus.readyToDeal:
        if (state.controllerId != pid) return false;

        // Pause so the human can see the undealt table.
        await Future.delayed(const Duration(milliseconds: 1200));
        if (_disposed) return false;
        final current = gameRepo.gameState;
        if (current == null ||
            current.round.roundStatus != RoundStatus.readyToDeal ||
            current.controllerId != pid) {
          return false;
        }

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
