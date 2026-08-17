import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameSound { deal, capture, shuffle, win, illegal, softCard }

class SoundService extends ChangeNotifier {
  SoundService._();
  static final SoundService instance = SoundService._();

  /// Max overlapping card ticks so a big deal/capture does not become a wash.
  static const cardTickMax = 6;

  static const _sfxKey = 'sfx_enabled';
  static const _musicKey = 'music_enabled';
  static const _musicAsset = 'sounds/bg_music.mp3';

  final AudioPlayer _oneshot = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  final List<AudioPlayer> _layers = List.generate(
    cardTickMax,
    (_) => AudioPlayer(),
  );
  int _layer = 0;

  bool sfxEnabled = true;
  bool musicEnabled = true;
  bool _musicPlaying = false;
  bool _loaded = false;

  static const _assets = {
    GameSound.deal: 'sounds/deal.wav',
    GameSound.capture: 'sounds/capture.wav',
    GameSound.shuffle: 'sounds/shuffle.wav',
    GameSound.win: 'sounds/win.wav',
    GameSound.illegal: 'sounds/illegal.wav',
    GameSound.softCard: 'sounds/soft_card.wav',
  };

  /// Kept for call sites that still use [enabled].
  bool get enabled => sfxEnabled;
  set enabled(bool value) => setSfxEnabled(value);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final sp = await SharedPreferences.getInstance();
    sfxEnabled = sp.getBool(_sfxKey) ?? true;
    musicEnabled = sp.getBool(_musicKey) ?? true;
    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setVolume(0.35);
    notifyListeners();
    if (musicEnabled) await startMusic();
  }

  Future<void> setSfxEnabled(bool value) async {
    if (sfxEnabled == value) return;
    sfxEnabled = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_sfxKey, value);
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool value) async {
    if (musicEnabled == value) return;
    musicEnabled = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_musicKey, value);
    notifyListeners();
    if (value) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> startMusic() async {
    if (!musicEnabled) return;
    try {
      if (_musicPlaying) {
        await _music.resume();
        return;
      }
      await _music.stop();
      await _music.play(AssetSource(_musicAsset));
      _musicPlaying = true;
    } catch (e) {
      debugPrint('SoundService music: $e');
      _musicPlaying = false;
    }
  }

  Future<void> pauseMusic() async {
    if (!_musicPlaying) return;
    try {
      await _music.pause();
    } catch (e) {
      debugPrint('SoundService music: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (e) {
      debugPrint('SoundService music: $e');
    }
    _musicPlaying = false;
  }

  Future<void> play(GameSound sound) async {
    if (!sfxEnabled) return;
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
    if (!sfxEnabled) return;
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
