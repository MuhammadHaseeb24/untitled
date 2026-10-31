import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';

import '../models/save_data.dart';

enum Sfx {
  tap('sfx/tap.wav'),
  recruit('sfx/recruit.wav'),
  sword('sfx/sword.wav'),
  shield('sfx/shield.wav'),
  bow('sfx/bow.wav'),
  arrowHit('sfx/arrow_hit.wav'),
  magicCast('sfx/magic_cast.wav'),
  magicHit('sfx/magic_hit.wav'),
  fortressHit('sfx/fortress_hit.wav'),
  victory('sfx/victory.wav'),
  defeat('sfx/defeat.wav'),
  ability('sfx/ability.wav'),
  error('sfx/error.wav');

  const Sfx(this.file);
  final String file;
}

enum MusicTrack {
  menu('music/menu.wav'),
  battle('music/battle.wav');

  const MusicTrack(this.file);
  final String file;
}

/// Sound effects and music. Every call is wrapped so a missing audio plugin or
/// device problem can never crash the game.
class AudioService with WidgetsBindingObserver {
  GameSettings _settings = const GameSettings();
  // Player type comes from flame_audio's own dependency; kept dynamic so the
  // app needs only flame_audio in pubspec.yaml.
  dynamic _music;
  MusicTrack? _track;
  bool _initialized = false;
  bool _musicStarting = false;
  final Map<Sfx, int> _lastPlayed = {};

  Future<void> init(GameSettings settings) async {
    _settings = settings;
    if (_initialized) return;
    _initialized = true;
    try {
      WidgetsBinding.instance.addObserver(this);
      await FlameAudio.audioCache.loadAll([
        for (final s in Sfx.values) s.file,
        for (final m in MusicTrack.values) m.file,
      ]);
    } catch (_) {
      // Audio is optional; continue silently.
    }
  }

  double get _sfxVolume =>
      _settings.sfxOn ? _settings.masterVolume * _settings.sfxVolume : 0;
  double get _musicVolume =>
      _settings.musicOn ? _settings.masterVolume * _settings.musicVolume : 0;

  void apply(GameSettings settings) {
    _settings = settings;
    final dynamic p = _music;
    if (p != null) {
      unawaited(
        Future(() async {
          try {
            await p.setVolume(_musicVolume);
          } catch (_) {}
        }),
      );
    }
  }

  void playSfx(Sfx sfx) {
    final volume = _sfxVolume;
    if (volume <= 0) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayed[sfx] ?? 0;
    if (now - last < 70) return; // avoid stacking identical sounds
    _lastPlayed[sfx] = now;
    unawaited(
      Future(() async {
        try {
          await FlameAudio.play(sfx.file, volume: volume);
        } catch (_) {}
      }),
    );
  }

  Future<void> playMusic(MusicTrack track) async {
    if (_track == track && _music != null) return;
    if (_musicStarting) return;
    _musicStarting = true;
    try {
      await stopMusic();
      _track = track;
      _music = await FlameAudio.loop(track.file, volume: _musicVolume);
    } catch (_) {
      _music = null;
    } finally {
      _musicStarting = false;
    }
  }

  Future<void> stopMusic() async {
    final dynamic p = _music;
    _music = null;
    _track = null;
    if (p == null) return;
    try {
      await p.stop();
      await p.dispose();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final dynamic p = _music;
    if (p == null) return;
    unawaited(
      Future(() async {
        try {
          if (state == AppLifecycleState.resumed) {
            await p.resume();
          } else {
            await p.pause();
          }
        } catch (_) {}
      }),
    );
  }
}