import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/game_engine/casino/casino_game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/casino/handlers/casino_game_state_handler.dart';
import 'package:dominican_casino/game_control/game_engine/game_engine.dart';
import 'package:dominican_casino/game_control/game_engine/tresydos/tres_dos_game_engine.dart';
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
  String pid = "localjohn";
  String name = "john";
  late GameState _gameState;
  GameRepo gameRepo;
  GameMode mode;
  late GameEngine engine;
  LocalPlayer({required this.gameRepo, required this.mode}) {
    switch (mode) {
      case .casino:
        engine = CasinoGameEngine(gameService: gameRepo.fs);
        break;
      case .tresydos:
        engine = TresDosGameEngine(gameService: gameRepo.fs);
        break;

      default:
        engine = CasinoGameEngine(gameService: gameRepo.fs);
    }
    gameRepo.addListener(_onGameRepoChanged);
    developer.log("LocalPlayer. Mode: $mode, Engine: $engine");
  }
  Future<void> _onGameRepoChanged() async {
    try {
      _gameState = gameRepo.gameState!;
      await Future.delayed(Duration(microseconds: 500));

      switch (_gameState.gameStatus) {
        case GameStatus.inProgress:
          switch (_gameState.round.roundStatus) {
            case RoundStatus.playing:
              //HANDLE DEALING SAME ROUND
              if (_gameState.controllerId == pid &&
                  CasinoGameStateHandler.shouldDealSameRound(_gameState)) {
                await engine.performInGameAction(_gameState, .dealSame, pid);
                return;
              }
              //HANDLE PLAY ACTION
              if (_gameState.currentTurnPlayerId != pid) return;
              PossibleSelection bestAction;
              switch (_gameState.gameMode) {
                case .tresydos:
                  bestAction = await TresdosPlayer.tresdosBestAction(
                    pid,
                    _gameState,
                  );
                default:
                  bestAction = await CasinoPlayer.casinoBestAction(
                    pid,
                    _gameState,
                  );
              }
              developer.log("LocalPlayer._onGameRepoChanged $bestAction");
              await Future.delayed(Duration(seconds: 1));

              _gameState = await engine.performPlayAction(
                _gameState,
                bestAction.cardSelection,
                bestAction.playAction,
              );
            case RoundStatus.completed:
              //HANLDE DEALING NEW ROUND
              if (_gameState.controllerId != pid) return;
              InGameAction action = InGameAction.shuffle;
              await engine.performInGameAction(_gameState, action, pid);
            case RoundStatus.readyToDeal:
              if (_gameState.controllerId != pid) return;

              engine.performInGameAction(_gameState, .deal, pid);
          }
        case GameStatus.gameOver:
        case GameStatus.error:
        default:
      }

      // notifyListeners();
    } catch (e) {
      developer.log("LocalPlayer._onGameRepoChanged Error $e");
      notifyListeners();
    }
  }
}
