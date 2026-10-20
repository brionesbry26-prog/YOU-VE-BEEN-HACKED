import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/prank_constants.dart';

/// Every user-configurable option. Immutable; use [copyWith] to change it.
///
/// There is deliberately no option that disables the reveal or removes the
/// exit controls: those are always available.
@immutable
class PrankSettings {
  const PrankSettings({
    this.durationSeconds = PrankConstants.defaultDurationSeconds,
    this.terminalAnimations = true,
    this.screenShake = true,
    this.glitchEffects = true,
    this.soundEnabled = true,
    this.masterVolume = 0.7,
    this.typingSounds = true,
    this.warningSounds = true,
    this.robotVoice = true,
    this.vibration = true,
    this.confetti = true,
    this.reduceMotion = false,
    this.disableFlashing = false,
    this.highContrast = false,
    this.largeTerminalText = false,
    this.showRevealShortcut = true,
    this.autoReveal = true,
    this.exitConfirmation = true,
  });

  final int durationSeconds;
  final bool terminalAnimations;
  final bool screenShake;
  final bool glitchEffects;
  final bool soundEnabled;
  final double masterVolume;
  final bool typingSounds;
  final bool warningSounds;
  final bool robotVoice;
  final bool vibration;
  final bool confetti;
  final bool reduceMotion;
  final bool disableFlashing;
  final bool highContrast;
  final bool largeTerminalText;
  final bool showRevealShortcut;
  final bool autoReveal;
  final bool exitConfirmation;

  Duration get duration => Duration(seconds: durationSeconds);

  PrankSettings copyWith({
    int? durationSeconds,
    bool? terminalAnimations,
    bool? screenShake,
    bool? glitchEffects,
    bool? soundEnabled,
    double? masterVolume,
    bool? typingSounds,
    bool? warningSounds,
    bool? robotVoice,
    bool? vibration,
    bool? confetti,
    bool? reduceMotion,
    bool? disableFlashing,
    bool? highContrast,
    bool? largeTerminalText,
    bool? showRevealShortcut,
    bool? autoReveal,
    bool? exitConfirmation,
  }) {
    return PrankSettings(
      durationSeconds: durationSeconds ?? this.durationSeconds,
      terminalAnimations: terminalAnimations ?? this.terminalAnimations,
      screenShake: screenShake ?? this.screenShake,
      glitchEffects: glitchEffects ?? this.glitchEffects,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      masterVolume: masterVolume ?? this.masterVolume,
      typingSounds: typingSounds ?? this.typingSounds,
      warningSounds: warningSounds ?? this.warningSounds,
      robotVoice: robotVoice ?? this.robotVoice,
      vibration: vibration ?? this.vibration,
      confetti: confetti ?? this.confetti,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      disableFlashing: disableFlashing ?? this.disableFlashing,
      highContrast: highContrast ?? this.highContrast,
      largeTerminalText: largeTerminalText ?? this.largeTerminalText,
      showRevealShortcut: showRevealShortcut ?? this.showRevealShortcut,
      autoReveal: autoReveal ?? this.autoReveal,
      exitConfirmation: exitConfirmation ?? this.exitConfirmation,
    );
  }

  Map<String, Object> toMap() => {
    _Keys.duration: durationSeconds,
    _Keys.terminalAnimations: terminalAnimations,
    _Keys.screenShake: screenShake,
    _Keys.glitchEffects: glitchEffects,
    _Keys.soundEnabled: soundEnabled,
    _Keys.masterVolume: masterVolume,
    _Keys.typingSounds: typingSounds,
    _Keys.warningSounds: warningSounds,
    _Keys.robotVoice: robotVoice,
    _Keys.vibration: vibration,
    _Keys.confetti: confetti,
    _Keys.reduceMotion: reduceMotion,
    _Keys.disableFlashing: disableFlashing,
    _Keys.highContrast: highContrast,
    _Keys.largeTerminalText: largeTerminalText,
    _Keys.showRevealShortcut: showRevealShortcut,
    _Keys.autoReveal: autoReveal,
    _Keys.exitConfirmation: exitConfirmation,
  };

  /// Reads settings, falling back to defaults for missing or invalid values.
  factory PrankSettings.fromPreferences(SharedPreferences prefs) {
    const d = PrankSettings();
    bool b(String key, bool fallback) => prefs.getBool(key) ?? fallback;

    final duration = prefs.getInt(_Keys.duration);
    final volume = prefs.getDouble(_Keys.masterVolume);
    return PrankSettings(
      durationSeconds: PrankConstants.allowedDurations.contains(duration)
          ? duration!
          : d.durationSeconds,
      terminalAnimations: b(_Keys.terminalAnimations, d.terminalAnimations),
      screenShake: b(_Keys.screenShake, d.screenShake),
      glitchEffects: b(_Keys.glitchEffects, d.glitchEffects),
      soundEnabled: b(_Keys.soundEnabled, d.soundEnabled),
      masterVolume: (volume ?? d.masterVolume).clamp(0.0, 1.0),
      typingSounds: b(_Keys.typingSounds, d.typingSounds),
      warningSounds: b(_Keys.warningSounds, d.warningSounds),
      robotVoice: b(_Keys.robotVoice, d.robotVoice),
      vibration: b(_Keys.vibration, d.vibration),
      confetti: b(_Keys.confetti, d.confetti),
      reduceMotion: b(_Keys.reduceMotion, d.reduceMotion),
      disableFlashing: b(_Keys.disableFlashing, d.disableFlashing),
      highContrast: b(_Keys.highContrast, d.highContrast),
      largeTerminalText: b(_Keys.largeTerminalText, d.largeTerminalText),
      showRevealShortcut: b(_Keys.showRevealShortcut, d.showRevealShortcut),
      autoReveal: b(_Keys.autoReveal, d.autoReveal),
      exitConfirmation: b(_Keys.exitConfirmation, d.exitConfirmation),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PrankSettings && mapEquals(other.toMap(), toMap());

  @override
  int get hashCode => Object.hashAll(toMap().values);
}

abstract final class _Keys {
  static const duration = 'duration_seconds';
  static const terminalAnimations = 'terminal_animations';
  static const screenShake = 'screen_shake';
  static const glitchEffects = 'glitch_effects';
  static const soundEnabled = 'sound_enabled';
  static const masterVolume = 'master_volume';
  static const typingSounds = 'typing_sounds';
  static const warningSounds = 'warning_sounds';
  static const robotVoice = 'robot_voice';
  static const vibration = 'vibration';
  static const confetti = 'confetti';
  static const reduceMotion = 'reduce_motion';
  static const disableFlashing = 'disable_flashing';
  static const highContrast = 'high_contrast';
  static const largeTerminalText = 'large_terminal_text';
  static const showRevealShortcut = 'show_reveal_shortcut';
  static const autoReveal = 'auto_reveal';
  static const exitConfirmation = 'exit_confirmation';
}

/// Holds the live settings, notifies listeners immediately on change and
/// persists every change to local storage.
class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs, this._settings);

  /// In-memory controller for tests and previews; nothing is persisted.
  SettingsController.inMemory([PrankSettings settings = const PrankSettings()])
    : _prefs = null,
      _settings = settings;

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsController._(prefs, PrankSettings.fromPreferences(prefs));
  }

  final SharedPreferences? _prefs;
  PrankSettings _settings;

  PrankSettings get value => _settings;

  /// Applies [next] immediately and saves it in the background.
  Future<void> update(PrankSettings next) async {
    if (next == _settings) return;
    final previous = _settings.toMap();
    _settings = next;
    notifyListeners();
    await _save({
      for (final e in next.toMap().entries)
        if (previous[e.key] != e.value) e.key: e.value,
    });
  }

  Future<void> reset() => update(const PrankSettings());

  Future<void> _save(Map<String, Object> changed) async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      for (final entry in changed.entries) {
        final value = entry.value;
        if (value is bool) {
          await prefs.setBool(entry.key, value);
        } else if (value is int) {
          await prefs.setInt(entry.key, value);
        } else if (value is double) {
          await prefs.setDouble(entry.key, value);
        }
      }
    } catch (e) {
      debugPrint('Could not save settings: $e');
    }
  }
}
