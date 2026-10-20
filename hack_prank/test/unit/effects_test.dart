import 'package:flutter_test/flutter_test.dart';
import 'package:hack_prank/core/services/audio_service.dart';
import 'package:hack_prank/core/services/haptics_service.dart';
import 'package:hack_prank/core/services/preferences_service.dart';
import 'package:hack_prank/features/prank/prank_effects_director.dart';
import 'package:hack_prank/features/prank/prank_stage.dart';
import 'package:hack_prank/shared/effect_flags.dart';

import '../helpers/fakes.dart';

void main() {
  group('SoundPolicy', () {
    const s = PrankSettings(masterVolume: 0.5);

    test('scales by master volume and per-sound gain', () {
      expect(SoundPolicy.volumeFor(SoundEffect.voice, s), 0.5);
      expect(SoundPolicy.volumeFor(SoundEffect.typing, s), closeTo(0.5 * 0.45, 1e-9));
      for (final e in SoundEffect.values) {
        expect(SoundPolicy.volumeFor(e, const PrankSettings(masterVolume: 1)), lessThanOrEqualTo(1));
      }
    });

    test('each category toggle mutes only its sounds', () {
      final noTyping = s.copyWith(typingSounds: false);
      expect(SoundPolicy.volumeFor(SoundEffect.typing, noTyping), 0);
      expect(SoundPolicy.volumeFor(SoundEffect.alarm, noTyping), greaterThan(0));

      final noAlerts = s.copyWith(warningSounds: false);
      for (final e in [SoundEffect.beep, SoundEffect.connect, SoundEffect.alarm, SoundEffect.transfer, SoundEffect.siren]) {
        expect(SoundPolicy.volumeFor(e, noAlerts), 0, reason: e.name);
      }
      expect(SoundPolicy.volumeFor(SoundEffect.voice, noAlerts), greaterThan(0));

      final noVoice = s.copyWith(robotVoice: false);
      expect(SoundPolicy.volumeFor(SoundEffect.voice, noVoice), 0);
    });

    test('master switch and zero volume silence everything, even previews', () {
      for (final muted in [s.copyWith(soundEnabled: false), s.copyWith(masterVolume: 0)]) {
        for (final e in SoundEffect.values) {
          expect(SoundPolicy.volumeFor(e, muted), 0);
          expect(SoundPolicy.volumeFor(e, muted, preview: true), 0);
        }
      }
    });

    test('previews ignore category toggles', () {
      final noVoice = s.copyWith(robotVoice: false);
      expect(SoundPolicy.volumeFor(SoundEffect.voice, noVoice, preview: true), greaterThan(0));
    });
  });

  group('HapticPolicy', () {
    test('follows the vibration toggle', () {
      expect(HapticPolicy.allowed(const PrankSettings()), isTrue);
      expect(HapticPolicy.allowed(const PrankSettings(vibration: false)), isFalse);
    });

    test('patterns are short and never repeat', () {
      for (final cue in HapticCue.values) {
        final total = cue.pattern.fold<int>(0, (a, b) => a + b);
        expect(total, lessThan(400), reason: cue.name);
      }
    });
  });

  group('PrankEffectsDirector', () {
    PrankEffectsDirector director(TestServices s) => PrankEffectsDirector(
      audio: s.audio,
      haptics: s.haptics,
      wakelock: s.wakelock,
    );

    void runAllStages(PrankEffectsDirector d) {
      for (final stage in [...PrankStage.sequence, PrankStage.ransom]) {
        d.onStageEntered(stage);
      }
    }

    test('plays the cinematic cues with default settings', () async {
      final s = TestServices();
      runAllStages(director(s));
      await Future<void>.delayed(Duration.zero);

      expect(s.audio.audible, containsAll(SoundEffect.values.where((e) => e != SoundEffect.celebrate)));
      expect(s.haptics.pulses, [
        HapticCue.connection,
        HapticCue.breach,
        HapticCue.extractionComplete,
        HapticCue.ransom,
      ]);
      expect(s.wakelock.enabled, isTrue);
    });

    test('respects audio and vibration toggles at the moment of playback', () async {
      final s = TestServices(
        const PrankSettings(typingSounds: false, robotVoice: false, vibration: false),
      );
      runAllStages(director(s));
      await Future<void>.delayed(Duration.zero);

      expect(s.audio.audible, isNot(contains(SoundEffect.typing)));
      expect(s.audio.audible, isNot(contains(SoundEffect.voice)));
      expect(s.audio.audible, contains(SoundEffect.alarm));
      expect(s.haptics.pulses, isEmpty);
    });

    test('produces nothing audible or tactile with every effect off', () async {
      final s = TestServices(allEffectsOff);
      runAllStages(director(s));
      await Future<void>.delayed(Duration.zero);
      expect(s.audio.audible, isEmpty);
      expect(s.haptics.pulses, isEmpty);
    });

    test('stop silences audio, cancels vibration and releases the wakelock', () async {
      final s = TestServices();
      final d = director(s)..onStageEntered(PrankStage.extracting);
      await Future<void>.delayed(Duration.zero);
      expect(s.audio.loop, SoundEffect.transfer);

      d.stop();
      await Future<void>.delayed(Duration.zero);
      expect(s.audio.loop, isNull);
      expect(s.audio.prankStops, 1);
      expect(s.haptics.cancels, 1);
      expect(s.wakelock.enabled, isFalse);
    });

    test('resume restarts only the background loop of the current stage', () async {
      final s = TestServices();
      final d = director(s)
        ..onStageEntered(PrankStage.initializing)
        ..onPaused();
      await Future<void>.delayed(Duration.zero);
      expect(s.audio.loop, isNull);

      s.audio.audible.clear();
      d.onResumed(PrankStage.initializing);
      await Future<void>.delayed(Duration.zero);
      expect(s.audio.audible, [SoundEffect.typing]);
      expect(s.wakelock.enabled, isTrue);
    });
  });

  group('EffectFlags', () {
    test('reduce motion (app or system) disables every moving effect', () {
      for (final f in [
        EffectFlags.resolve(const PrankSettings(reduceMotion: true)),
        EffectFlags.resolve(const PrankSettings(), systemReduceMotion: true),
      ]) {
        expect(f.motion, isFalse);
        expect(f.shake, isFalse);
        expect(f.glitch, isFalse);
        expect(f.flashing, isFalse);
        expect(f.confetti, isFalse);
        expect(f.typewriter, isFalse);
      }
    });

    test('disable flashing only affects flashing', () {
      final f = EffectFlags.resolve(const PrankSettings(disableFlashing: true));
      expect(f.flashing, isFalse);
      expect(f.motion, isTrue);
      expect(f.shake, isTrue);
    });
  });
}
