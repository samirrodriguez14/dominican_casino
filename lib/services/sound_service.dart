import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum GameSound { deal, capture, shuffle, win, illegal, softCard }

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  /// Max overlapping card ticks so a big deal/capture does not become a wash.
  static const cardTickMax = 6;

  final AudioPlayer _oneshot = AudioPlayer();
  final List<AudioPlayer> _layers = List.generate(
    cardTickMax,
    (_) => AudioPlayer(),
  );
  int _layer = 0;
  bool enabled = true;

  static const _assets = {
    GameSound.deal: 'sounds/deal.wav',
    GameSound.capture: 'sounds/capture.wav',
    GameSound.shuffle: 'sounds/shuffle.wav',
    GameSound.win: 'sounds/win.wav',
    GameSound.illegal: 'sounds/illegal.wav',
    GameSound.softCard: 'sounds/soft_card.wav',
  };

  Future<void> play(GameSound sound) async {
    if (!enabled) return;
    final path = _assets[sound];
    if (path == null) return;
    try {
      await _oneshot.stop();
      await _oneshot.play(AssetSource(path));
    } catch (e) {
      debugPrint('SoundService: $e');
    }
  }

  /// Overlapping one-shot (card ticks). Does not cut the previous tick.
  Future<void> playLayered(GameSound sound, {double volume = 1}) async {
    if (!enabled) return;
    final path = _assets[sound];
    if (path == null) return;
    final player = _layers[_layer % _layers.length];
    _layer++;
    try {
      await player.stop();
      await player.setVolume(volume.clamp(0, 1));
      await player.play(AssetSource(path));
    } catch (e) {
      debugPrint('SoundService: $e');
    }
  }
}
