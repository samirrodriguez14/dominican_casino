import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum GameSound { deal, capture, win, illegal, yourTurn }

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool enabled = true;

  static const _assets = {
    GameSound.deal: 'sounds/deal.wav',
    GameSound.capture: 'sounds/capture.wav',
    GameSound.win: 'sounds/win.wav',
    GameSound.illegal: 'sounds/illegal.wav',
    GameSound.yourTurn: 'sounds/your_turn.wav',
  };

  Future<void> play(GameSound sound) async {
    if (!enabled) return;
    final path = _assets[sound];
    if (path == null) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(path));
    } catch (e) {
      debugPrint('SoundService: $e');
    }
  }
}
