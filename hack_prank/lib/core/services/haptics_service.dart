import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'preferences_service.dart';

/// Key moments that get a short haptic cue.
enum HapticCue {
  connection([0, 40, 70, 40]),
  breach([0, 120, 90, 120]),
  countdown([0, 180]),
  reveal([0, 40]);

  const HapticCue(this.pattern);

  /// Alternating wait/vibrate durations in ms. Every pattern is under 400 ms
  /// in total and nothing ever repeats.
  final List<int> pattern;
}

abstract final class HapticPolicy {
  static bool allowed(PrankSettings settings) => settings.vibration;
}

abstract class HapticsService {
  Future<void> pulse(HapticCue cue);

  /// Stops any vibration that is still running.
  Future<void> cancel();
}

/// [HapticsService] backed by the `vibration` plugin, falling back to the
/// built-in haptic feedback where custom patterns are unsupported.
///
/// The system decides whether vibration is allowed (Do Not Disturb, silent
/// and accessibility settings); this service never overrides it.
class VibrationHapticsService implements HapticsService {
  VibrationHapticsService(this._settings);

  final SettingsController _settings;
  bool? _hasVibrator;
  bool? _customPatterns;

  @override
  Future<void> pulse(HapticCue cue) async {
    if (!HapticPolicy.allowed(_settings.value)) return;
    try {
      _hasVibrator ??= await Vibration.hasVibrator();
      _customPatterns ??= await Vibration.hasCustomVibrationsSupport();
      if (_hasVibrator != true) return;
      if (_customPatterns == true) {
        await Vibration.vibrate(pattern: cue.pattern);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('Haptics unavailable: $e');
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('Haptics cancel ignored: $e');
    }
  }
}
