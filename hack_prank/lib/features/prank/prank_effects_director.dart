import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/device_services.dart';
import '../../core/services/haptics_service.dart';
import '../../core/services/shake_service.dart';
import 'prank_controller.dart';
import 'prank_stage.dart';

/// Maps stages to sound, vibration, the screen wakelock and the shake sensor.
///
/// Settings are checked by the services at the moment each effect fires, so
/// changes apply immediately. [stop] releases everything at once: audio,
/// vibration, wakelock and the accelerometer subscription.
class PrankEffectsDirector implements PrankEffects {
  PrankEffectsDirector({
    required this.audio,
    required this.haptics,
    required this.wakelock,
    required this.shake,
    required this.onShake,
  });

  final AudioService audio;
  final HapticsService haptics;
  final WakelockService wakelock;
  final ShakeSensor shake;

  /// Called when a deliberate shake is detected (ends the simulation).
  final VoidCallback onShake;

  @override
  void onStageEntered(PrankStage stage) {
    switch (stage) {
      case PrankStage.intro:
        unawaited(wakelock.enable());
        unawaited(audio.play(SoundEffect.startup));
      case PrankStage.initializing:
        // Shake-to-reveal is armed from the first terminal screen onwards.
        shake.start(onShake);
        unawaited(audio.play(SoundEffect.beep));
        unawaited(audio.startLoop(SoundEffect.typing));
      case PrankStage.activity:
        unawaited(audio.play(SoundEffect.connect));
        unawaited(audio.startLoop(SoundEffect.transfer));
        unawaited(haptics.pulse(HapticCue.connection));
      case PrankStage.warning:
        unawaited(audio.stopLoop());
        unawaited(audio.play(SoundEffect.alarm));
        unawaited(haptics.pulse(HapticCue.breach));
      case PrankStage.extracting:
        unawaited(audio.startLoop(SoundEffect.transfer));
      case PrankStage.ransom:
        unawaited(audio.startLoop(SoundEffect.countdown));
        unawaited(audio.play(SoundEffect.voice));
        unawaited(haptics.pulse(HapticCue.countdown));
      case PrankStage.idle:
      case PrankStage.revealed:
      case PrankStage.disposed:
        break;
    }
  }

  @override
  void onPaused() => stop();

  @override
  void onResumed(PrankStage stage) {
    unawaited(wakelock.enable());
    if (stage != PrankStage.idle && stage != PrankStage.intro) shake.start(onShake);
    // Only background loops resume; one-shot alerts are not replayed.
    final loop = switch (stage) {
      PrankStage.initializing => SoundEffect.typing,
      PrankStage.activity || PrankStage.extracting => SoundEffect.transfer,
      PrankStage.ransom => SoundEffect.countdown,
      _ => null,
    };
    if (loop != null) unawaited(audio.startLoop(loop));
  }

  @override
  void stop() {
    shake.stop();
    unawaited(audio.stopPrankAudio());
    unawaited(haptics.cancel());
    unawaited(wakelock.disable());
  }
}
