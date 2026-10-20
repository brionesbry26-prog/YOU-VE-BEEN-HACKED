import 'dart:async';

import '../../core/services/audio_service.dart';
import '../../core/services/device_services.dart';
import '../../core/services/haptics_service.dart';
import 'prank_controller.dart';
import 'prank_stage.dart';

/// Maps prank stages to sounds, haptics and the screen wakelock.
///
/// Settings are checked by the services at the moment each effect fires, so
/// changes apply immediately.
class PrankEffectsDirector implements PrankEffects {
  PrankEffectsDirector({
    required this.audio,
    required this.haptics,
    required this.wakelock,
  });

  final AudioService audio;
  final HapticsService haptics;
  final WakelockService wakelock;

  @override
  void onStageEntered(PrankStage stage) {
    switch (stage) {
      case PrankStage.initializing:
        unawaited(wakelock.enable());
        unawaited(audio.play(SoundEffect.beep));
        unawaited(audio.startLoop(SoundEffect.typing));
      case PrankStage.tracing:
        unawaited(audio.stopLoop());
        unawaited(audio.play(SoundEffect.connect));
        unawaited(haptics.pulse(HapticCue.connection));
      case PrankStage.warning:
        unawaited(audio.play(SoundEffect.alarm));
        unawaited(haptics.pulse(HapticCue.breach));
      case PrankStage.extracting:
        unawaited(audio.startLoop(SoundEffect.transfer));
      case PrankStage.simulatedTracking:
        unawaited(audio.stopLoop());
        unawaited(audio.play(SoundEffect.beep));
        unawaited(haptics.pulse(HapticCue.extractionComplete));
      case PrankStage.breachComplete:
        unawaited(audio.play(SoundEffect.alarm));
        unawaited(audio.play(SoundEffect.voice));
      case PrankStage.ransom:
        unawaited(audio.play(SoundEffect.siren));
        unawaited(haptics.pulse(HapticCue.ransom));
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
    // Only background loops resume; one-shot alerts are not replayed.
    if (stage == PrankStage.initializing) {
      unawaited(audio.startLoop(SoundEffect.typing));
    } else if (stage == PrankStage.extracting) {
      unawaited(audio.startLoop(SoundEffect.transfer));
    }
  }

  @override
  void stop() {
    unawaited(audio.stopPrankAudio());
    unawaited(haptics.cancel());
    unawaited(wakelock.disable());
  }
}
