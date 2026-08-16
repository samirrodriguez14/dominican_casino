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
  String pid = "elabusador";
  String name = "Pulilo";
  late GameState _gameState;
  GameRepo gameRepo;
  GameMode mode;
  late GameEngine engine;

  LocalPlayer({required this.gameRepo, required this.mode}) {
    final created = GameRegistry.createEngine(mode);
    if (created == null) {
      throw StateError('No engine for mode $mode');
    }
    engine = created;
    gameRepo.addListener(_onGameRepoChanged);
    developer.log("LocalPlayer. Mode: $mode, Engine: $engine");
  }

  Future<void> _persist(GameState state) async {
    await gameRepo.fs.updateGame(state);
  }

  Future<void> _onGameRepoChanged() async {
    try {
      _gameState = gameRepo.gameState!;
      await Future.delayed(Duration(microseconds: 500));

      switch (_gameState.gameStatus) {
        case GameStatus.inProgress:
          switch (_gameState.round.roundStatus) {
            case RoundStatus.playing:
              if (_gameState.controllerId == pid &&
                  _gameState.gameMode == GameMode.casino &&
                  CasinoGameStateHandler.shouldDealSameRound(_gameState)) {
                _gameState = engine.performInGameAction(
                  _gameState,
                  InGameAction.dealSame,
                  pid,
                );
                await _persist(_gameState);
                return;
              }
              if (_gameState.currentTurnPlayerId != pid) return;
              PossibleSelection bestAction;
              switch (_gameState.gameMode) {
                case GameMode.tresydos:
                  bestAction = await TresdosPlayer.tresdosBestAction(
                    pid,
                    _gameState,
                  );
                  break;
                default:
                  bestAction = await CasinoPlayer.casinoBestAction(
                    pid,
                    _gameState,
                  );
                  break;
              }
              await Future.delayed(Duration(seconds: 1));

              _gameState = engine.performPlayAction(
                _gameState,
                bestAction.cardSelection,
                bestAction.playAction,
              );
              await _persist(_gameState);
              break;
            case RoundStatus.completed:
              if (_gameState.controllerId != pid) return;
              _gameState = engine.performInGameAction(
                _gameState,
                InGameAction.shuffle,
                pid,
              );
              await _persist(_gameState);
              break;
            case RoundStatus.readyToDeal:
              if (_gameState.controllerId != pid) return;
              _gameState = engine.performInGameAction(
                _gameState,
                InGameAction.deal,
                pid,
              );
              await _persist(_gameState);
          }
        case GameStatus.gameOver:
        case GameStatus.error:
        default:
      }
    } catch (e) {
      developer.log("LocalPlayer._onGameRepoChanged Error $e");
      notifyListeners();
    }
  }
}
