import 'package:flutter/widgets.dart';

import '../core/services/preferences_service.dart';

/// Visual effect switches resolved from the user's settings combined with the
/// operating system's "reduce motion" preference.
@immutable
class EffectFlags {
  const EffectFlags({
    required this.motion,
    required this.typewriter,
    required this.shake,
    required this.glitch,
    required this.flashing,
    required this.highContrast,
    required this.largeText,
  });

  factory EffectFlags.resolve(PrankSettings s, {bool systemReduceMotion = false}) {
    final motion = !(s.reduceMotion || systemReduceMotion);
    return EffectFlags(
      motion: motion,
      typewriter: motion && s.terminalAnimations,
      shake: motion && s.screenShake,
      glitch: motion && s.glitchEffects,
      flashing: motion && !s.disableFlashing,
      highContrast: s.highContrast,
      largeText: s.largeTerminalText,
    );
  }

  static EffectFlags of(BuildContext context, PrankSettings settings) {
    return EffectFlags.resolve(
      settings,
      systemReduceMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
    );
  }

  /// Ambient looping animations (glows, rain, particles).
  final bool motion;
  final bool typewriter;
  final bool shake;
  final bool glitch;

  /// Brief colour pulses on warning borders. Never a full-screen strobe.
  final bool flashing;
  final bool highContrast;
  final bool largeText;
}
