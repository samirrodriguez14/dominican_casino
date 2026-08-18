import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameSound { deal, capture, shuffle, win, illegal, softCard, coin, button }

class SoundService extends ChangeNotifier {
  SoundService._();
  static final SoundService instance = SoundService._();

  /// Max overlapping card ticks so a big deal/capture does not become a wash.
  static const cardTickMax = 6;

  static const _sfxKey = 'sfx_enabled';
  static const _musicKey = 'music_enabled';
  static const _sfxVolumeKey = 'sfx_volume';
  static const _musicVolumeKey = 'music_volume';
  static const _hapticKey = 'haptic_enabled';
  static const _musicAsset = 'sounds/bg_music.mp3';
  static const _defaultMusicVolume = 0.35;

  final AudioPlayer _oneshot = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  final List<AudioPlayer> _layers = List.generate(
    cardTickMax,
    (_) => AudioPlayer(),
  );
  int _layer = 0;

  bool sfxEnabled = true;
  bool musicEnabled = true;
  bool hapticEnabled = true;
  double sfxVolume = 1;
  double musicVolume = _defaultMusicVolume;
  bool _musicPlaying = false;
  bool _loaded = false;

  static const _assets = {
    GameSound.deal: 'sounds/deal.wav',
    GameSound.capture: 'sounds/capture.wav',
    GameSound.shuffle: 'sounds/shuffle.wav',
    GameSound.win: 'sounds/win.wav',
    GameSound.illegal: 'sounds/illegal.wav',
    GameSound.softCard: 'sounds/soft_card.wav',
    GameSound.coin: 'sounds/coin.wav',
    GameSound.button: 'sounds/button_soft.wav',
  };

  /// Soft UI thud for taps that have no other SFX.
  static VoidCallback? wrapTap(VoidCallback? onPressed) {
    if (onPressed == null) return null;
    return () {
      instance.playLayered(GameSound.button);
      onPressed();
    };
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final sp = await SharedPreferences.getInstance();
    sfxEnabled = sp.getBool(_sfxKey) ?? true;
    musicEnabled = sp.getBool(_musicKey) ?? true;
    hapticEnabled = sp.getBool(_hapticKey) ?? true;
    sfxVolume = (sp.getDouble(_sfxVolumeKey) ?? 1).clamp(0, 1);
    musicVolume =
        (sp.getDouble(_musicVolumeKey) ?? _defaultMusicVolume).clamp(0, 1);
    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setVolume(musicVolume);
    // Low-latency mode on SFX players — set once, not per tick.
    await _oneshot.setPlayerMode(PlayerMode.lowLatency);
    for (final p in _layers) {
      await p.setPlayerMode(PlayerMode.lowLatency);
    }
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

  Future<void> setSfxVolume(double value) async {
    sfxVolume = value.clamp(0, 1);
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_sfxVolumeKey, sfxVolume);
  }

  Future<void> setMusicVolume(double value) async {
    musicVolume = value.clamp(0, 1);
    try {
      await _music.setVolume(musicVolume);
    } catch (e) {
      debugPrint('SoundService music volume: $e');
    }
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_musicVolumeKey, musicVolume);
  }

  Future<void> setHapticEnabled(bool value) async {
    if (hapticEnabled == value) return;
    hapticEnabled = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_hapticKey, value);
    notifyListeners();
  }

  Future<void> startMusic() async {
    if (!musicEnabled) return;
    try {
      if (_musicPlaying) {
        await _music.resume();
        return;
      }
      await _music.setVolume(musicVolume);
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
      await _oneshot.setVolume(sfxVolume);
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
      // Direct play — seek/resume was adding multi-hundred-ms latency on iOS.
      await player.setVolume((volume * sfxVolume).clamp(0, 1));
      await player.play(AssetSource(path));
    } catch (e) {
      debugPrint('SoundService: $e');
    }
  }
}
