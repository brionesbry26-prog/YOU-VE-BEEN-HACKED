import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'preferences_service.dart';

/// Which settings toggle controls a sound.
enum SoundCategory { typing, alert, voice, reveal }

/// The bundled sound effects (see `tool/generate_sounds.py`).
enum SoundEffect {
  startup('audio/startup.wav', SoundCategory.alert, 0.5),
  typing('audio/typing.wav', SoundCategory.typing, 0.45),
  beep('audio/beep.wav', SoundCategory.alert, 0.6),
  connect('audio/connect.wav', SoundCategory.alert, 0.7),
  alarm('audio/alarm.wav', SoundCategory.alert, 0.7),
  transfer('audio/transfer.wav', SoundCategory.alert, 0.4),
  countdown('audio/countdown.wav', SoundCategory.alert, 0.7),
  voice('audio/voice.wav', SoundCategory.voice, 1.0),
  reveal('audio/reveal.wav', SoundCategory.reveal, 0.6);

  const SoundEffect(this.asset, this.category, this.gain);

  /// Path relative to `assets/`.
  final String asset;
  final SoundCategory category;

  /// Per-sound gain so that no effect is much louder than the others.
  final double gain;

  String get label => switch (this) {
    SoundEffect.startup => 'Startup tone',
    SoundEffect.typing => 'Mechanical typing',
    SoundEffect.beep => 'Terminal beep',
    SoundEffect.connect => 'Connection',
    SoundEffect.alarm => 'Warning alarm',
    SoundEffect.transfer => 'Data transfer',
    SoundEffect.countdown => 'Countdown heartbeat',
    SoundEffect.voice => 'Robotic announcement',
    SoundEffect.reveal => 'Reveal tone',
  };
}

/// Decides how loud a sound may play under the current settings.
abstract final class SoundPolicy {
  /// Returns 0 when the sound must not play. [preview] ignores the per-category
  /// toggles (so users can audition a muted sound) but never the master mute.
  static double volumeFor(
    SoundEffect effect,
    PrankSettings settings, {
    bool preview = false,
  }) {
    if (!settings.soundEnabled || settings.masterVolume <= 0) return 0;
    if (!preview && !_categoryEnabled(effect.category, settings)) return 0;
    return (settings.masterVolume * effect.gain).clamp(0.0, 1.0);
  }

  static bool _categoryEnabled(SoundCategory category, PrankSettings s) {
    return switch (category) {
      SoundCategory.typing => s.typingSounds,
      SoundCategory.alert => s.warningSounds,
      SoundCategory.voice => s.robotVoice,
      SoundCategory.reveal => true,
    };
  }
}

/// Plays bundled sounds. All methods are safe to call at any time and never
/// throw: missing assets or unsupported platforms are logged and ignored.
abstract class AudioService {
  Future<void> init();

  /// Plays a one-shot sound effect.
  Future<void> play(SoundEffect effect, {bool preview = false});

  /// Starts a looping background sound, replacing any previous loop.
  Future<void> startLoop(SoundEffect effect);

  Future<void> stopLoop();

  /// Stops every sound that belongs to the prank sequence (loops, alerts and
  /// the voice). The reveal tone is left alone.
  Future<void> stopPrankAudio();

  /// Stops everything, including the reveal tone.
  Future<void> stopAll();

  Future<void> dispose();
}

/// [AudioService] backed by the `audioplayers` plugin.
///
/// Overlap is capped by design: one loop player, two alert players used
/// round-robin, one voice player and one reveal player.
class AudioPlayersAudioService implements AudioService {
  AudioPlayersAudioService(this._settings);

  final SettingsController _settings;

  AudioPlayer? _loop;
  final List<AudioPlayer> _alerts = [];
  AudioPlayer? _voice;
  AudioPlayer? _revealPlayer;
  int _nextAlert = 0;

  // Bumped by every stop. A sound that is still loading when a stop happens
  // sees the new value and is silenced instead of starting late.
  int _prankGeneration = 0;
  int _loopGeneration = 0;
  SoundEffect? _currentLoop;
  bool _ready = false;
  bool _disposed = false;

  Future<void>? _initializing;

  /// Safe to call repeatedly or concurrently: players are created once.
  @override
  Future<void> init() {
    if (_ready || _disposed) return Future.value();
    return _initializing ??= _createPlayers();
  }

  Future<void> _createPlayers() async {
    try {
      // Ambient, mixable audio: respects the iOS silent switch / Android ringer
      // mode and never steals audio focus from music apps.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          respectSilence: true,
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
      final loop = AudioPlayer(playerId: 'hack_prank_loop');
      await loop.setReleaseMode(ReleaseMode.loop);
      _loop = loop;
      for (var i = 0; i < 2; i++) {
        final p = AudioPlayer(playerId: 'hack_prank_alert_$i');
        await p.setReleaseMode(ReleaseMode.stop);
        _alerts.add(p);
      }
      _voice = AudioPlayer(playerId: 'hack_prank_voice');
      _revealPlayer = AudioPlayer(playerId: 'hack_prank_revealPlayer');
      _ready = true;
    } catch (e) {
      debugPrint('Audio unavailable, continuing silently: $e');
    }
  }

  AudioPlayer? _playerFor(SoundEffect effect) {
    switch (effect.category) {
      case SoundCategory.voice:
        return _voice;
      case SoundCategory.reveal:
        return _revealPlayer;
      case SoundCategory.typing:
      case SoundCategory.alert:
        if (_alerts.isEmpty) return null;
        final player = _alerts[_nextAlert % _alerts.length];
        _nextAlert++;
        return player;
    }
  }

  @override
  Future<void> play(SoundEffect effect, {bool preview = false}) async {
    final volume = SoundPolicy.volumeFor(
      effect,
      _settings.value,
      preview: preview,
    );
    if (volume <= 0) return;
    final generation = _prankGeneration;
    final isPrankSound = effect.category != SoundCategory.reveal;
    if (!_ready) await init();
    final player = _playerFor(effect);
    if (player == null || _disposed) return;
    await _playGuarded(
      player,
      effect,
      volume,
      () => isPrankSound && generation != _prankGeneration,
    );
  }

  @override
  Future<void> startLoop(SoundEffect effect) async {
    final volume = SoundPolicy.volumeFor(effect, _settings.value);
    if (volume <= 0) {
      await stopLoop();
      return;
    }
    final generation = ++_loopGeneration;
    if (!_ready) await init();
    final loop = _loop;
    if (loop == null || _disposed) return;
    _currentLoop = effect;
    await _playGuarded(
      loop,
      effect,
      volume,
      () => generation != _loopGeneration,
    );
  }

  @override
  Future<void> stopLoop() async {
    _loopGeneration++;
    _currentLoop = null;
    final loop = _loop;
    if (loop != null) await _guard(loop.stop);
  }

  @override
  Future<void> stopPrankAudio() async {
    _prankGeneration++;
    await stopLoop();
    for (final p in [..._alerts, ?_voice]) {
      await _guard(p.stop);
    }
  }

  @override
  Future<void> stopAll() async {
    await stopPrankAudio();
    final c = _revealPlayer;
    if (c != null) await _guard(c.stop);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await stopAll();
    _disposed = true;
    for (final p in [?_loop, ..._alerts, ?_voice, ?_revealPlayer]) {
      await _guard(p.dispose);
    }
    _alerts.clear();
    _loop = _voice = _revealPlayer = null;
  }

  /// The loop currently requested, if any (for diagnostics).
  SoundEffect? get currentLoop => _currentLoop;

  Future<void> _playGuarded(
    AudioPlayer player,
    SoundEffect effect,
    double volume,
    bool Function() cancelled,
  ) async {
    await _guard(() async {
      await player.stop();
      if (cancelled() || _disposed) return;
      await player.play(AssetSource(effect.asset), volume: volume);
      if (cancelled() && !_disposed) await player.stop();
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Audio error ignored: $e');
    }
  }
}
